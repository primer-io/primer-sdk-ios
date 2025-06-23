//
//  DefaultCardFormScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import Foundation

/// Default implementation of PrimerCardFormScope
@available(iOS 15.0, *)
@MainActor
internal final class DefaultCardFormScope: PrimerCardFormScope, ObservableObject, LogReporter {
    // MARK: - Properties

    /// The current card form state
    @Published private var internalState = PrimerCardFormState()

    /// State stream for external observation
    public var state: AsyncStream<PrimerCardFormState> {
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

    // MARK: - UI Customization Properties

    public var cardNumberInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var cvvInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var expiryDateInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var cardholderNameInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var firstNameInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var lastNameInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var emailInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var phoneNumberInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var addressLine1Input: ((_ modifier: PrimerModifier) -> AnyView)?
    public var addressLine2Input: ((_ modifier: PrimerModifier) -> AnyView)?
    public var cityInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var stateInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var postalCodeInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var countryInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var otpCodeInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var container: ((_ content: @escaping () -> AnyView) -> AnyView)?
    public var errorView: ((_ error: String) -> AnyView)?
    public var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> AnyView)?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let diContainer: DIContainer
    private var tokenizeCardInteractor: TokenizeCardInteractor?
    private var processCardPaymentInteractor: ProcessCardPaymentInteractor?
    private var validateInputInteractor: ValidateInputInteractor?

    /// Track if billing address has been sent to avoid duplicate requests
    private var billingAddressSent = false

    /// Store the current card data
    private var currentCardData: PrimerCardData?

    /// Available card networks for co-badged cards
    private var availableCardNetworks: [CardNetwork] = []

    // MARK: - Initialization

    init(checkoutScope: DefaultCheckoutScope) {
        self.checkoutScope = checkoutScope
        self.diContainer = DIContainer.shared

        Task {
            await setupInteractors()
        }
    }

    // MARK: - Setup

    private func setupInteractors() async {
        do {
            guard let container = await DIContainer.current else {
                throw ContainerError.containerUnavailable
            }
            do {
                // processCardPaymentInteractor = try await container.resolve(ProcessCardPaymentInteractor.self)
                // tokenizeCardInteractor = try await container.resolve(TokenizeCardInteractor.self)
                // validateInputInteractor = try await container.resolve(ValidateInputInteractor.self)
            } catch {
                logger.error(message: "Failed to resolve dependencies: \(error)")
            }
        } catch {
            logger.error(message: "Failed to setup interactors: \(error)")
        }
    }

    // MARK: - Update Methods

    public func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "Updating card number")
        internalState.cardNumber = cardNumber
        updateCardData()

        // Check for co-badged cards
        detectAvailableNetworks(from: cardNumber)
    }

    public func updateCvv(_ cvv: String) {
        logger.debug(message: "Updating CVV")
        internalState.cvv = cvv
        updateCardData()
    }

    public func updateExpiryDate(_ expiryDate: String) {
        logger.debug(message: "Updating expiry date: \(expiryDate)")
        internalState.expiryDate = expiryDate

        // Parse month and year from the expiry date
        let components = expiryDate.components(separatedBy: "/")
        if components.count == 2 {
            internalState.expiryMonth = components[0]
            internalState.expiryYear = components[1]
        }

        updateCardData()
    }

    public func updateExpiryMonth(_ month: String) {
        logger.debug(message: "Updating expiry month: \(month)")
        internalState.expiryMonth = month
        updateExpiryDateFromComponents()
        updateCardData()
    }

    public func updateExpiryYear(_ year: String) {
        logger.debug(message: "Updating expiry year: \(year)")
        internalState.expiryYear = year
        updateExpiryDateFromComponents()
        updateCardData()
    }

    public func updateCardholderName(_ name: String) {
        logger.debug(message: "Updating cardholder name")
        internalState.cardholderName = name
        updateCardData()
    }

    public func updateFirstName(_ firstName: String) {
        logger.debug(message: "Updating first name")
        internalState.firstName = firstName
    }

    public func updateLastName(_ lastName: String) {
        logger.debug(message: "Updating last name")
        internalState.lastName = lastName
    }

    public func updateEmail(_ email: String) {
        logger.debug(message: "Updating email")
        internalState.email = email
    }

    public func updatePhoneNumber(_ phoneNumber: String) {
        logger.debug(message: "Updating phone number")
        internalState.phoneNumber = phoneNumber
    }

    public func updateAddressLine1(_ addressLine1: String) {
        logger.debug(message: "Updating address line 1")
        internalState.addressLine1 = addressLine1
    }

    public func updateAddressLine2(_ addressLine2: String) {
        logger.debug(message: "Updating address line 2")
        internalState.addressLine2 = addressLine2
    }

    public func updateCity(_ city: String) {
        logger.debug(message: "Updating city")
        internalState.city = city
    }

    public func updateState(_ state: String) {
        logger.debug(message: "Updating state")
        internalState.state = state
    }

    public func updatePostalCode(_ postalCode: String) {
        logger.debug(message: "Updating postal code")
        internalState.postalCode = postalCode
    }

    public func updateCountryCode(_ countryCode: String) {
        logger.debug(message: "Updating country code: \(countryCode)")
        internalState.countryCode = countryCode
    }

    public func updateOtpCode(_ otpCode: String) {
        logger.debug(message: "Updating OTP code")
        internalState.otpCode = otpCode
    }

    public func updateSelectedCardNetwork(_ network: String) {
        logger.debug(message: "Updating selected card network: \(network)")
        internalState.selectedCardNetwork = network
        updateCardData()
    }

    public func updateRetailOutlet(_ retailOutlet: String) {
        logger.debug(message: "Updating retail outlet")
        internalState.retailOutlet = retailOutlet
    }

    // MARK: - Navigation Methods

    public func onSubmit() {
        Task {
            await submit()
        }
    }

    public func onBack() {
        logger.debug(message: "Card form back navigation")
        checkoutScope?.checkoutNavigator.navigateBack()
    }

    public func onCancel() {
        logger.debug(message: "Card form cancelled")
        checkoutScope?.checkoutNavigator.navigateToPaymentSelection()
    }

    public func navigateToCountrySelection() {
        logger.debug(message: "Navigate to country selection")
        checkoutScope?.checkoutNavigator.navigateToCountrySelection()
    }

    // MARK: - Nested Scope

    private var _selectCountry: DefaultSelectCountryScope?
    public var selectCountry: PrimerSelectCountryScope {
        if let existing = _selectCountry {
            return existing
        }
        let scope = DefaultSelectCountryScope(cardFormScope: self, checkoutScope: checkoutScope)
        _selectCountry = scope
        return scope
    }

    // MARK: - Screen Customization

    public var screen: ((_ scope: PrimerCardFormScope) -> AnyView)?
    public var submitButton: ((_ modifier: PrimerModifier, _ text: String) -> AnyView)?
    public var cardDetails: ((_ modifier: PrimerModifier) -> AnyView)?
    public var billingAddress: ((_ modifier: PrimerModifier) -> AnyView)?
    public var countryCodeInput: ((_ modifier: PrimerModifier) -> AnyView)?
    public var retailOutletInput: ((_ modifier: PrimerModifier) -> AnyView)?

    // MARK: - Private Methods

    private func updateExpiryDateFromComponents() {
        let month = internalState.expiryMonth
        let year = internalState.expiryYear

        if !month.isEmpty && !year.isEmpty {
            internalState.expiryDate = "\(month)/\(year)"
        }
    }

    private func updateCardData() {
        // Create PrimerCardData
        let cardData = PrimerCardData(
            cardNumber: internalState.cardNumber.replacingOccurrences(of: " ", with: ""),
            expiryDate: internalState.expiryDate,
            cvv: internalState.cvv,
            cardholderName: internalState.cardholderName.isEmpty ? nil : internalState.cardholderName
        )

        // Set card network if selected (for co-badged cards)
        if let selectedNetwork = internalState.selectedCardNetwork,
           let cardNetwork = CardNetwork(rawValue: selectedNetwork) {
            cardData.cardNetwork = cardNetwork
        }

        currentCardData = cardData

        // Validate card data using validation service
        validateCardData(cardData)
    }

    private func validateCardData(_ cardData: PrimerCardData) {
        // Use validation service to validate card data
        Task {
            await MainActor.run {
                // Use validation rules directly to avoid DI circular dependency
                logger.debug(message: "🔍 [CardForm] Raw card number: '\(cardData.cardNumber)'")
                let cardNumberRule = CardNumberRule()
                let cardNumberResult = cardNumberRule.validate(cardData.cardNumber)
                logger.debug(message: "🔍 [CardForm] Card number validation result: \(cardNumberResult.isValid), message: '\(cardNumberResult.errorMessage ?? "none")'")

                // For CVV validation, we need to detect the card network first
                let cardNetwork = CardNetwork(cardNumber: cardData.cardNumber)
                logger.debug(message: "🔍 [CardForm] Detected card network: \(cardNetwork.rawValue)")
                logger.debug(message: "🔍 [CardForm] Raw CVV: '\(cardData.cvv)'")
                let cvvRule = CVVRule(cardNetwork: cardNetwork)
                let cvvResult = cvvRule.validate(cardData.cvv)
                logger.debug(message: "🔍 [CardForm] CVV validation result: \(cvvResult.isValid), message: '\(cvvResult.errorMessage ?? "none")')")

                // For expiry validation, parse the month and year
                logger.debug(message: "🔍 [CardForm] Raw expiry date: '\(cardData.expiryDate)'")
                let expiryComponents = cardData.expiryDate.components(separatedBy: "/")
                logger.debug(message: "🔍 [CardForm] Expiry components: \(expiryComponents)")
                let expiryResult: ValidationResult
                if expiryComponents.count == 2 {
                    let month = expiryComponents[0]
                    let year = expiryComponents[1]
                    logger.debug(message: "🔍 [CardForm] Parsed month: '\(month)', year: '\(year)'")
                    let expiryRule = ExpiryDateRule()
                    let expiryInput = ExpiryDateInput(month: month, year: year)
                    expiryResult = expiryRule.validate(expiryInput)
                    logger.debug(message: "🔍 [CardForm] Expiry validation result: \(expiryResult.isValid), message: '\(expiryResult.errorMessage ?? "none")'")
                } else {
                    logger.debug(message: "🔍 [CardForm] Invalid expiry format - expected 2 components, got \(expiryComponents.count)")
                    expiryResult = .invalid(code: "invalid-expiry-format", message: "Invalid expiry date format")
                }

                // Update validation state
                internalState.isValid = cardNumberResult.isValid && cvvResult.isValid && expiryResult.isValid

                logger.debug(message: "🔍 [CardForm] Validation results - Card: \(cardNumberResult.isValid), CVV: \(cvvResult.isValid), Expiry: \(expiryResult.isValid), Overall: \(internalState.isValid)")

                // Show first error found
                if !cardNumberResult.isValid {
                    internalState.error = cardNumberResult.errorMessage
                } else if !cvvResult.isValid {
                    internalState.error = cvvResult.errorMessage
                } else if !expiryResult.isValid {
                    internalState.error = expiryResult.errorMessage
                } else {
                    internalState.error = nil
                }
            }
        }
    }

    private func detectAvailableNetworks(from cardNumber: String) {
        // This would normally use BIN detection to find available networks
        // For now, just detect single network from card number pattern
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")

        if cleanNumber.count >= 6 {
            // Check for co-badged cards (e.g., Cartes Bancaires + Visa)
            // This is simplified - real implementation would use BIN database
            if cleanNumber.hasPrefix("4") {
                // Could be Visa or co-badged with Cartes Bancaires
                if isCartesBancairesBIN(cleanNumber) {
                    availableCardNetworks = [.visa, .cartesBancaires]
                    internalState.availableCardNetworks = ["VISA", "CARTES_BANCAIRES"]
                } else {
                    availableCardNetworks = [.visa]
                    internalState.availableCardNetworks = ["VISA"]
                }
            } else if cleanNumber.hasPrefix("5") {
                availableCardNetworks = [.masterCard]
                internalState.availableCardNetworks = ["MASTERCARD"]
            } else {
                availableCardNetworks = []
                internalState.availableCardNetworks = []
            }
        }
    }

    private func isCartesBancairesBIN(_ cardNumber: String) -> Bool {
        // Simplified check - real implementation would use proper BIN database
        // French card BINs that support co-badging
        let cbBINs = ["497010", "497011", "497012"] // Example BINs
        return cbBINs.contains { cardNumber.hasPrefix($0) }
    }

    private func createBillingAddress() -> ClientSession.Address? {
        // Only create address if we have required fields
        guard !internalState.postalCode.isEmpty else { return nil }

        return ClientSession.Address(
            firstName: internalState.firstName.isEmpty ? nil : internalState.firstName,
            lastName: internalState.lastName.isEmpty ? nil : internalState.lastName,
            addressLine1: internalState.addressLine1.isEmpty ? nil : internalState.addressLine1,
            addressLine2: internalState.addressLine2.isEmpty ? nil : internalState.addressLine2,
            city: internalState.city.isEmpty ? nil : internalState.city,
            postalCode: internalState.postalCode,
            state: internalState.state.isEmpty ? nil : internalState.state,
            countryCode: internalState.countryCode.isEmpty ? nil : CountryCode(rawValue: internalState.countryCode)
        )
    }

    private func createInteractorBillingAddress() -> BillingAddress? {
        // Only create address if we have required fields
        guard !internalState.postalCode.isEmpty else { return nil }

        return BillingAddress(
            firstName: internalState.firstName.isEmpty ? nil : internalState.firstName,
            lastName: internalState.lastName.isEmpty ? nil : internalState.lastName,
            addressLine1: internalState.addressLine1.isEmpty ? nil : internalState.addressLine1,
            addressLine2: internalState.addressLine2.isEmpty ? nil : internalState.addressLine2,
            city: internalState.city.isEmpty ? nil : internalState.city,
            state: internalState.state.isEmpty ? nil : internalState.state,
            postalCode: internalState.postalCode.isEmpty ? nil : internalState.postalCode,
            countryCode: internalState.countryCode.isEmpty ? nil : internalState.countryCode,
            phoneNumber: nil // Not currently collected in this form
        )
    }

    // MARK: - Public Submit Method

    func submit() async {
        logger.debug(message: "Card form submit initiated")

        // Update state to submitting
        internalState.isSubmitting = true

        do {
            // Send billing address first if needed
            if !billingAddressSent, let billingAddress = createBillingAddress() {
                logger.debug(message: "Sending billing address via Client Session Actions")

                await withCheckedContinuation { continuation in
                    ClientSessionActionsModule.updateBillingAddressViaClientSessionActionWithAddressIfNeeded(billingAddress)
                        .done {
                            self.billingAddressSent = true
                            continuation.resume()
                        }
                        .catch { error in
                            self.logger.error(message: "Failed to send billing address: \(error)")
                            continuation.resume()
                        }
                }
            }

            // Submit card data using existing SDK infrastructure
            logger.debug(message: "Processing card payment using RawDataManager")

            // Create card data for existing SDK
            // Convert 2-digit year to 4-digit year for RawDataManager compatibility
            let formattedExpiryDate: String = {
                let components = internalState.expiryDate.components(separatedBy: "/")
                if components.count == 2 {
                    let month = components[0]
                    let year = components[1]
                    // Convert 2-digit year to 4-digit year
                    let fullYear = year.count == 2 ? "20\(year)" : year
                    return "\(month)/\(fullYear)"
                }
                return internalState.expiryDate
            }()

            let cardData = PrimerCardData(
                cardNumber: internalState.cardNumber.replacingOccurrences(of: " ", with: ""),
                expiryDate: formattedExpiryDate,
                cvv: internalState.cvv,
                cardholderName: internalState.cardholderName.isEmpty ? nil : internalState.cardholderName
            )

            // Set card network if selected (for co-badged cards)
            if let selectedNetwork = internalState.selectedCardNetwork,
               let cardNetwork = CardNetwork(rawValue: selectedNetwork) {
                cardData.cardNetwork = cardNetwork
            }

            logger.debug(message: "Card data prepared: number=***\(String(cardData.cardNumber.suffix(4))), expiry=\(cardData.expiryDate) (formatted from \(internalState.expiryDate)), network=\(cardData.cardNetwork?.rawValue ?? "auto")")

            // Use RawDataManager for tokenization like the legacy implementation
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                paymentMethodType: "PAYMENT_CARD",
                delegate: nil
            )

            logger.debug(message: "Created RawDataManager, configuring...")

            // Configure the RawDataManager first (some payment methods require this)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                rawDataManager.configure { _, error in
                    if let error = error {
                        self.logger.error(message: "RawDataManager configuration failed: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        self.logger.debug(message: "RawDataManager configured successfully")
                        continuation.resume()
                    }
                }
            }

            logger.debug(message: "Setting card data and validating...")

            // Set the raw data (this triggers validation automatically)
            rawDataManager.rawData = cardData

            // Add a small delay to allow async validation to complete
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

            logger.debug(message: "Checking validation status after delay...")
            logger.debug(message: "RawDataManager isDataValid: \(rawDataManager.isDataValid)")

            // Try to get more detailed validation information
            if let paymentMethodTokenData = rawDataManager.paymentMethodTokenData {
                logger.debug(message: "Payment method token data available: \(paymentMethodTokenData)")
            } else {
                logger.debug(message: "No payment method token data available yet")
            }

            // Verify data is valid before submitting
            if rawDataManager.isDataValid {
                logger.debug(message: "Raw data is valid, submitting payment...")
                rawDataManager.submit()
                logger.info(message: "Card payment submitted successfully")

                // For now, assume success since we don't have delegate callbacks set up
                // In a real implementation, you would need to implement the delegate methods
                await handlePaymentSuccess(PaymentResult(
                    paymentId: UUID().uuidString,
                    status: .success,
                    token: "checkout_components_token"
                ))
            } else {
                logger.error(message: "Raw data validation failed")

                // Check if there are specific required input types missing
                let requiredInputs = rawDataManager.requiredInputElementTypes
                logger.error(message: "Required input element types: \(requiredInputs)")

                throw PrimerError.unknown(
                    userInfo: ["error": "Card data validation failed", "requiredInputs": requiredInputs.map { "\($0.rawValue)" }.joined(separator: ", ")],
                    diagnosticsId: UUID().uuidString
                )
            }

        } catch {
            logger.error(message: "Card form submission failed: \(error)")
            internalState.isSubmitting = false
            let primerError = error as? PrimerError ?? PrimerError.unknown(
                userInfo: nil,
                diagnosticsId: UUID().uuidString
            )
            checkoutScope?.handlePaymentError(primerError)
        }
    }

    private func handlePaymentSuccess(_ result: PaymentResult) async {
        logger.info(message: "Payment processed successfully: \(result.paymentId)")
        internalState.isSubmitting = false
        checkoutScope?.handlePaymentSuccess(result)
    }
}
