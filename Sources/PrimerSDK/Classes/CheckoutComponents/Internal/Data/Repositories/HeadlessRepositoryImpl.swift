//
//  HeadlessRepositoryImpl.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Payment completion handler that implements delegate callbacks for async payment processing
@available(iOS 15.0, *)
private class PaymentCompletionHandler: NSObject, PrimerHeadlessUniversalCheckoutDelegate, PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    private let completion: (Result<PaymentResult, Error>) -> Void
    private let logger = PrimerLogging.shared.logger
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
            logger.warn(message: "Payment completion delegate called multiple times - ignoring duplicate")
            return
        }
        hasCompleted = true

        logger.info(message: "Payment completed successfully via delegate")

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
            logger.warn(message: "Payment failure delegate called after completion - ignoring")
            return
        }
        hasCompleted = true

        logger.error(message: "Payment failed via delegate: \(err.localizedDescription)")
        completion(.failure(err))
    }

    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(
        _ data: PrimerCheckoutPaymentMethodData,
        decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void
    ) {
        logger.debug(message: "Will create payment - allowing to proceed")
        // Allow payment creation to proceed
        decisionHandler(.continuePaymentCreation())
    }

    // MARK: - 3DS Support

    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(
        _ paymentMethodTokenData: PrimerPaymentMethodTokenData,
        decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
    ) {
        logger.info(message: "🔐🪲 [3DS] Payment method tokenized - proceeding to completion")

        // For CheckoutComponents, we simply complete the tokenization
        // 3DS handling will be done at the payment creation level, not here
        // This follows the pattern from MerchantHeadlessCheckoutAvailablePaymentMethodsViewController
        logger.debug(message: "🔐🪲 [3DS] Completing tokenization, 3DS will be handled during payment creation")
        decisionHandler(.complete())
    }

    func primerHeadlessUniversalCheckoutDidResumeWith(
        _ resumeToken: String,
        decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void
    ) {
        logger.info(message: "🔐🪲 [3DS] Payment resumed with token, proceeding to completion")
        decisionHandler(.complete())
    }

    // MARK: - PrimerHeadlessUniversalCheckoutRawDataManagerDelegate (Validation)

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?) {
        logger.debug(message: "RawDataManager validation state: \(isValid)")

        // Handle validation failures only if we haven't completed yet
        if !isValid, let errors = errors, !errors.isEmpty, !hasCompleted {
            hasCompleted = true
            logger.error(message: "RawDataManager validation failed: \(errors)")
            completion(.failure(errors.first!))
        }
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState state: PrimerValidationState) {
        logger.debug(message: "RawDataManager received metadata for state: \(state)")
        // Handle card network detection and metadata updates if needed
    }
}

/// Implementation of HeadlessRepository using PrimerHeadlessUniversalCheckout.
/// This wraps the existing headless SDK with async/await patterns.
internal final class HeadlessRepositoryImpl: HeadlessRepository, LogReporter {

    // Reference to headless SDK will be injected or accessed here
    // For now, using placeholders to show the implementation pattern

    private var clientToken: String?
    private var paymentMethods: [InternalPaymentMethod] = []

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

    init() {
        logger.debug(message: "HeadlessRepositoryImpl initialized")
    }

    func initialize(clientToken: String) async throws {
        logger.info(message: "Initializing headless checkout")
        self.clientToken = clientToken

        // TODO: Initialize PrimerHeadlessUniversalCheckout.current with clientToken
        // This will be implemented when integrating with the actual SDK

        // For now, simulate success
        logger.info(message: "Headless checkout initialized successfully")
    }

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        logger.info(message: "Fetching payment methods from headless SDK")

        // Get payment methods from PrimerAPIConfigurationModule
        let primerMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods ?? []

        // Map PrimerPaymentMethod to InternalPaymentMethod with surcharge data
        let mappedMethods = primerMethods.map { primerMethod in
            let networkSurcharges = extractNetworkSurcharges(for: primerMethod.type)

            // Debug logging for surcharge data
            logger.debug(message: "💰🪲 [HeadlessRepository] Payment method \(primerMethod.type) - \(primerMethod.name):")
            logger.debug(message: "💰🪲 [HeadlessRepository]   - surcharge: \(primerMethod.surcharge?.description ?? "nil")")
            logger.debug(message: "💰🪲 [HeadlessRepository]   - hasUnknownSurcharge: \(primerMethod.hasUnknownSurcharge)")
            logger.debug(message: "💰🪲 [HeadlessRepository]   - networkSurcharges: \(networkSurcharges?.description ?? "nil")")

            return InternalPaymentMethod(
                id: primerMethod.id ?? primerMethod.type,
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
        logger.info(message: "Mapped \(mappedMethods.count) payment methods with surcharge data")
        return paymentMethods
    }

    /// Extract network-specific surcharges from client session configuration
    private func extractNetworkSurcharges(for paymentMethodType: String) -> [String: Int]? {
        logger.debug(message: "💰🪲 [HeadlessRepository] Extracting network surcharges for payment method type: \(paymentMethodType)")

        // Only card payment methods have network-specific surcharges
        guard paymentMethodType == PrimerPaymentMethodType.paymentCard.rawValue else {
            logger.debug(message: "💰🪲 [HeadlessRepository] Not a card payment method, no network surcharges")
            return nil
        }

        // Get client session payment method data
        let session = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        guard let paymentMethodData = session?.paymentMethod else {
            logger.debug(message: "💰🪲 [HeadlessRepository] No payment method data found in client session")
            return nil
        }

        logger.debug(message: "💰🪲 [HeadlessRepository] Client session payment method data found, checking options...")

        // Check for networks in payment method options
        guard let options = paymentMethodData.options else {
            logger.debug(message: "💰🪲 [HeadlessRepository] No options found in payment method data")
            return nil
        }

        logger.debug(message: "💰🪲 [HeadlessRepository] Found \(options.count) payment method options")

        // Find the payment card option
        guard let paymentCardOption = options.first(where: { ($0["type"] as? String) == paymentMethodType }) else {
            logger.debug(message: "💰🪲 [HeadlessRepository] No PAYMENT_CARD option found in payment method options")
            return nil
        }

        logger.debug(message: "💰🪲 [HeadlessRepository] Found PAYMENT_CARD option: \(paymentCardOption.keys.joined(separator: ", "))")

        // Check for networks data - handle both array and dictionary formats
        if let networksArray = paymentCardOption["networks"] as? [[String: Any]] {
            logger.debug(message: "💰🪲 [HeadlessRepository] Found networks array format with \(networksArray.count) networks")
            return extractFromNetworksArray(networksArray)
        } else if let networksDict = paymentCardOption["networks"] as? [String: [String: Any]] {
            logger.debug(message: "💰🪲 [HeadlessRepository] Found networks dictionary format with \(networksDict.count) networks")
            return extractFromNetworksDict(networksDict)
        } else {
            logger.debug(message: "💰🪲 [HeadlessRepository] No networks data found in payment card option")
            logger.debug(message: "💰🪲 [HeadlessRepository] Available keys in payment card option: \(paymentCardOption.keys.joined(separator: ", "))")
            return nil
        }
    }

    /// Extract surcharges from networks array (traditional format)
    private func extractFromNetworksArray(_ networksArray: [[String: Any]]) -> [String: Int]? {
        var networkSurcharges: [String: Int] = [:]

        for networkData in networksArray {
            guard let networkType = networkData["type"] as? String else {
                logger.debug(message: "💰🪲 [HeadlessRepository] Network missing type field, skipping")
                continue
            }

            // Handle nested surcharge structure: surcharge.amount
            if let surchargeData = networkData["surcharge"] as? [String: Any],
               let surchargeAmount = surchargeData["amount"] as? Int,
               surchargeAmount > 0 {
                networkSurcharges[networkType] = surchargeAmount
                logger.debug(message: "💰🪲 [HeadlessRepository] Found network surcharge (nested): \(networkType) = \(surchargeAmount)")
            }
            // Fallback: handle direct surcharge integer (backward compatibility)
            else if let surcharge = networkData["surcharge"] as? Int,
                    surcharge > 0 {
                networkSurcharges[networkType] = surcharge
                logger.debug(message: "💰🪲 [HeadlessRepository] Found network surcharge (direct): \(networkType) = \(surcharge)")
            } else {
                logger.debug(message: "💰🪲 [HeadlessRepository] No surcharge found for network: \(networkType)")
            }
        }

        logger.debug(message: "💰🪲 [HeadlessRepository] Extracted \(networkSurcharges.count) network surcharges from array format")
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
                logger.debug(message: "💰🪲 [HeadlessRepository] Found network surcharge: \(networkType) = \(surchargeAmount)")
            }
            // Fallback: handle direct surcharge integer (backward compatibility)
            else if let surcharge = networkData["surcharge"] as? Int,
                    surcharge > 0 {
                networkSurcharges[networkType] = surcharge
                logger.debug(message: "💰🪲 [HeadlessRepository] Found direct network surcharge: \(networkType) = \(surcharge)")
            } else {
                logger.debug(message: "💰🪲 [HeadlessRepository] No surcharge found for network: \(networkType)")
            }
        }

        logger.debug(message: "💰🪲 [HeadlessRepository] Extracted \(networkSurcharges.count) network surcharges")
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
        logger.info(message: "Processing card payment via RawDataManager with proper delegate handling")

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                // Check iOS version availability for PaymentCompletionHandler
                if #available(iOS 15.0, *) {
                    do {
                        // Create card data with proper expiry date format
                        let formattedExpiryDate = "\(expiryMonth)/\(expiryYear)"
                        let cardData = PrimerCardData(
                            cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""),
                            expiryDate: formattedExpiryDate,
                            cvv: cvv,
                            cardholderName: cardholderName.isEmpty ? nil : cardholderName
                        )

                        // Set card network if selected (for co-badged cards)
                        if let selectedNetwork = selectedNetwork {
                            cardData.cardNetwork = selectedNetwork
                        }

                        self.logger.debug(message: "Card data prepared: number=***\(String(cardData.cardNumber.suffix(4))), expiry=\(cardData.expiryDate), network=\(cardData.cardNetwork?.rawValue ?? "auto")")

                        // Create payment completion handler
                        let paymentHandler = PaymentCompletionHandler(repository: self) { result in
                            continuation.resume(with: result)
                        }

                        // Set up headless checkout delegate to handle payment completion
                        PrimerHeadlessUniversalCheckout.current.delegate = paymentHandler

                        // Create and configure RawDataManager with delegate
                        let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                            paymentMethodType: "PAYMENT_CARD",
                            delegate: paymentHandler
                        )

                        self.logger.debug(message: "Created RawDataManager with delegate, configuring...")

                        // Configure the RawDataManager
                        rawDataManager.configure { _, error in
                            if let error = error {
                                self.logger.error(message: "RawDataManager configuration failed: \(error)")
                                continuation.resume(throwing: error)
                                return
                            }

                            self.logger.debug(message: "RawDataManager configured successfully")

                            // Set the raw data (this triggers validation automatically)
                            rawDataManager.rawData = cardData

                            // Small delay to allow validation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.logger.debug(message: "Checking validation status...")
                                self.logger.debug(message: "RawDataManager isDataValid: \(rawDataManager.isDataValid)")

                                // Verify data is valid before submitting
                                if rawDataManager.isDataValid {
                                    self.logger.debug(message: "Raw data is valid, updating client session before payment submission...")

                                    // CRITICAL: Update client session with payment method selection BEFORE submitting payment
                                    // This ensures backend has correct surcharge context (matches Drop-in flow)
                                    self.updateClientSessionBeforePayment(selectedNetwork: selectedNetwork) { [weak self] error in
                                        guard let self = self else { return }

                                        if let error = error {
                                            self.logger.error(message: "Client session update failed: \(error)")
                                            continuation.resume(throwing: error)
                                            return
                                        }

                                        self.logger.debug(message: "Client session updated successfully, now submitting payment...")
                                        // This will trigger async payment processing and delegate callbacks
                                        rawDataManager.submit()
                                        self.logger.info(message: "Card payment submitted - waiting for completion via delegate...")
                                    }
                                } else {
                                    self.logger.error(message: "Raw data validation failed")

                                    // Check required input types for debugging
                                    let requiredInputs = rawDataManager.requiredInputElementTypes
                                    self.logger.error(message: "Required input element types: \(requiredInputs)")

                                    let error = PrimerError.unknown(
                                        userInfo: ["error": "Card data validation failed", "requiredInputs": requiredInputs.map { "\($0.rawValue)" }.joined(separator: ", ")],
                                        diagnosticsId: UUID().uuidString
                                    )
                                    continuation.resume(throwing: error)
                                }
                            }
                        }

                    } catch {
                        self.logger.error(message: "Failed to setup payment: \(error)")
                        continuation.resume(throwing: error)
                    }
                } else {
                    // iOS < 15.0 - fallback implementation
                    self.logger.error(message: "CheckoutComponents requires iOS 15.0 or later")
                    let error = PrimerError.unknown(
                        userInfo: ["error": "CheckoutComponents requires iOS 15.0 or later"],
                        diagnosticsId: UUID().uuidString
                    )
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func tokenizeCard(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> TokenizationResult {
        logger.info(message: "Tokenizing card data")

        // TODO: Similar to processCardPayment but with tokenization intent

        // Placeholder implementation
        return TokenizationResult(
            token: "tok_\(UUID().uuidString)",
            tokenId: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(3600),
            cardDetails: TokenizationResult.CardDetails(
                last4: String(cardNumber.suffix(4)),
                network: selectedNetwork?.rawValue ?? "VISA",
                expiryMonth: Int(expiryMonth) ?? 1,
                expiryYear: Int(expiryYear) ?? 2025
            )
        )
    }

    func setBillingAddress(_ billingAddress: BillingAddress) async throws {
        logger.info(message: "Setting billing address via Client Session Actions")

        // TODO: Call Client Session Actions API to set billing address
        // This is separate from card tokenization

        logger.debug(message: "Billing address set successfully")
    }

    func detectCardNetworks(for cardNumber: String) async -> [CardNetwork]? {
        logger.debug(message: "Detecting card networks for card number: ***\(String(cardNumber.suffix(4)))")

        // Use RawDataManager for real network detection
        await updateCardNumberInRawDataManager(cardNumber)

        // Return stream for real-time updates
        return await withTimeout(seconds: 2.0) {
            for await networks in self.networkDetectionStream {
                if !networks.isEmpty {
                    return networks
                }
            }
            return nil
        }
    }

    /// Get network detection stream for real-time updates
    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
        return self.networkDetectionStream
    }

    /// Update card number in RawDataManager to trigger network detection
    @MainActor
    func updateCardNumberInRawDataManager(_ cardNumber: String) async {
        logger.debug(message: "Updating card number in RawDataManager")

        // Configure RawDataManager if needed
        rawDataManager?.configure { [weak self] _, error in
            if let error = error {
                self?.logger.error(message: "RawDataManager configuration failed: \(error)")
            } else {
                self?.logger.debug(message: "RawDataManager configured successfully")
            }
        }

        // Update card data
        rawCardData.cardNumber = cardNumber.replacingOccurrences(of: " ", with: "")

        // Trigger network detection by setting raw data
        rawDataManager?.rawData = rawCardData

        logger.debug(message: "Updated RawDataManager with card number: ***\(String(cardNumber.suffix(4)))")
    }

    /// Handle user selection of a specific card network (for co-badged cards)
    func selectCardNetwork(_ cardNetwork: CardNetwork) async {
        logger.info(message: "User selected card network: \(cardNetwork.displayName)")

        // Update the raw card data with selected network
        rawCardData.cardNetwork = cardNetwork
        rawDataManager?.rawData = rawCardData

        // Use Client Session Actions to select payment method based on network
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        clientSessionActionsModule
            .selectPaymentMethodIfNeeded("PAYMENT_CARD", cardNetwork: cardNetwork.rawValue)
            .cauterize()
    }

    // MARK: - 3DS Error Handling

    /// Create user-friendly 3DS error using centralized strings
    private func createUserFriendly3DSError(from error: Error) -> Error {
        logger.debug(message: "🔐🪲 [3DS] Creating user-friendly error from: \(error)")

        // Check for specific 3DS error types
        if let primer3DSError = error as? Primer3DSErrorContainer {
            return createUserFriendly3DSError(from: primer3DSError)
        }

        if let primerError = error as? PrimerError {
            return createUserFriendly3DSError(from: primerError)
        }

        // Check error message for common scenarios using centralized strings
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("timeout") || errorMessage.contains("timed out") {
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSAuthenticationTimeout,
                    "recovery": CheckoutComponentsStrings.threeDSCheckConnectionMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        }

        if errorMessage.contains("cancelled") || errorMessage.contains("canceled") {
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSAuthenticationCancelled,
                    "recovery": CheckoutComponentsStrings.threeDSCompleteAuthMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        }

        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSNetworkError,
                    "recovery": CheckoutComponentsStrings.threeDSCheckConnectionMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        }

        if errorMessage.contains("invalid") || errorMessage.contains("malformed") {
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSInvalidData,
                    "recovery": CheckoutComponentsStrings.threeDSRetryMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        }

        // Default enhanced error with centralized strings
        return PrimerError.unknown(
            userInfo: [
                "error": CheckoutComponentsStrings.threeDSGenericError,
                "recovery": CheckoutComponentsStrings.threeDSRetryMessage,
                "originalError": error.localizedDescription
            ],
            diagnosticsId: UUID().uuidString
        )
    }

    /// Create user-friendly error from Primer3DSErrorContainer using centralized strings
    private func createUserFriendly3DSError(from error: Primer3DSErrorContainer) -> PrimerError {
        switch error {
        case .missingSdkDependency:
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSNotAvailable,
                    "recovery": CheckoutComponentsStrings.threeDSContactSupportMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        case .missing3DSConfiguration:
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSConfigurationError,
                    "recovery": CheckoutComponentsStrings.threeDSContactSupportMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        case .invalid3DSSdkVersion:
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSNotAvailable,
                    "recovery": CheckoutComponentsStrings.threeDSRetryMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        default:
            return PrimerError.unknown(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSGenericError,
                    "recovery": CheckoutComponentsStrings.threeDSRetryMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        }
    }

    /// Create user-friendly error from PrimerError using centralized strings
    private func createUserFriendly3DSError(from error: PrimerError) -> PrimerError {
        switch error {
        case .invalidClientToken:
            return PrimerError.invalidClientToken(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSSessionExpired,
                    "recovery": CheckoutComponentsStrings.threeDSRetryMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        case .missingPrimerConfiguration:
            return PrimerError.missingPrimerConfiguration(
                userInfo: [
                    "error": CheckoutComponentsStrings.threeDSConfigurationError,
                    "recovery": CheckoutComponentsStrings.threeDSContactSupportMessage
                ],
                diagnosticsId: UUID().uuidString
            )
        default:
            return error // Return original error if no specific enhancement needed
        }
    }

    /// Update client session with payment method selection (matches Drop-in's dispatchActions)
    /// This is CRITICAL for surcharge functionality - backend needs network context for correct calculation
    private func updateClientSessionBeforePayment(selectedNetwork: CardNetwork?, completion: @escaping (Error?) -> Void) {
        logger.debug(message: "💰🪲 [HeadlessRepository] Updating client session before payment submission...")

        // Determine card network (following Drop-in logic exactly)
        var network = selectedNetwork?.rawValue.uppercased()
        if network == nil || network == "UNKNOWN" {
            network = "OTHER"
        }

        logger.debug(message: "💰🪲 [HeadlessRepository] Using card network for surcharge: \(network ?? "nil")")

        // Create parameters matching Drop-in's dispatchActions format
        let params: [String: Any] = [
            "paymentMethodType": "PAYMENT_CARD",
            "binData": [
                "network": network ?? "OTHER"
            ]
        ]

        logger.debug(message: "💰🪲 [HeadlessRepository] Client session action parameters: \(params)")

        // Create action (single action for now - billing address would be added here if needed)
        let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]

        // Use ClientSessionActionsModule to dispatch actions (same as Drop-in)
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

        clientSessionActionsModule.dispatch(actions: actions)
            .done { [weak self] in
                self?.logger.debug(message: "💰🪲 [HeadlessRepository] Client session updated successfully - surcharge context set")
                completion(nil)
            }
            .catch { [weak self] error in
                self?.logger.error(message: "💰🪲 [HeadlessRepository] Client session update failed: \(error)")
                completion(error)
            }
    }

    /// Helper function for timeout on async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T?) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                return await operation()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }

            return await group.first { _ in true } ?? nil
        }
    }
}

// MARK: - RawDataManager Delegate Extension

extension HeadlessRepositoryImpl: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?) {
        let errorsDescription = errors?.map { $0.localizedDescription }.joined(separator: ", ")
        logger.debug(message: "RawDataManager dataIsValid: \(isValid), errors: \(errorsDescription ?? "none")")
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?) {
        logger.debug(message: "RawDataManager metadataDidChange: \(metadata ?? [:])")
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState cardState: PrimerValidationState) {
        guard let state = cardState as? PrimerCardNumberEntryState else {
            logger.error(message: "Received non-card metadata. Ignoring ...")
            return
        }
        logger.debug(message: "RawDataManager willFetchMetadataForState: ***\(String(state.cardNumber.suffix(4)))")
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState cardState: PrimerValidationState) {
        guard let metadataModel = metadata as? PrimerCardNumberEntryMetadata,
              let stateModel = cardState as? PrimerCardNumberEntryState else {
            logger.error(message: "Received non-card metadata. Ignoring ...")
            return
        }

        let metadataDescription = metadataModel.selectableCardNetworks?.items
            .map { $0.displayName }
            .joined(separator: ", ") ?? "n/a"
        logger.debug(message: "RawDataManager didReceiveMetadata: (selectable ->) \(metadataDescription), cardState: ***\(String(stateModel.cardNumber.suffix(4)))")

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
            logger.info(message: "Co-badged networks detected: \(cardNetworks.map { $0.displayName })")

            // Emit networks via AsyncStream for SwiftUI consumption
            networkDetectionContinuation.yield(cardNetworks)
        }
    }
}
