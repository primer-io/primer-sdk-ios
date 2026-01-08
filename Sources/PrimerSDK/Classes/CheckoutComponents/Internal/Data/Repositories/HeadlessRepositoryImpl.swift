//
//  HeadlessRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
#if canImport(Primer3DS)
import Primer3DS
#endif

/// Payment completion handler that implements delegate callbacks for async payment processing
@available(iOS 15.0, *)
private class PaymentCompletionHandler: NSObject, PrimerHeadlessUniversalCheckoutDelegate, PrimerHeadlessUniversalCheckoutRawDataManagerDelegate, LogReporter {

    private let completion: (Result<PaymentResult, Error>) -> Void
    private var hasCompleted = false
    private weak var repository: HeadlessRepositoryImpl?
    private var validationCompletion: ((Bool, [Error]?) -> Void)?
    private let paymentMethodType: String

    init(
        repository: HeadlessRepositoryImpl,
        paymentMethodType: String = "PAYMENT_CARD",
        completion: @escaping (Result<PaymentResult, Error>) -> Void
    ) {
        self.repository = repository
        self.paymentMethodType = paymentMethodType
        self.completion = completion
        super.init()
    }

    func setValidationCompletion(_ validationCompletion: @escaping (Bool, [Error]?) -> Void) {
        self.validationCompletion = validationCompletion
    }

    // MARK: - PrimerHeadlessUniversalCheckoutDelegate (Payment Completion)

    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        guard !hasCompleted else {
            return
        }
        hasCompleted = true

        let result = PaymentResult(
            paymentId: data.payment?.id ?? UUID().uuidString,
            status: .success,
            token: data.payment?.id,
            amount: nil,
            paymentMethodType: paymentMethodType
        )
        completion(.success(result))
    }

    func primerHeadlessUniversalCheckoutDidFail(withError err: Error, checkoutData: PrimerCheckoutData?) {
        guard !hasCompleted else {
            return
        }
        hasCompleted = true

        completion(.failure(err))
    }

    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(
        _ data: PrimerCheckoutPaymentMethodData,
        decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void
    ) {
        decisionHandler(.continuePaymentCreation())
    }

    // MARK: - 3DS Support

    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(
        _ paymentMethodTokenData: PrimerPaymentMethodTokenData,
        decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
    ) {
        repository?.trackThreeDSChallengeIfNeeded(from: paymentMethodTokenData)

        // For CheckoutComponents, we simply complete the tokenization
        // 3DS handling will be done at the payment creation level, not here
        decisionHandler(.complete())
    }

    func primerHeadlessUniversalCheckoutDidResumeWith(
        _ resumeToken: String,
        decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
    ) {
        decisionHandler(.complete())
    }

    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(
        _ additionalInfo: PrimerCheckoutAdditionalInfo?
    ) {
        repository?.trackRedirectToThirdPartyIfNeeded(from: additionalInfo)
    }

    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        repository?.trackRedirectToThirdPartyIfNeeded(from: additionalInfo)
    }

    // MARK: - PrimerHeadlessUniversalCheckoutRawDataManagerDelegate (Validation)

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?) {
        // Notify validation completion handler - continuation is resumed in submitPaymentWithValidation
        if let validationCompletion {
            self.validationCompletion = nil
            validationCompletion(isValid, errors)
        }
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState state: PrimerValidationState) {
    }
}

@available(iOS 15.0, *)
final class HeadlessRepositoryImpl: HeadlessRepository, LogReporter {

    private var paymentMethods: [InternalPaymentMethod] = []

    // MARK: - Settings Integration

    private var settings: PrimerSettings?
    private var configurationService: ConfigurationService?

    // MARK: - Co-Badged Cards Support

    private lazy var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? = {
        let manager = try? PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: "PAYMENT_CARD",
            delegate: self,
            isUsedInDropIn: false
        )
        return manager
    }()

    // MARK: - Vault Support

    private lazy var vaultManager: PrimerHeadlessUniversalCheckout.VaultManager = {
        let manager = PrimerHeadlessUniversalCheckout.VaultManager()
        do {
            try manager.configure()
        } catch {
            logger.error(message: "[Vault] VaultManager.configure() failed: \(error.localizedDescription)")
        }
        return manager
    }()

    /// Retains the completion handler during vault payment processing to prevent deallocation.
    ///
    /// CLEANUP NOTE: This handler is explicitly set to nil in the completion callback (see processVaultedPayment).
    /// If payment is interrupted (e.g., app backgrounded/terminated), cleanup happens automatically because
    /// HeadlessRepository uses transient DI scope - each checkout session creates a fresh instance,
    /// and the old instance (with any retained handler) is deallocated when the session ends.
    private var vaultPaymentCompletionHandler: PaymentCompletionHandler?

    private var rawCardData = PrimerCardData(cardNumber: "", expiryDate: "", cvv: "", cardholderName: "")
    private let (networkDetectionStream, networkDetectionContinuation) = AsyncStream<[CardNetwork]>.makeStream()
    // Last detected networks to avoid duplicate notifications
    private var lastDetectedNetworks: [CardNetwork] = []
    private var lastTrackedRedirectDestination: String?

    // MARK: - Dependency Injection for Testing

    private var clientSessionActionsFactory: () -> ClientSessionActionsProtocol
    private var configurationServiceFactory: (() -> ConfigurationService)?
    private var rawDataManagerFactory: RawDataManagerFactoryProtocol

    init(
        clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() },
        configurationServiceFactory: (() -> ConfigurationService)? = nil,
        rawDataManagerFactory: RawDataManagerFactoryProtocol = DefaultRawDataManagerFactory()
    ) {
        self.clientSessionActionsFactory = clientSessionActionsFactory
        self.configurationServiceFactory = configurationServiceFactory
        self.rawDataManagerFactory = rawDataManagerFactory
    }

    @available(iOS 15.0, *)
    private func injectSettings() async {
        guard settings == nil else { return }

        do {
            guard let container = await DIContainer.current else {
                return
            }

            settings = try await container.resolve(PrimerSettings.self)
        } catch {
        }
    }

    @available(iOS 15.0, *)
    private func ensureSettings() async {
        if settings == nil {
            await injectSettings()
        }
    }

    @available(iOS 15.0, *)
    private func injectConfigurationService() async {
        guard configurationService == nil else { return }

        // Use factory if provided (for testing)
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
        }
    }

    @available(iOS 15.0, *)
    private func ensureConfigurationService() async {
        if configurationService == nil {
            await injectConfigurationService()
        }
    }

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        await ensureConfigurationService()

        let primerMethods = configurationService?.apiConfiguration?.paymentMethods ?? []

        // Map PrimerPaymentMethod to InternalPaymentMethod with surcharge data
        let mappedMethods = primerMethods.map { primerMethod in
            let networkSurcharges = extractNetworkSurcharges(for: primerMethod.type)

            return InternalPaymentMethod(
                id: primerMethod.type,
                type: primerMethod.type,
                name: primerMethod.name,
                icon: primerMethod.logo,
                configId: primerMethod.processorConfigId,
                isEnabled: true, // From payment method availability
                supportedCurrencies: nil, // Could be extracted from primerMethod if available
                requiredInputElements: getRequiredInputElements(for: primerMethod.type),
                metadata: nil, // Could be extracted from primerMethod.displayMetadata
                surcharge: primerMethod.surcharge, // Direct from PrimerPaymentMethod
                hasUnknownSurcharge: primerMethod.hasUnknownSurcharge, // Direct from PrimerPaymentMethod
                networkSurcharges: networkSurcharges // Extract from client session
            )
        }

        paymentMethods = mappedMethods
        // Mapped payment methods with surcharge data
        return paymentMethods
    }

    private func extractNetworkSurcharges(for paymentMethodType: String) -> [String: Int]? {

        // Only card payment methods have network-specific surcharges
        guard paymentMethodType == PrimerPaymentMethodType.paymentCard.rawValue else {
            return nil
        }

        let session = configurationService?.apiConfiguration?.clientSession
        guard let paymentMethodData = session?.paymentMethod else {
            return nil
        }

        guard let options = paymentMethodData.options else {
            return nil
        }

        guard let paymentCardOption = options.first(where: { ($0["type"] as? String) == paymentMethodType }) else {
            return nil
        }

        // Check for networks data - handle both array and dictionary formats
        if let networksArray = paymentCardOption["networks"] as? [[String: Any]] {
            return extractFromNetworksArray(networksArray)
        } else if let networksDict = paymentCardOption["networks"] as? [String: [String: Any]] {
            return extractFromNetworksDict(networksDict)
        } else {
            return nil
        }
    }

    func extractFromNetworksArray(_ networksArray: [[String: Any]]) -> [String: Int]? {
        var networkSurcharges: [String: Int] = [:]

        for networkData in networksArray {
            guard let networkType = networkData["type"] as? String else {
                continue
            }

            // Handle nested surcharge structure: surcharge.amount
            if let surchargeData = networkData["surcharge"] as? [String: Any],
               let surchargeAmount = surchargeData["amount"] as? Int,
               surchargeAmount > 0 {
                networkSurcharges[networkType] = surchargeAmount
            }
            // Fallback: handle direct surcharge integer format
            else if let surcharge = networkData["surcharge"] as? Int,
                    surcharge > 0 {
                networkSurcharges[networkType] = surcharge
            } else {
            }
        }

        return networkSurcharges.isEmpty ? nil : networkSurcharges
    }

    func extractFromNetworksDict(_ networksDict: [String: [String: Any]]) -> [String: Int]? {
        var networkSurcharges: [String: Int] = [:]

        for (networkType, networkData) in networksDict {
            // Handle nested surcharge structure: surcharge.amount
            if let surchargeData = networkData["surcharge"] as? [String: Any],
               let surchargeAmount = surchargeData["amount"] as? Int,
               surchargeAmount > 0 {
                networkSurcharges[networkType] = surchargeAmount
            }
            // Fallback: handle direct surcharge integer format
            else if let surcharge = networkData["surcharge"] as? Int,
                    surcharge > 0 {
                networkSurcharges[networkType] = surcharge
            } else {
            }
        }

        return networkSurcharges.isEmpty ? nil : networkSurcharges
    }

    func getRequiredInputElements(for paymentMethodType: String) -> [PrimerInputElementType] {
        switch paymentMethodType {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return [.cardNumber, .cvv, .expiryDate, .cardholderName]
        default:
            return []
        }
    }

    func processCardPayment(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> PaymentResult {
        // PAYMENT METHOD OPTIONS INTEGRATION: Validate URL scheme if configured
        try await validatePaymentMethodOptions()

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                // Check iOS version availability for PaymentCompletionHandler
                if #available(iOS 15.0, *) {
                    do {
                        let cardData = createCardData(
                            cardNumber: cardNumber,
                            cvv: cvv,
                            expiryMonth: expiryMonth,
                            expiryYear: expiryYear,
                            cardholderName: cardholderName,
                            selectedNetwork: selectedNetwork
                        )

                        let paymentHandler = PaymentCompletionHandler(repository: self) { result in
                            continuation.resume(with: result)
                        }
                        PrimerHeadlessUniversalCheckout.current.delegate = paymentHandler

                        let rawDataManager = try self.rawDataManagerFactory.createRawDataManager(
                            paymentMethodType: "PAYMENT_CARD",
                            delegate: paymentHandler
                        )

                        configureRawDataManagerAndSubmit(
                            rawDataManager: rawDataManager,
                            cardData: cardData,
                            selectedNetwork: selectedNetwork,
                            continuation: continuation,
                            paymentHandler: paymentHandler
                        )
                    } catch {
                        // Failed to setup payment
                        continuation.resume(throwing: error)
                    }
                } else {
                    handleiOS14Fallback(continuation: continuation)
                }
            }
        }
    }

    func createCardData(
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
        continuation: CheckedContinuation<PaymentResult, Error>,
        paymentHandler: PaymentCompletionHandler
    ) {
        rawDataManager.configure { [weak self] _, error in
            guard let self else { return }

            if let error {
                continuation.resume(throwing: error)
                return
            }

            // Set up validation callback to be notified when validation completes
            paymentHandler.setValidationCompletion { [weak self] isValid, errors in
                guard let self else { return }

                DispatchQueue.main.async {
                    // Use the callback's isValid parameter instead of re-checking the property
                    // to avoid race condition where the property hasn't been updated yet
                    self.submitPaymentWithValidation(
                        rawDataManager: rawDataManager,
                        selectedNetwork: selectedNetwork,
                        continuation: continuation,
                        validationResult: isValid,
                        validationErrors: errors
                    )
                }
            }

            // This triggers validation automatically and will call the delegate when done
            rawDataManager.rawData = cardData
        }
    }

    @MainActor
    private func submitPaymentWithValidation(
        rawDataManager: RawDataManagerProtocol,
        selectedNetwork: CardNetwork?,
        continuation: CheckedContinuation<PaymentResult, Error>,
        validationResult: Bool,
        validationErrors: [Error]?
    ) {
        // Use the validationResult from the callback instead of rawDataManager.isDataValid
        // to avoid race condition where the property hasn't been updated yet
        if validationResult {
            updateClientSessionBeforePayment(selectedNetwork: selectedNetwork) { [weak self] error in
                guard let self = self else { return }

                if let error {
                    // Client session update failed
                    continuation.resume(throwing: error)
                    return
                }

                Task {
                    await self.submitPaymentWithHandlingMode(rawDataManager: rawDataManager)
                }
            }
        } else {
            handleValidationFailure(
                rawDataManager: rawDataManager,
                continuation: continuation,
                validationErrors: validationErrors
            )
        }
    }

    @MainActor
    private func submitPaymentWithHandlingMode(rawDataManager: RawDataManagerProtocol) async {
        let paymentHandlingMode: PrimerPaymentHandling
        if #available(iOS 15.0, *) {
            await ensureSettings()
            paymentHandlingMode = settings?.paymentHandling ?? .auto
        } else {
            paymentHandlingMode = .auto
        }

        // CheckoutComponents currently only supports auto mode, but log the setting
        if paymentHandlingMode == .manual {
            // Manual payment handling not yet supported in CheckoutComponents - proceeding with auto mode
        }

        // This will trigger async payment processing and delegate callbacks
        rawDataManager.submit()
    }

    private func handleValidationFailure(
        rawDataManager: RawDataManagerProtocol,
        continuation: CheckedContinuation<PaymentResult, Error>,
        validationErrors: [Error]?
    ) {
        // Use the actual validation errors from the delegate if available
        if let validationErrors = validationErrors, !validationErrors.isEmpty {
            // If there's a single validation error, use it directly
            if validationErrors.count == 1, let error = validationErrors.first {
                continuation.resume(throwing: error)
            } else {
                // If there are multiple errors, wrap them in an underlying errors container
                let error = PrimerError.underlyingErrors(
                    errors: validationErrors,
                    diagnosticsId: .uuid
                )
                continuation.resume(throwing: error)
            }
        } else {
            // Fallback to generic error if no validation errors are available
            let requiredInputs = rawDataManager.requiredInputElementTypes
            let error = PrimerError.invalidValue(
                key: "cardData",
                value: nil,
                reason: "Card data validation failed. Required inputs: \(requiredInputs.map { "\($0.rawValue)" }.joined(separator: ", "))"
            )
            continuation.resume(throwing: error)
        }
    }

    private func handleiOS14Fallback(continuation: CheckedContinuation<PaymentResult, Error>) {
        // CheckoutComponents requires iOS 15.0 or later
        let error = PrimerError.invalidArchitecture(
            description: "CheckoutComponents requires iOS 15.0 or later",
            recoverSuggestion: "Please update your iOS deployment target to iOS 15.0 or later"
        )
        continuation.resume(throwing: error)
    }

    func setBillingAddress(_ billingAddress: BillingAddress) async throws {
    }

    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
        self.networkDetectionStream
    }

    @MainActor
    func updateCardNumberInRawDataManager(_ cardNumber: String) async {
        rawDataManager?.configure { [weak self] _, error in
        }

        let sanitizedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        rawCardData.cardNumber = sanitizedCardNumber

        // If card number is too short for BIN lookup (< 8 digits) and we have cached networks, clear them
        // This ensures the picker disappears when user deletes below the BIN lookup threshold
        if sanitizedCardNumber.count < 8, !lastDetectedNetworks.isEmpty {
            lastDetectedNetworks = []
            networkDetectionContinuation.yield([])
        }

        rawDataManager?.rawData = rawCardData
    }

    func selectCardNetwork(_ cardNetwork: CardNetwork) async {
        rawCardData.cardNetwork = cardNetwork
        rawDataManager?.rawData = rawCardData

        // Use Client Session Actions to select payment method based on network
        let clientSessionActionsModule = clientSessionActionsFactory()
        Task {
            do {
                try await clientSessionActionsModule
                    .selectPaymentMethodIfNeeded("PAYMENT_CARD", cardNetwork: cardNetwork.rawValue)
            } catch {
                // Log error but don't block the flow since this is a fire-and-forget operation
                logger.error(message: "Failed to select payment method: \(error)")
            }
        }
    }

    // MARK: - Vault Methods

    func fetchVaultedPaymentMethods() async throws -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
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
        // (not AppState or any shared state). Since HeadlessRepository uses transient scope in DI,
        // each checkout session creates a fresh instance with an empty VaultManager cache.
        //
        // Without this fetch, VaultManager.startPaymentFlow() would fail validation because its
        // internal cache is empty. This is the correct architectural pattern - it ensures each
        // payment operation has fresh, validated data from the server.
        _ = try await fetchVaultedPaymentMethods()

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let completionHandler = PaymentCompletionHandler(
                    repository: self,
                    paymentMethodType: paymentMethodType
                ) { [weak self] result in
                    self?.vaultPaymentCompletionHandler = nil
                    continuation.resume(with: result)
                }

                // Retain handler to prevent deallocation during async flow
                self.vaultPaymentCompletionHandler = completionHandler
                PrimerHeadlessUniversalCheckout.current.delegate = completionHandler

                self.vaultManager.startPaymentFlow(
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
    private func updateClientSessionBeforePayment(selectedNetwork: CardNetwork?, completion: @escaping (Error?) -> Void) {

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

        Task {
            do {
                try await clientSessionActionsModule.dispatch(actions: actions)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    // MARK: - Payment Method Options Integration

    private func validatePaymentMethodOptions() async throws {
        if #available(iOS 15.0, *) {
            await ensureSettings()
            guard let settings else {
                // PrimerSettings not available for payment method options validation
                return
            }

            // Validate URL scheme if configured (critical for payment redirects and deep links)
            do {
                let validUrl = try settings.paymentMethodOptions.validUrlForUrlScheme()
                // URL scheme validated successfully
            } catch {
                // Invalid URL scheme configuration
                let urlScheme = try? settings.paymentMethodOptions.validSchemeForUrlScheme()
                throw PrimerError.invalidValue(
                    key: "urlScheme",
                    value: urlScheme,
                    reason: "URL scheme validation failed. Please configure a valid URL scheme in PrimerSettings.paymentMethodOptions.urlScheme. Valid format: myapp://payment or https://myapp.com/payment"
                )
            }

            // Log Apple Pay configuration for payment method registry
            if let applePayOptions = settings.paymentMethodOptions.applePayOptions {
                // Apple Pay configured with merchant ID
                // Apple Pay validation will be handled by the payment method itself when selected
            }

            // Log 3DS configuration for security compliance
            if let threeDsOptions = settings.paymentMethodOptions.threeDsOptions {
                // 3DS configuration found
            }

            // Log Stripe configuration if present
            if let stripeOptions = settings.paymentMethodOptions.stripeOptions {
                // Stripe configuration found
            }

            // TODO: KLARNA PAYMENT METHOD - Wire klarnaOptions when Klarna is implemented
            // Klarna payment method is planned but not yet available in CheckoutComponents
            // When implementing Klarna, uncomment and complete this section
            if let klarnaOptions = settings.paymentMethodOptions.klarnaOptions {
                logger.debug(message: "Klarna options configured: \(klarnaOptions.recurringPaymentDescription)")
                // TODO: Initialize Klarna payment method with these options
                // Expected usage: pass klarnaOptions to Klarna payment method configuration
                // Reference: Similar pattern used for stripeOptions (see lines above)
                // Note: iOS klarnaOptions only has recurringPaymentDescription
            }

            // Log 3DS sanity check setting (critical for security)
            let is3DSSanityEnabled = settings.debugOptions.is3DSSanityCheckEnabled
            // 3DS sanity check configuration

            // Payment method options validation completed
        } else {
            // PrimerSettings not available on iOS < 15.0
            return
        }
    }

    // MARK: - Analytics Integration

    func trackThreeDSChallengeIfNeeded(from tokenData: PrimerPaymentMethodTokenData) {
        guard let authentication = tokenData.threeDSecureAuthentication else {
            return
        }

        trackAnalyticsEvent(.paymentThreeds, metadata: .threeDS(ThreeDSEvent(
            paymentMethod: tokenData.paymentMethodType ?? "PAYMENT_CARD",
            provider: threeDSProvider ?? "Unknown",
            response: authentication.responseCode.rawValue
        )))
    }

    func trackRedirectToThirdPartyIfNeeded(from additionalInfo: PrimerCheckoutAdditionalInfo?) {
        guard let additionalInfo,
              let redirectUrl = extractRedirectURL(from: additionalInfo) else { return }

        if redirectUrl == lastTrackedRedirectDestination {
            return
        }
        lastTrackedRedirectDestination = redirectUrl

        trackAnalyticsEvent(.paymentRedirectToThirdParty, metadata: .redirect(RedirectEvent(destinationUrl: redirectUrl)))
    }

    private func extractRedirectURL(from info: PrimerCheckoutAdditionalInfo) -> String? {
        let candidateKeys = ["redirectUrl", "url", "deeplinkUrl", "deepLinkUrl", "qrCodeUrl", "link", "href"]

        for key in candidateKeys {
            if let value = info.value(forKey: key) as? String, isLikelyURL(value) {
                return value
            }
            if let url = info.value(forKey: key) as? URL {
                return url.absoluteString
            }
        }

        for child in Mirror(reflecting: info).children {
            if let nestedInfo = child.value as? PrimerCheckoutAdditionalInfo,
               let nestedUrl = extractRedirectURL(from: nestedInfo) {
                return nestedUrl
            }

            if let url = extractURL(from: child.value) {
                return url
            }
        }

        return nil
    }

    func extractURL(from value: Any) -> String? {
        if let string = value as? String, isLikelyURL(string) {
            return string
        }

        if let url = value as? URL {
            return url.absoluteString
        }

        if let info = value as? PrimerCheckoutAdditionalInfo {
            return extractRedirectURL(from: info)
        }

        return nil
    }

    func isLikelyURL(_ string: String) -> Bool {
        ["http://", "https://"].contains { string.lowercased().hasPrefix($0) }
    }

    private func trackAnalyticsEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) {
        Task {
            await injectAnalyticsInteractor()

            guard let interactor = analyticsInteractor else {
                return
            }

            await interactor.trackEvent(eventType, metadata: metadata)
        }
    }

    private var threeDSProvider: String? {
        #if canImport(Primer3DS)
        return Primer3DS.threeDsSdkProvider
        #else
        return nil
        #endif
    }

    // MARK: - Analytics Interactor

    private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    @available(iOS 15.0, *)
    private func injectAnalyticsInteractor() async {
        guard analyticsInteractor == nil else { return }

        do {
            guard let container = await DIContainer.current else {
                return
            }

            analyticsInteractor = try await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)
        } catch {
            // Failed to resolve analytics interactor
        }
    }
}

// MARK: - RawDataManager Delegate Extension

@available(iOS 15.0, *)
extension HeadlessRepositoryImpl: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?) {
        let errorsDescription = errors?.map(\.localizedDescription).joined(separator: ", ")
        // RawDataManager validation state updated
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?) {
        // RawDataManager metadata changed
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState cardState: PrimerValidationState) {
        guard cardState is PrimerCardNumberEntryState else {
            return
        }
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState cardState: PrimerValidationState) {
        guard let metadataModel = metadata as? PrimerCardNumberEntryMetadata,
              cardState is PrimerCardNumberEntryState else {
            return
        }

        // Extract networks following traditional SDK pattern
        var primerNetworks: [PrimerCardNetwork]
        if metadataModel.source == .remote,
           let selectable = metadataModel.selectableCardNetworks?.items,
           !selectable.isEmpty {
            primerNetworks = selectable
        } else if let preferred = metadataModel.detectedCardNetworks.preferred {
            primerNetworks = [preferred]
        } else if let first = metadataModel.detectedCardNetworks.items.first {
            primerNetworks = [first]
        } else {
            primerNetworks = []
        }

        let filteredNetworks = primerNetworks.filter { $0.displayName != "Unknown" }

        // Convert PrimerCardNetwork to CardNetwork
        let cardNetworks = filteredNetworks.compactMap { CardNetwork(rawValue: $0.network.rawValue) }

        // Only emit if networks changed to avoid duplicate notifications
        if cardNetworks != lastDetectedNetworks {
            lastDetectedNetworks = cardNetworks

            // Emit networks via AsyncStream for SwiftUI consumption
            networkDetectionContinuation.yield(cardNetworks)
        }
    }
}
