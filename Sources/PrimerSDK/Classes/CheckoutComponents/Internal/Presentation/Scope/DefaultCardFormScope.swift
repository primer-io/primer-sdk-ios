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
    @Published private var availableCardNetworks: [CardNetwork] = []

    /// HeadlessRepository for network detection
    private var headlessRepository: HeadlessRepository?

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
                // Setup interactors (proper layered architecture)
                let repository = HeadlessRepositoryImpl()
                headlessRepository = repository
                processCardPaymentInteractor = ProcessCardPaymentInteractorImpl(repository: repository)
                logger.debug(message: "ProcessCardPaymentInteractor initialized successfully")

                // Setup network detection stream
                setupNetworkDetectionStream()

                // tokenizeCardInteractor = try await container.resolve(TokenizeCardInteractor.self)
                // validateInputInteractor = try await container.resolve(ValidateInputInteractor.self)
            } catch {
                logger.error(message: "Failed to resolve dependencies: \(error)")
            }
        } catch {
            logger.error(message: "Failed to setup interactors: \(error)")
        }
    }

    /// Setup network detection stream for co-badged cards
    private func setupNetworkDetectionStream() {
        guard let repository = headlessRepository else { return }

        Task {
            for await networks in repository.getNetworkDetectionStream() {
                await MainActor.run {
                    logger.info(message: "🌐 [CardForm] Received networks from stream: \(networks.map { $0.displayName })")
                    self.availableCardNetworks = networks
                    self.internalState.availableCardNetworks = networks.map { $0.rawValue }

                    // If multiple networks detected, clear any automatic selection
                    if networks.count > 1 {
                        self.internalState.selectedCardNetwork = nil
                        self.updateSurchargeAmount(for: nil)
                        logger.debug(message: "🌐 [CardForm] Multiple networks detected, clearing selection")
                    } else if networks.count == 1 {
                        // Single network - auto-select it
                        let network = networks[0]
                        self.internalState.selectedCardNetwork = network.rawValue
                        self.updateSurchargeAmount(for: network)
                        logger.debug(message: "🌐 [CardForm] Single network detected, auto-selecting: \(network.displayName)")
                    } else {
                        // No networks detected - clear surcharge
                        self.updateSurchargeAmount(for: nil)
                    }
                }
            }
        }
    }

    // MARK: - Update Methods

    public func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "Updating card number")
        internalState.cardNumber = cardNumber
        updateCardData()

        // Trigger network detection via HeadlessRepository
        Task {
            await triggerNetworkDetection(for: cardNumber)
        }
    }

    /// Trigger network detection for the given card number
    private func triggerNetworkDetection(for cardNumber: String) async {
        guard let repository = headlessRepository, cardNumber.count >= 6 else { return }

        logger.debug(message: "🌐 [CardForm] Triggering network detection for: ***\(String(cardNumber.suffix(4)))")
        await repository.updateCardNumberInRawDataManager(cardNumber)
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
        logger.info(message: "🌐 [CardForm] User selected card network: \(network)")
        internalState.selectedCardNetwork = network

        // Update surcharge for selected network
        if let cardNetwork = CardNetwork(rawValue: network) {
            updateSurchargeAmount(for: cardNetwork)
        }

        updateCardData()

        // Notify HeadlessRepository about the selection
        Task {
            await handleNetworkSelection(network)
        }
    }

    /// Handle user selection of a card network for co-badged cards
    private func handleNetworkSelection(_ networkString: String) async {
        guard let repository = headlessRepository,
              let cardNetwork = CardNetwork(rawValue: networkString) else { return }

        logger.info(message: "🌐 [CardForm] Handling network selection: \(cardNetwork.displayName)")
        await repository.selectCardNetwork(cardNetwork)
    }

    /// Handle detected networks from CardDetailsView
    func handleDetectedNetworks(_ networks: [CardNetwork]) {
        logger.debug(message: "🌐 [CardForm] CardDetailsView detected networks: \(networks.map { $0.displayName })")
        // The actual network detection is handled via the stream in setupNetworkDetectionStream
        // This method is kept for compatibility but the real work happens in the stream
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

                // Validate cardholder name (required field)
                let cardholderNameValid = !internalState.cardholderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                logger.debug(message: "🔍 [CardForm] Cardholder name: '\(internalState.cardholderName)', valid: \(cardholderNameValid)")

                // Update validation state (include cardholder name as required)
                internalState.isValid = cardNumberResult.isValid && cvvResult.isValid && expiryResult.isValid && cardholderNameValid

                logger.debug(message: "🔍 [CardForm] Validation results - Card: \(cardNumberResult.isValid), CVV: \(cvvResult.isValid), Expiry: \(expiryResult.isValid), Cardholder: \(cardholderNameValid), Overall: \(internalState.isValid)")

                // Show first error found, but don't show cardholder name error to avoid confusion
                if !cardNumberResult.isValid {
                    internalState.error = cardNumberResult.errorMessage
                } else if !cvvResult.isValid {
                    internalState.error = cvvResult.errorMessage
                } else if !expiryResult.isValid {
                    internalState.error = expiryResult.errorMessage
                } else {
                    // Clear error when all card fields are valid (even if cardholder name is missing)
                    internalState.error = nil
                }
            }
        }
    }

    // Network detection is now handled by HeadlessRepository and RawDataManager
    // Old detectAvailableNetworks and isCartesBancairesBIN methods removed

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

            // Submit card data using interactor (proper layered architecture)
            logger.debug(message: "Processing card payment using ProcessCardPaymentInteractor")

            guard let interactor = processCardPaymentInteractor else {
                throw PrimerError.unknown(
                    userInfo: ["error": "ProcessCardPaymentInteractor not initialized"],
                    diagnosticsId: UUID().uuidString
                )
            }

            // Parse expiry components
            let expiryComponents = internalState.expiryDate.components(separatedBy: "/")
            guard expiryComponents.count == 2 else {
                throw PrimerError.unknown(
                    userInfo: ["error": "Invalid expiry date format"],
                    diagnosticsId: UUID().uuidString
                )
            }

            let expiryMonth = expiryComponents[0]
            let expiryYear = expiryComponents[1]
            // Convert 2-digit year to 4-digit year if needed
            let fullYear = expiryYear.count == 2 ? "20\(expiryYear)" : expiryYear

            // Get selected network if any
            let selectedNetwork: CardNetwork? = {
                if let networkString = internalState.selectedCardNetwork {
                    return CardNetwork(rawValue: networkString)
                }
                return nil
            }()

            logger.debug(message: "Processing payment: card=***\(String(internalState.cardNumber.suffix(4))), month=\(expiryMonth), year=\(fullYear), network=\(selectedNetwork?.rawValue ?? "auto")")

            // Create billing address from current state (for interactor)
            let billingAddress = createInteractorBillingAddress()

            // Create card payment data for interactor
            let cardData = CardPaymentData(
                cardNumber: internalState.cardNumber,
                cvv: internalState.cvv,
                expiryMonth: expiryMonth,
                expiryYear: fullYear,
                cardholderName: internalState.cardholderName,
                selectedNetwork: selectedNetwork,
                billingAddress: billingAddress
            )

            // Process payment through interactor (follows proper architecture)
            let result = try await interactor.execute(cardData: cardData)

            logger.info(message: "Card payment processed successfully via interactor")
            await handlePaymentSuccess(result)

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

        // Notify CheckoutComponentsPrimer about the success with the payment result
        await MainActor.run {
            logger.info(message: "Notifying CheckoutComponentsPrimer about payment success")
            CheckoutComponentsPrimer.shared.handlePaymentSuccess(result)
        }
    }

    // MARK: - Surcharge Management

    /// Updates the surcharge amount based on the selected card network
    private func updateSurchargeAmount(for network: CardNetwork?) {
        guard let network = network else {
            internalState.surchargeAmount = nil
            logger.debug(message: "💰 [CardForm] Clearing surcharge (no network)")
            return
        }

        // Check if surcharge should be displayed (same logic as Drop-in)
        guard let surcharge = network.surcharge,
              PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
              let currency = AppState.current.currency else {
            internalState.surchargeAmount = nil
            logger.debug(message: "💰 [CardForm] No surcharge for network: \(network.displayName)")
            return
        }

        // Format surcharge amount similar to Drop-in implementation
        let formattedSurcharge = "+ \(surcharge.toCurrencyString(currency: currency))"
        internalState.surchargeAmount = formattedSurcharge
        logger.info(message: "💰 [CardForm] Updated surcharge for \(network.displayName): \(formattedSurcharge)")
    }
}
