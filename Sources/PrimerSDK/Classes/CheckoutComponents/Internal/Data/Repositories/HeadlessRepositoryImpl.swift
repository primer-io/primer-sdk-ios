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

    init(completion: @escaping (Result<PaymentResult, Error>) -> Void) {
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
            token: "payment_completed_successfully"
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

        // TODO: Call PrimerHeadlessUniversalCheckout.current.start()
        // and map the returned payment methods

        // For now, return card payment method as example
        let cardMethod = InternalPaymentMethod(
            id: "card",
            type: "PAYMENT_CARD",
            name: "Card",
            icon: nil,
            configId: nil,
            isEnabled: true,
            supportedCurrencies: nil,
            requiredInputElements: [
                .cardNumber,
                .cvv,
                .expiryDate,
                .cardholderName
            ]
        )

        paymentMethods = [cardMethod]
        return paymentMethods
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
                        let paymentHandler = PaymentCompletionHandler { result in
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
                                    self.logger.debug(message: "Raw data is valid, submitting payment...")
                                    // This will trigger async payment processing and delegate callbacks
                                    rawDataManager.submit()
                                    self.logger.info(message: "Card payment submitted - waiting for completion via delegate...")
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
