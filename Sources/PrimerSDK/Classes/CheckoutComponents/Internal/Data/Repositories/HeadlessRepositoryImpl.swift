//
//  HeadlessRepositoryImpl.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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

    init(repository: HeadlessRepositoryImpl, completion: @escaping (Result<PaymentResult, Error>) -> Void) {
        self.repository = repository
        self.completion = completion
        super.init()
    }

    // MARK: - PrimerHeadlessUniversalCheckoutDelegate (Payment Completion)

    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        // Prevent multiple completions
        guard !hasCompleted else {
            // Payment completion delegate called multiple times
            return
        }
        hasCompleted = true

        // Payment completed successfully

        let result = PaymentResult(
            paymentId: data.payment?.id ?? UUID().uuidString,
            status: .success,
            token: data.payment?.id, // Use payment ID as token for CheckoutComponents
            amount: nil, // Amount not available in PrimerCheckoutDataPayment
            paymentMethodType: "PAYMENT_CARD" // Default to card for CheckoutComponents
        )
        completion(.success(result))
    }

    func primerHeadlessUniversalCheckoutDidFail(withError err: Error, checkoutData: PrimerCheckoutData?) {
        // Prevent multiple completions
        guard !hasCompleted else {
            // Payment failure delegate called after completion
            return
        }
        hasCompleted = true

        // Payment failed via delegate
        completion(.failure(err))
    }

    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(
        _ data: PrimerCheckoutPaymentMethodData,
        decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void
    ) {
        // Will create payment
        // Allow payment creation to proceed
        decisionHandler(.continuePaymentCreation())
    }

    // MARK: - 3DS Support

    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(
        _ paymentMethodTokenData: PrimerPaymentMethodTokenData,
        decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
    ) {
        // Payment method tokenized
        repository?.trackThreeDSChallengeIfNeeded(from: paymentMethodTokenData)

        // For CheckoutComponents, we simply complete the tokenization
        // 3DS handling will be done at the payment creation level, not here
        // This follows the pattern from MerchantHeadlessCheckoutAvailablePaymentMethodsViewController
        // Completing tokenization
        decisionHandler(.complete())
    }

    func primerHeadlessUniversalCheckoutDidResumeWith(
        _ resumeToken: String,
        decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
    ) {
        // Payment resumed with token
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
        // RawDataManager validation state: \(isValid)

        // Handle validation failures only if we haven't completed yet
        if !isValid, let errors = errors, !errors.isEmpty, !hasCompleted {
            hasCompleted = true
            // RawDataManager validation failed
            completion(.failure(errors.first!))
        }
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState state: PrimerValidationState) {
        // RawDataManager received metadata
        // Handle card network detection and metadata updates if needed
    }
}

/// Implementation of HeadlessRepository using PrimerHeadlessUniversalCheckout.
/// This wraps the existing headless SDK with async/await patterns.
@available(iOS 15.0, *)
final class HeadlessRepositoryImpl: HeadlessRepository, LogReporter {

    // Reference to headless SDK will be injected or accessed here
    // For now, using placeholders to show the implementation pattern

    private var paymentMethods: [InternalPaymentMethod] = []

    // MARK: - Settings Integration

    /// PrimerSettings for accessing SDK configurations (iOS 15.0+ only)
    private var settings: PrimerSettings?

    // MARK: - Co-Badged Cards Support

    /// RawDataManager for co-badged cards detection (follows traditional SDK pattern)
    private lazy var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? = {
        let manager = try? PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: "PAYMENT_CARD",
            delegate: self,
            isUsedInDropIn: false
        )
        return manager
    }()

    /// Current card data for RawDataManager
    private var rawCardData = PrimerCardData(cardNumber: "", expiryDate: "", cvv: "", cardholderName: "")

    /// Stream for network detection events
    private let (networkDetectionStream, networkDetectionContinuation) = AsyncStream<[CardNetwork]>.makeStream()

    /// Last detected networks to avoid duplicate notifications
    private var lastDetectedNetworks: [CardNetwork] = []
    private var lastTrackedRedirectDestination: String?

    init() {
        // HeadlessRepositoryImpl initialized
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

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        // Fetching payment methods

        // Get payment methods from PrimerAPIConfigurationModule
        let primerMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods ?? []

        // Map PrimerPaymentMethod to InternalPaymentMethod with surcharge data
        let mappedMethods = primerMethods.map { primerMethod in
            let networkSurcharges = extractNetworkSurcharges(for: primerMethod.type)

            // Debug logging for surcharge data
            // Note: primerMethod.id is a processor configuration ID (will be nil for cards)
            // For accessibility, we use type as the stable identifier

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

    /// Extract network-specific surcharges from client session configuration
    private func extractNetworkSurcharges(for paymentMethodType: String) -> [String: Int]? {

        // Only card payment methods have network-specific surcharges
        guard paymentMethodType == PrimerPaymentMethodType.paymentCard.rawValue else {
            return nil
        }

        // Get client session payment method data
        let session = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        guard let paymentMethodData = session?.paymentMethod else {
            return nil
        }

        // Check for networks in payment method options
        guard let options = paymentMethodData.options else {
            return nil
        }

        // Find the payment card option
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

    /// Extract surcharges from networks array (traditional format)
    private func extractFromNetworksArray(_ networksArray: [[String: Any]]) -> [String: Int]? {
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

    /// Extract surcharges from networks dictionary
    private func extractFromNetworksDict(_ networksDict: [String: [String: Any]]) -> [String: Int]? {
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

    /// Get required input elements for a payment method type
    private func getRequiredInputElements(for paymentMethodType: String) -> [PrimerInputElementType] {
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
        // Processing card payment via RawDataManager with proper delegate handling

        // PAYMENT METHOD OPTIONS INTEGRATION: Validate URL scheme if configured
        try await validatePaymentMethodOptions()

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                // Check iOS version availability for PaymentCompletionHandler
                if #available(iOS 15.0, *) {
                    do {
                        // Create card data
                        let cardData = createCardData(
                            cardNumber: cardNumber,
                            cvv: cvv,
                            expiryMonth: expiryMonth,
                            expiryYear: expiryYear,
                            cardholderName: cardholderName,
                            selectedNetwork: selectedNetwork
                        )

                        // Create payment handler and setup delegate
                        let paymentHandler = PaymentCompletionHandler(repository: self) { result in
                            continuation.resume(with: result)
                        }
                        PrimerHeadlessUniversalCheckout.current.delegate = paymentHandler

                        // Create and configure RawDataManager
                        let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                            paymentMethodType: "PAYMENT_CARD",
                            delegate: paymentHandler
                        )

                        // Configure and submit payment
                        configureRawDataManagerAndSubmit(
                            rawDataManager: rawDataManager,
                            cardData: cardData,
                            selectedNetwork: selectedNetwork,
                            continuation: continuation
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

    private func createCardData(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) -> PrimerCardData {
        let formattedExpiryDate = "\(expiryMonth)/\(expiryYear)"
        let cardData = PrimerCardData(
            cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""),
            expiryDate: formattedExpiryDate,
            cvv: cvv,
            cardholderName: cardholderName.isEmpty ? nil : cardholderName
        )

        // Set card network if selected (for co-badged cards)
        if let selectedNetwork {
            cardData.cardNetwork = selectedNetwork
        }

        // Card data prepared for payment processing
        return cardData
    }

    @MainActor
    private func configureRawDataManagerAndSubmit(
        rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
        cardData: PrimerCardData,
        selectedNetwork: CardNetwork?,
        continuation: CheckedContinuation<PaymentResult, Error>
    ) {
        // Created RawDataManager with delegate, configuring...

        rawDataManager.configure { [weak self] _, error in
            guard let self = self else { return }

            if let error {
                // RawDataManager configuration failed
                continuation.resume(throwing: error)
                return
            }

            // RawDataManager configured successfully

            // Set the raw data (this triggers validation automatically)
            rawDataManager.rawData = cardData

            // Small delay to allow validation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.submitPaymentWithValidation(
                    rawDataManager: rawDataManager,
                    selectedNetwork: selectedNetwork,
                    continuation: continuation
                )
            }
        }
    }

    @MainActor
    private func submitPaymentWithValidation(
        rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
        selectedNetwork: CardNetwork?,
        continuation: CheckedContinuation<PaymentResult, Error>
    ) {
        // Checking validation status...

        // Verify data is valid before submitting
        if rawDataManager.isDataValid {
            // Raw data is valid, updating client session before payment submission...

            // Update client session with payment method selection
            updateClientSessionBeforePayment(selectedNetwork: selectedNetwork) { [weak self] error in
                guard let self = self else { return }

                if let error {
                    // Client session update failed
                    continuation.resume(throwing: error)
                    return
                }

                // Client session updated successfully, now submitting payment...

                // Submit payment
                Task {
                    await self.submitPaymentWithHandlingMode(rawDataManager: rawDataManager)
                }
            }
        } else {
            handleValidationFailure(rawDataManager: rawDataManager, continuation: continuation)
        }
    }

    @MainActor
    private func submitPaymentWithHandlingMode(rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) async {
        let paymentHandlingMode: PrimerPaymentHandling
        if #available(iOS 15.0, *) {
            await ensureSettings()
            paymentHandlingMode = settings?.paymentHandling ?? .auto
        } else {
            paymentHandlingMode = .auto
        }

        // Processing payment in specified mode

        // CheckoutComponents currently only supports auto mode, but log the setting
        if paymentHandlingMode == .manual {
            // Manual payment handling not yet supported in CheckoutComponents - proceeding with auto mode
        }

        // This will trigger async payment processing and delegate callbacks
        rawDataManager.submit()
        // Card payment submitted - waiting for completion via delegate...
    }

    private func handleValidationFailure(
        rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
        continuation: CheckedContinuation<PaymentResult, Error>
    ) {
        // Raw data validation failed

        // Check required input types for debugging
        let requiredInputs = rawDataManager.requiredInputElementTypes
        // Required input element types validation failed

        let error = PrimerError.invalidValue(
            key: "cardData",
            value: nil,
            reason: "Card data validation failed. Required inputs: \(requiredInputs.map { "\($0.rawValue)" }.joined(separator: ", "))"
        )
        continuation.resume(throwing: error)
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
        // Setting billing address via Client Session Actions
    }

    /// Get network detection stream for real-time updates
    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
        return self.networkDetectionStream
    }

    /// Update card number in RawDataManager to trigger network detection
    @MainActor
    func updateCardNumberInRawDataManager(_ cardNumber: String) async {
        // Updating card number in RawDataManager

        // Configure RawDataManager if needed
        rawDataManager?.configure { [weak self] _, error in
            if let error {
                // RawDataManager configuration failed
            } else {
                // RawDataManager configured successfully
            }
        }

        // Update card data
        rawCardData.cardNumber = cardNumber.replacingOccurrences(of: " ", with: "")

        // Trigger network detection by setting raw data
        rawDataManager?.rawData = rawCardData

        // Updated RawDataManager with card data
    }

    /// Handle user selection of a specific card network (for co-badged cards)
    func selectCardNetwork(_ cardNetwork: CardNetwork) async {
        // User selected card network

        // Update the raw card data with selected network
        rawCardData.cardNetwork = cardNetwork
        rawDataManager?.rawData = rawCardData

        // Use Client Session Actions to select payment method based on network
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
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

    /// Update client session with payment method selection (matches Drop-in's dispatchActions)
    /// This is CRITICAL for surcharge functionality - backend needs network context for correct calculation
    private func updateClientSessionBeforePayment(selectedNetwork: CardNetwork?, completion: @escaping (Error?) -> Void) {

        // Determine card network (following Drop-in logic exactly)
        var network = selectedNetwork?.rawValue.uppercased()
        if [nil, "UNKNOWN"].contains(network) {
            network = "OTHER"
        }

        // Create parameters matching Drop-in's dispatchActions format
        let params: [String: Any] = [
            "paymentMethodType": "PAYMENT_CARD",
            "binData": [
                "network": network ?? "OTHER"
            ]
        ]

        // Create action (single action for now - billing address would be added here if needed)
        let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]

        // Use ClientSessionActionsModule to dispatch actions (same as Drop-in)
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

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

    /// Validates payment method options from PrimerSettings before processing payments
    /// This ensures CheckoutComponents respects URL scheme, Apple Pay, and 3DS configurations
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

    private func extractURL(from value: Any) -> String? {
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

    private func isLikelyURL(_ string: String) -> Bool {
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
        let errorsDescription = errors?.map { $0.localizedDescription }.joined(separator: ", ")
        // RawDataManager validation state updated
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?) {
        // RawDataManager metadata changed
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState cardState: PrimerValidationState) {
        guard cardState is PrimerCardNumberEntryState else {
            // Received non-card metadata
            return
        }
        // RawDataManager fetching metadata for card state
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState cardState: PrimerValidationState) {
        guard let metadataModel = metadata as? PrimerCardNumberEntryMetadata,
              cardState is PrimerCardNumberEntryState else {
            // Received non-card metadata
            return
        }

        let metadataDescription = metadataModel.selectableCardNetworks?.items
            .map { $0.displayName }
            .joined(separator: ", ") ?? "n/a"
        // RawDataManager received metadata

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
            // Co-badged networks detected

            // Emit networks via AsyncStream for SwiftUI consumption
            networkDetectionContinuation.yield(cardNetworks)
        }
    }
}
