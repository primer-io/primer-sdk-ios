//
//  DefaultPaymentMethodSelectionScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScope: PaymentMethodSelectionScopeInternal, ObservableObject,
  LogReporter {
  // MARK: - Properties

  @Published private var internalState = PrimerPaymentMethodSelectionState()

  var state: AsyncStream<PrimerPaymentMethodSelectionState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await value in $internalState.values {
          continuation.yield(value)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  var currentState: PrimerPaymentMethodSelectionState { internalState }

  var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  // MARK: - Private Properties

  private weak var checkoutScope: DefaultCheckoutScope?
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private var accessibilityAnnouncementService: AccessibilityAnnouncementService?
  private var setupTask: Task<Void, Never>?

  // MARK: - Initialization

  init(
    checkoutScope: DefaultCheckoutScope,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
  ) {
    self.checkoutScope = checkoutScope
    self.analyticsInteractor = analyticsInteractor

    setupTask = Task { [self] in
      await loadPaymentMethods()
      await refreshVaultedPaymentMethods()
      await resolveAccessibilityService()
    }
  }

  func refreshVaultedPaymentMethods() async {
    do {
      guard let container = await DIContainer.current else { return }
      let repository = try await container.resolve(HeadlessRepository.self)
      let vaultedMethods = try await repository.fetchVaultedPaymentMethods()

      checkoutScope?.setVaultedPaymentMethods(vaultedMethods)
      syncSelectedVaultedPaymentMethod()
    } catch {
      logger.error(
        message: "[Vault] Failed to load vaulted payment methods: \(error.localizedDescription)",
        error: error
      )
    }
  }

  // MARK: - Accessibility Setup

  private func resolveAccessibilityService() async {
    do {
      guard let container = await DIContainer.current else { return }
      accessibilityAnnouncementService = try await container.resolve(
        AccessibilityAnnouncementService.self)
    } catch {
      // Failed to resolve AccessibilityAnnouncementService, accessibility announcements will be disabled
      logger.debug(
        message:
          "[A11Y] Failed to resolve AccessibilityAnnouncementService: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - Setup

  private func loadPaymentMethods() async {
    guard let checkoutScope else {
      internalState.error = CheckoutComponentsStrings.checkoutScopeNotAvailable
      return
    }

    for await checkoutState in checkoutScope.state {
      if case .ready = checkoutState {
        let paymentMethods = checkoutScope.availablePaymentMethods

        let mapper: PaymentMethodMapper
        do {
          guard let container = await DIContainer.current else {
            throw PrimerError.invalidArchitecture(
              description: "DIContainer.current is nil",
              recoverSuggestion: nil
            )
          }
          mapper = try await container.resolve(PaymentMethodMapper.self)
        } catch {
          // Fallback to manual creation without surcharge data
          let composablePaymentMethods = paymentMethods.map { method in
            CheckoutPaymentMethod(
              id: method.id,
              type: method.type,
              name: method.name,
              icon: method.icon
            )
          }
          internalState.paymentMethods = composablePaymentMethods
          internalState.filteredPaymentMethods = composablePaymentMethods
          break
        }

        let composablePaymentMethods = mapper.mapToPublic(paymentMethods)

        internalState.paymentMethods = composablePaymentMethods
        internalState.filteredPaymentMethods = composablePaymentMethods

        break
      } else if case let .failure(error) = checkoutState {
        internalState.error = error.localizedDescription
        break
      } else if case .dismissed = checkoutState {
        break
      }
    }
  }

  // MARK: - Public Methods

  func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) {
    internalState.selectedPaymentMethod = paymentMethod

    let selectionMessage = CheckoutComponentsStrings.a11yPaymentMethodSelected(paymentMethod.name)
    accessibilityAnnouncementService?.announceStateChange(selectionMessage)
    logger.debug(message: "[A11Y] Payment method selected announcement: \(selectionMessage)")

    Task {
      await trackPaymentMethodSelection(paymentMethod.type)
    }

    let internalMethod = InternalPaymentMethod(
      id: paymentMethod.id,
      type: paymentMethod.type,
      name: paymentMethod.name,
      icon: paymentMethod.icon
    )

    checkoutScope?.handlePaymentMethodSelection(internalMethod)
  }

  private func trackPaymentMethodSelection(_ paymentMethodType: String) async {
    await analyticsInteractor?.trackEvent(
      .paymentMethodSelection, metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType)))
  }

  func cancel() {
    setupTask?.cancel()
    checkoutScope?.onDismiss()
  }

  // MARK: - Vault Payment

  func payWithVaultedPaymentMethod() async {
    guard let vaultedMethod = internalState.selectedVaultedPaymentMethod else {
      logger.warn(message: "[Vault] No vaulted payment method selected")
      return
    }

    // The CVV screen submits through `payWithVaultedPaymentMethodAndCvv`.
    if shouldRequireCvvInput(for: vaultedMethod) {
      logger.info(message: "[Vault] CVV required for vaulted card payment, showing CVV screen")
      checkoutScope?.updateNavigationState(.cvvRecapture)
      return
    }

    await executeVaultPayment(vaultedMethod: vaultedMethod, additionalData: nil)
  }

  func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async {
    guard let vaultedMethod = internalState.selectedVaultedPaymentMethod else {
      logger.warn(message: "[Vault] No vaulted payment method selected")
      return
    }

    logger.info(
      message: "[Vault] Starting payment with vaulted method: \(vaultedMethod.id) with CVV")

    let additionalData = PrimerVaultedCardAdditionalData(cvv: cvv)
    await executeVaultPayment(vaultedMethod: vaultedMethod, additionalData: additionalData)
  }

  /// Validates CVV input and returns validation state with optional error message.
  /// - Parameter cvv: The CVV string to validate
  /// - Returns: Tuple with `isValid` flag and optional `errorMessage`
  func validateCvv(_ cvv: String) -> (isValid: Bool, errorMessage: String?) {
    let expectedLength =
      internalState.selectedVaultedPaymentMethod?.cardNetwork.validation?.code.length ?? 3

    // Empty input: not valid yet, but no error (user hasn't started typing)
    guard !cvv.isEmpty else {
      return (false, nil)
    }

    // Non-numeric characters: invalid with error
    guard cvv.allSatisfy(\.isNumber) else {
      return (false, CheckoutComponentsStrings.cvvInvalidError)
    }

    // Too many digits: invalid with error
    if cvv.count > expectedLength {
      return (false, CheckoutComponentsStrings.cvvInvalidError)
    }

    // Exact length: valid, no error
    if cvv.count == expectedLength {
      return (true, nil)
    }

    // Partial input (fewer digits): not yet valid, no error (user still typing)
    return (false, nil)
  }

  // MARK: - Vault Payment Helpers

  private func executeVaultPayment(
    vaultedMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod,
    additionalData: PrimerVaultedPaymentMethodAdditionalData?
  ) async {
    // A merchant's own pay button need not disable itself, so guard against a double tap here.
    guard !internalState.isVaultPaymentLoading else {
      return logger.warn(message: "[Vault] A payment is already in flight, ignoring the repeat submit")
    }

    logger.info(message: "[Vault] Starting payment with vaulted method: \(vaultedMethod.id)")

    internalState.isVaultPaymentLoading = true
    // Without this the payment runs behind the merchant's own list, with nothing to show it started.
    checkoutScope?.startProcessing(payingWith: nil)

    await analyticsInteractor?.trackEvent(
      .paymentSubmitted,
      metadata: .payment(PaymentEvent(paymentMethod: vaultedMethod.paymentMethodType))
    )

    do {
      guard let container = await DIContainer.current else {
        throw PrimerError.unknown(message: "DIContainer.current is nil")
      }
      let interactor = try await container.resolve(SubmitVaultedPaymentInteractor.self)

      let result = try await interactor.execute(
        vaultedPaymentMethodId: vaultedMethod.id,
        paymentMethodType: vaultedMethod.paymentMethodType,
        additionalData: additionalData
      )

      internalState.isVaultPaymentLoading = false
      checkoutScope?.handlePaymentSuccess(result)

    } catch {
      internalState.isVaultPaymentLoading = false
      logger.error(message: "[Vault] Payment failed: \(error.localizedDescription)")

      let primerError =
        error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      checkoutScope?.handlePaymentError(primerError)
    }
  }

  private func shouldRequireCvvInput(
    for vaultedMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  ) -> Bool {
    // Only cards can require CVV
    guard
      vaultedMethod.paymentInstrumentType == .paymentCard
        || vaultedMethod.paymentInstrumentType == .cardOffSession
    else {
      return false
    }

    do {
      guard let container = DIContainer.currentSync else { return false }
      let configService = try container.resolveSync(ConfigurationService.self)
      return configService.captureVaultedCardCvv
    } catch {
      logger.error(
        message: "[Vault] Failed to resolve ConfigurationService: \(error.localizedDescription)")
      return false
    }
  }

  func showAllVaultedPaymentMethods() {
    logger.info(message: "[Vault] Navigating to all vaulted payment methods screen")
    checkoutScope?.updateNavigationState(.vaultedPaymentMethods)
  }

  func showOtherWaysToPay() {
    logger.info(message: "[PaymentSelection] Expanding to show all payment methods")
    internalState.isPaymentMethodsExpanded = true
  }

  func collapsePaymentMethods() {
    logger.info(message: "[PaymentSelection] Collapsing payment methods section")
    internalState.isPaymentMethodsExpanded = false
  }

  func searchPaymentMethods(_ query: String) {
    internalState.searchQuery = query

    if query.isEmpty {
      internalState.filteredPaymentMethods = internalState.paymentMethods
    } else {
      let lowercasedQuery = query.lowercased()
      internalState.filteredPaymentMethods = internalState.paymentMethods.filter { method in
        method.name.lowercased().contains(lowercasedQuery)
          || method.type.lowercased().contains(lowercasedQuery)
      }
    }
  }

  // MARK: - Vault Selection Update

  /// Syncs internal state with checkout scope's selected vaulted payment method.
  /// Called by DefaultCheckoutScope when selection changes.
  /// Source of truth is always `checkoutScope.selectedVaultedPaymentMethod`.
  func syncSelectedVaultedPaymentMethod() {
    internalState.selectedVaultedPaymentMethod = checkoutScope?.selectedVaultedPaymentMethod
  }

  var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
    checkoutScope?.vaultedPaymentMethods ?? []
  }

  var vaultedPaymentMethodsStream: AsyncStream<[PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]> {
    AsyncStream { continuation in
      guard let vaultManager = checkoutScope?.vaultManager else {
        continuation.finish()
        return
      }
      let task = Task { @MainActor in
        for await methods in vaultManager.$methods.values {
          continuation.yield(methods)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  func selectVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    checkoutScope?.setSelectedVaultedPaymentMethod(method)
  }

  // MARK: - Vault Delete

  /// Deletes a vaulted payment method and refreshes the list
  /// - Parameter method: The vaulted payment method to delete
  /// - Throws: Error if deletion fails
  func deleteVaultedPaymentMethod(
    _ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  ) async throws {
    logger.info(message: "[Vault] Deleting vaulted payment method: \(method.id)")

    guard let container = await DIContainer.current else {
      throw PrimerError.unknown(message: "DIContainer.current is nil")
    }

    let repository = try await container.resolve(HeadlessRepository.self)
    try await repository.deleteVaultedPaymentMethod(method.id)

    logger.info(message: "[Vault] Successfully deleted payment method: \(method.id)")

    await refreshVaultedPaymentMethods()
  }

}
