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
        logger.debug(message: "Detecting card networks for number")

        // TODO: Use card number validation to detect co-badged cards
        // Check if multiple networks are available (e.g., Cartes Bancaires + Visa)

        // Example for co-badged card
        if cardNumber.starts(with: "4") && cardNumber.count >= 6 {
            // Check for French card that might be co-badged
            let firstSix = String(cardNumber.prefix(6))
            if isFrenchhCardBIN(firstSix) {
                return [
                    .cartesBancaires,
                    .visa
                ]
            }
        }

        return nil
    }

    private func isFrenchhCardBIN(_ bin: String) -> Bool {
        // Simplified check - in real implementation would check against BIN database
        let frenchBINs = ["497010", "497011", "497012"] // Example BINs
        return frenchBINs.contains(bin)
    }
}

// MARK: - RawDataManager Delegate Extension

// This extension will handle the delegate callbacks when implementing with real SDK
// extension HeadlessRepositoryImpl: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
//     // Implement delegate methods and convert to async/await using continuations
// }
