//
//  HeadlessRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

#if canImport(Primer3DS)
  import Primer3DS
#endif

@available(iOS 15.0, *)
@MainActor
final class HeadlessRepositoryImpl: @preconcurrency HeadlessRepository, LogReporter {

  private var paymentMethods: [InternalPaymentMethod] = []

  private var configurationService: ConfigurationService?

  // MARK: - Co-Badged Cards Support

  private lazy var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? = {
    let manager = try? PrimerHeadlessUniversalCheckout.RawDataManager(
      paymentMethodType: "PAYMENT_CARD",
      delegate: self,
      isUsedInDropIn: false
    )
    manager?.cardNetworkSyncObserver = self
    return manager
  }()

  private var didConfigureRawDataManager = false

  // MARK: - Vault Support

  private lazy var vaultManager: any VaultManagerProtocol = {
    if let factory = vaultManagerFactory { return factory() }
    let manager = PrimerHeadlessUniversalCheckout.VaultManager()
    do {
      try manager.configure()
    } catch {
      logger.error(
        message: "[Vault] VaultManager.configure() failed: \(error.localizedDescription)")
    }
    return manager
  }()

  /// Retains the completion handler during vault payment processing to prevent deallocation.
  ///
  /// CLEANUP NOTE: HeadlessRepository is registered as a DI singleton, so this instance is not
  /// freed when a checkout session ends. The handler is explicitly set to nil in the completion
  /// callback (see processVaultedPayment); that explicit reset is the cleanup mechanism.
  private var vaultPaymentCompletionHandler: PaymentCompletionHandler?
  private var cardPaymentCompletionHandler: PaymentCompletionHandler?

  private var rawCardData = PrimerCardData(
    cardNumber: "", expiryDate: "", cvv: "", cardholderName: "")
  // swiftformat:disable:next wrap
  // Accessed by the RawDataManager delegate extension (separate file), so not `private`.
  let (networkDetectionStream, networkDetectionContinuation) = AsyncStream<[CardNetwork]>.makeStream()
  // swiftformat:disable:next wrap
  let (binDataStream, binDataContinuation) = AsyncStream<PrimerBinData>.makeStream()
  let (cardNetworkSyncStream, cardNetworkSyncContinuation) = AsyncStream<Bool>.makeStream()
  // Last detected networks to avoid duplicate notifications
  var lastDetectedNetworks: [CardNetwork] = []
  let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

  private let clientSessionActionsFactory: () -> ClientSessionActionsProtocol
  private let cardNetworkSync: ClientSessionCardNetworkSync
  private var configurationServiceFactory: (() -> ConfigurationService)?
  private let rawDataManagerFactory: RawDataManagerFactoryProtocol
  private let vaultManagerFactory: (() -> any VaultManagerProtocol)?

  init(
    clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = {
      ClientSessionActionsModule()
    },
    cardNetworkSync: ClientSessionCardNetworkSync = .shared,
    configurationServiceFactory: (() -> ConfigurationService)? = nil,
    rawDataManagerFactory: RawDataManagerFactoryProtocol = DefaultRawDataManagerFactory(),
    vaultManagerFactory: (() -> any VaultManagerProtocol)? = nil,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
  ) {
    self.clientSessionActionsFactory = clientSessionActionsFactory
    self.cardNetworkSync = cardNetworkSync
    self.configurationServiceFactory = configurationServiceFactory
    self.rawDataManagerFactory = rawDataManagerFactory
    self.vaultManagerFactory = vaultManagerFactory
    self.analyticsInteractor = analyticsInteractor
  }

  private func injectConfigurationService() async {
    guard configurationService == nil else { return }

    if let factory = configurationServiceFactory {
      configurationService = factory()
      return
    }

    do {
      guard let container = await DIContainer.current else {
        return
      }

      configurationService = try await container.resolve(ConfigurationService.self)
    } catch {
      logger.error(message: "Failed to resolve dependency: \(error)")
    }
  }

  func getPaymentMethods() async throws -> [InternalPaymentMethod] {
    await injectConfigurationService()

    let primerMethods = configurationService?.apiConfiguration?.paymentMethods ?? []

    let mappedMethods = primerMethods.map { primerMethod in
      let networkSurcharges = configurationService.map {
        NetworkSurchargeExtractor.extractNetworkSurcharges(for: primerMethod.type, from: $0)
      } ?? nil

      let displayButton = primerMethod.displayMetadata?.button
      return InternalPaymentMethod(
        id: primerMethod.type,
        type: primerMethod.type,
        name: primerMethod.name,
        icon: primerMethod.logo,
        configId: primerMethod.processorConfigId,
        isEnabled: true,
        supportedCurrencies: nil,
        requiredInputElements: NetworkSurchargeExtractor.getRequiredInputElements(for: primerMethod.type),
        surcharge: primerMethod.surcharge,
        hasUnknownSurcharge: primerMethod.hasUnknownSurcharge,
        networkSurcharges: networkSurcharges,
        backgroundColor: displayButton?.backgroundColor?.uiColor,
        buttonText: displayButton?.text,
        textColor: displayButton?.textColor?.uiColor,
        borderColor: displayButton?.borderColor?.uiColor,
        borderWidth: displayButton?.borderWidth?.resolvedValue,
        cornerRadius: displayButton?.cornerRadius.map(CGFloat.init),
        logoVariants: primerMethod.baseLogoImage,
        backgroundColorVariants: displayButton?.backgroundColor,
        textColorVariants: displayButton?.textColor
      )
    }

    paymentMethods = mappedMethods
    return paymentMethods
  }

  func processCardPayment(
    cardNumber: String,
    cvv: String,
    expiryMonth: String,
    expiryYear: String,
    cardholderName: String,
    selectedNetwork: CardNetwork?,
    surchargeNetwork: CardNetwork? = nil
  ) async throws -> PaymentResult {
    await cardNetworkSync.startPayment()
    do {
      return try await withCheckedThrowingContinuation { continuation in
        let oneShot = OneShotContinuation(continuation)
        Task { @MainActor [self] in
          do {
            let cardData = createCardData(
              cardNumber: cardNumber,
              cvv: cvv,
              expiryMonth: expiryMonth,
              expiryYear: expiryYear,
              cardholderName: cardholderName,
              selectedNetwork: selectedNetwork
            )

            let paymentHandler = PaymentCompletionHandler { [weak self] result in
              self?.cardPaymentCompletionHandler = nil
              oneShot.resume(with: result)
            }
            cardPaymentCompletionHandler = paymentHandler
            PrimerHeadlessUniversalCheckout.current.delegate = paymentHandler

            let rawDataManager = try rawDataManagerFactory.createRawDataManager(
              paymentMethodType: "PAYMENT_CARD",
              delegate: paymentHandler
            )
            rawDataManager.requiredActionObserver = analyticsInteractor

            configureRawDataManagerAndSubmit(
              rawDataManager: rawDataManager,
              cardData: cardData,
              selectedNetwork: surchargeNetwork ?? selectedNetwork,
              oneShot: oneShot,
              paymentHandler: paymentHandler
            )
          } catch {
            oneShot.resume(throwing: error)
          }
        }
      }
    } catch {
      await cardNetworkSync.endPayment()
      throw error
    }
  }

  @MainActor
  func releaseCardNetwork() async {
    if didConfigureRawDataManager {
      rawDataManager?.isCardNetworkReleased = true
    }
    await cardNetworkSync.release()
  }

  func resetCardNetworkSync() async {
    await cardNetworkSync.reset()
  }

  private func createCardData(
    cardNumber: String,
    cvv: String,
    expiryMonth: String,
    expiryYear: String,
    cardholderName: String,
    selectedNetwork: CardNetwork?
  ) -> PrimerCardData {
    let formattedExpiryDate = "\(expiryMonth)/\(expiryYear)"
    let sanitizedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
    let cardData = PrimerCardData(
      cardNumber: sanitizedCardNumber,
      expiryDate: formattedExpiryDate,
      cvv: cvv,
      cardholderName: cardholderName.isEmpty ? nil : cardholderName
    )

    if let selectedNetwork {
      cardData.cardNetwork = selectedNetwork
    }

    return cardData
  }

  @MainActor
  private func configureRawDataManagerAndSubmit(
    rawDataManager: RawDataManagerProtocol,
    cardData: PrimerCardData,
    selectedNetwork: CardNetwork?,
    oneShot: OneShotContinuation<PaymentResult>,
    paymentHandler: PaymentCompletionHandler
  ) {
    rawDataManager.configure { [weak self] _, error in
      guard let self else { return }

      if let error {
        oneShot.resume(throwing: error)
        return
      }

      paymentHandler.setValidationCompletion { [weak self] isValid, errors in
        self?.submitPaymentWithValidation(
          rawDataManager: rawDataManager,
          selectedNetwork: selectedNetwork,
          oneShot: oneShot,
          validationResult: isValid,
          validationErrors: errors
        )
      }

      rawDataManager.rawData = cardData
    }
  }

  @MainActor
  private func submitPaymentWithValidation(
    rawDataManager: RawDataManagerProtocol,
    selectedNetwork: CardNetwork?,
    oneShot: OneShotContinuation<PaymentResult>,
    validationResult: Bool,
    validationErrors: [Error]?
  ) {
    if validationResult {
      updateClientSessionBeforePayment(selectedNetwork: selectedNetwork) { [weak self] error in
        guard let self else { return }

        if let error {
          oneShot.resume(throwing: error)
          return
        }

        // Triggers async payment processing and the delegate callbacks.
        Task { @MainActor in rawDataManager.submit() }
      }
    } else {
      handleValidationFailure(
        rawDataManager: rawDataManager,
        oneShot: oneShot,
        validationErrors: validationErrors
      )
    }
  }

  private func handleValidationFailure(
    rawDataManager: RawDataManagerProtocol,
    oneShot: OneShotContinuation<PaymentResult>,
    validationErrors: [Error]?
  ) {
    // Use the actual validation errors from the delegate if available
    if let validationErrors, !validationErrors.isEmpty {
      // If there's a single validation error, use it directly
      if validationErrors.count == 1, let error = validationErrors.first {
        oneShot.resume(throwing: error)
      } else {
        // If there are multiple errors, wrap them in an underlying errors container
        let error = PrimerError.underlyingErrors(
          errors: validationErrors,
          diagnosticsId: .uuid
        )
        oneShot.resume(throwing: error)
      }
    } else {
      // Fallback to generic error if no validation errors are available
      let requiredInputs = rawDataManager.requiredInputElementTypes
      let error = PrimerError.invalidValue(
        key: "cardData",
        value: nil,
        reason:
          "Card data validation failed. Required inputs: \(requiredInputs.map { "\($0.rawValue)" }.joined(separator: ", "))"
      )
      oneShot.resume(throwing: error)
    }
  }

  nonisolated func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
    networkDetectionStream
  }

  nonisolated func getBinDataStream() -> AsyncStream<PrimerBinData> {
    binDataStream
  }

  nonisolated func getCardNetworkSyncStream() -> AsyncStream<Bool> {
    cardNetworkSyncStream
  }

  @MainActor
  func updateCardNumberInRawDataManager(_ cardNumber: String) async {
    if !didConfigureRawDataManager {
      didConfigureRawDataManager = true
      rawDataManager?.configure { _, _ in }
    }

    let sanitizedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
    rawCardData.cardNumber = sanitizedCardNumber

    // If card number is too short for BIN lookup (< 8 digits) and we have cached networks, clear them
    // This ensures the picker disappears when user deletes below the BIN lookup threshold
    if sanitizedCardNumber.count < 8, !lastDetectedNetworks.isEmpty {
      emitDetectedNetworks([])
    }

    rawDataManager?.rawData = rawCardData
  }

  func selectCardNetwork(_ cardNetwork: CardNetwork) async {
    rawCardData.cardNetwork = cardNetwork
    rawDataManager?.rawData = rawCardData
  }

  func emitDetectedNetworks(_ networks: [CardNetwork]) {
    if let pick = rawCardData.cardNetwork, !networks.contains(pick) {
      rawCardData.cardNetwork = nil
    }
    lastDetectedNetworks = networks
    networkDetectionContinuation.yield(networks)
  }

  // MARK: - Vault Methods

  func fetchVaultedPaymentMethods() async throws -> [PrimerHeadlessUniversalCheckout
    .VaultedPaymentMethod] {
    try await withCheckedThrowingContinuation { continuation in
      vaultManager.fetchVaultedPaymentMethods { [weak self] vaultedPaymentMethods, error in
        if let error {
          self?.logger.error(message: "[Vault] Fetch failed: \(error.localizedDescription)")
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: vaultedPaymentMethods ?? [])
      }
    }
  }

  func processVaultedPayment(
    vaultedPaymentMethodId: String,
    paymentMethodType: String,
    additionalData: PrimerVaultedPaymentMethodAdditionalData?
  ) async throws -> PaymentResult {

    // ARCHITECTURE NOTE: This fetch is required even if vaulted methods were recently fetched.
    //
    // VaultManager internally validates payment IDs against its own `vaultedPaymentMethods` cache
    // (not AppState or any shared state). HeadlessRepository is a DI singleton, so its VaultManager
    // instance and cache persist across operations and may be empty or stale at this point.
    //
    // Without this fetch, VaultManager.startPaymentFlow() would fail validation because its
    // internal cache is empty. This is the correct architectural pattern - it ensures each
    // payment operation has fresh, validated data from the server.
    _ = try await fetchVaultedPaymentMethods()

    return try await withCheckedThrowingContinuation { continuation in
      let oneShot = OneShotContinuation(continuation)
      Task { @MainActor [self] in
        let completionHandler = PaymentCompletionHandler(
          paymentMethodType: paymentMethodType,
          staleCheckoutData: vaultManager.paymentCheckoutData
        ) { [weak self] result in
          self?.vaultPaymentCompletionHandler = nil
          oneShot.resume(with: result)
        }

        vaultPaymentCompletionHandler = completionHandler
        PrimerHeadlessUniversalCheckout.current.delegate = completionHandler
        vaultManager.requiredActionObserver = analyticsInteractor

        vaultManager.startPaymentFlow(
          vaultedPaymentMethodId: vaultedPaymentMethodId,
          vaultedPaymentMethodAdditionalData: additionalData
        )
      }
    }
  }

  func deleteVaultedPaymentMethod(_ id: String) async throws {
    // ARCHITECTURE NOTE: Same as processVaultedPayment - fetch required to populate VaultManager's
    // internal cache before deletion. VaultManager validates the ID exists before allowing delete.
    // See processVaultedPayment comment for full architectural explanation.
    _ = try await fetchVaultedPaymentMethods()

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      vaultManager.deleteVaultedPaymentMethod(id: id) { [weak self] error in
        if let error {
          self?.logger.error(message: "[Vault] Delete failed: \(error.localizedDescription)")
          continuation.resume(throwing: error)
          return
        }
        self?.logger.info(message: "[Vault] Successfully deleted payment method: \(id)")
        continuation.resume()
      }
    }
  }

  /// Update client session with payment method selection (matches Drop-in's dispatchActions)
  /// This is CRITICAL for surcharge functionality - backend needs network context for correct calculation
  private func updateClientSessionBeforePayment(
    selectedNetwork: CardNetwork?, completion: @escaping (Error?) -> Void
  ) {

    // Determine card network (following Drop-in logic exactly)
    var network = selectedNetwork?.rawValue.uppercased()
    if [nil, "UNKNOWN"].contains(network) {
      network = "OTHER"
    }

    let params: [String: Any] = [
      "paymentMethodType": "PAYMENT_CARD",
      "binData": [
        "network": network ?? "OTHER"
      ]
    ]

    let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]

    // Use ClientSessionActionsModule to dispatch actions (same as Drop-in)
    let clientSessionActionsModule = clientSessionActionsFactory()

    Task { [cardNetworkSync] in
      if let selectedNetwork, await !cardNetworkSync.needsSync(selectedNetwork) {
        completion(nil)
        return
      }
      do {
        try await clientSessionActionsModule.dispatch(actions: actions)
        if let selectedNetwork, selectedNetwork != .unknown {
          await cardNetworkSync.markSynced(selectedNetwork)
        }
        completion(nil)
      } catch {
        completion(error)
      }
    }
  }
}
