//
//  DefaultCardFormScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

// swiftlint:disable file_length
// swiftlint:disable identifier_name

import SwiftUI
import Foundation

/// Validation state tracking for individual fields
private struct FieldValidationStates: Equatable {
    // Card fields - start as false and become true when validation passes
    var cardNumber: Bool = false
    var cvv: Bool = false
    var expiry: Bool = false
    var cardholderName: Bool = false

    // Billing address fields
    var postalCode: Bool = false
    var countryCode: Bool = false
    var city: Bool = false
    var state: Bool = false
    var addressLine1: Bool = false
    var addressLine2: Bool = false
    var firstName: Bool = false
    var lastName: Bool = false
    var email: Bool = false
    var phoneNumber: Bool = false
}

/// Default implementation of PrimerCardFormScope
@available(iOS 15.0, *)
@MainActor
public final class DefaultCardFormScope: PrimerCardFormScope, ObservableObject, LogReporter {
    // MARK: - Properties

    /// The current card form state
    @Published private var internalState = PrimerCardFormState()

    /// Debug getter for internal state
    internal var debugInternalState: PrimerCardFormState {
        internalState
    }

    /// The presentation context determining navigation behavior
    public private(set) var presentationContext: PresentationContext = .fromPaymentSelection

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
    
    // MARK: - Screen Customization
    
    public var screen: ((_ scope: any PrimerCardFormScope) -> AnyView)?
    public var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> AnyView)?
    public var errorView: ((_ error: String) -> AnyView)?
    
    // MARK: - Field-Level Customization Properties
    public var cardNumberField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var expiryDateField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var cvvField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var cardholderNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var postalCodeField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var countryField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var cityField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var stateField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var addressLine1Field: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var addressLine2Field: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var phoneNumberField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var firstNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var lastNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var emailField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var retailOutletField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var otpCodeField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)?
    public var submitButton: ((_ text: String) -> AnyView)?
    
    // MARK: - Section-Level Customization Properties
    public var cardInputSection: (() -> AnyView)?
    public var billingAddressSection: (() -> AnyView)?
    public var submitButtonSection: (() -> AnyView)?
    
    // MARK: - Default Styling Properties
    public var defaultFieldStyling: [String: PrimerFieldStyling]?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let diContainer: DIContainer
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

    /// Field validation states for proper scope integration
    private var fieldValidationStates = FieldValidationStates()

    /// Computed property to get the selected country from the country code
    private var selectedCountryFromCode: CountryCode.PhoneNumberCountryCode? {
        logger.debug(message: "🔍 [CountryField] Computing selectedCountryFromCode - current code: '\(internalState.countryCode)'")
        guard !internalState.countryCode.isEmpty else {
            logger.debug(message: "🔍 [CountryField] Country code is empty, returning nil")
            return nil
        }
        let country = CountryCode.phoneNumberCountryCodes.first { $0.code.uppercased() == internalState.countryCode.uppercased() }
        logger.debug(message: "🔍 [CountryField] Found country: \(country?.name ?? "nil") (\(country?.code ?? "nil"))")
        return country
    }

    // MARK: - Initialization

    init(checkoutScope: DefaultCheckoutScope, presentationContext: PresentationContext = .fromPaymentSelection) {
        self.checkoutScope = checkoutScope
        self.diContainer = DIContainer.shared
        self.presentationContext = presentationContext

        // Log the presentation context initialization
        logger.info(message: "🧭 [CardFormScope] Initialized with presentation context: \(presentationContext)")
        logger.info(message: "🧭 [CardFormScope]   - Should show back button: \(presentationContext.shouldShowBackButton)")
        logger.info(message: "🧭 [CardFormScope]   - Cancel behavior: \(presentationContext.cancelBehavior)")
        logger.info(message: "🧭 [CardFormScope] Instance ID: \(ObjectIdentifier(self))")
        Task {
            await setupInteractors()
        }
    }

    // MARK: - Setup
    private func setupInteractors() async {
        do {
            guard await DIContainer.current != nil else {
                throw ContainerError.containerUnavailable
            }

            // Setup interactors (proper layered architecture)
            let repository = HeadlessRepositoryImpl()
            headlessRepository = repository
            processCardPaymentInteractor = ProcessCardPaymentInteractorImpl(repository: repository)
            logger.debug(message: "ProcessCardPaymentInteractor initialized successfully")

            // Setup network detection stream
            setupNetworkDetectionStream()
        } catch {
            logger.error(message: "Failed to setup interactors: \(error)")
        }
    }

    private func getCardNetworkForCvv() -> CardNetwork {
        if let selectedNetworkString = internalState.selectedCardNetwork,
           let selectedNetwork = CardNetwork(rawValue: selectedNetworkString) {
            return selectedNetwork
        } else {
            return CardNetwork(cardNumber: internalState.cardNumber)
        }
    }

    private func updateFieldValidationState() {
        logger.debug(message: "🔍 [FieldValidation] Current fieldValidationStates - Card: \(fieldValidationStates.cardNumber), CVV: \(fieldValidationStates.cvv), Expiry: \(fieldValidationStates.expiry), Cardholder: \(fieldValidationStates.cardholderName)")

        // Synchronize field-level validation with the scope
        updateValidationState(
            cardNumber: fieldValidationStates.cardNumber,
            cvv: fieldValidationStates.cvv,
            expiry: fieldValidationStates.expiry,
            cardholderName: fieldValidationStates.cardholderName
        )
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
        // Force UI update by publishing the change
        objectWillChange.send()
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
        logger.info(message: "🧭 [CardFormScope] Back navigation triggered:")
        logger.info(message: "🧭 [CardFormScope]   - Current context: \(presentationContext)")
        logger.info(message: "🧭 [CardFormScope]   - Should show back button: \(presentationContext.shouldShowBackButton)")

        // Only navigate back if we came from payment selection
        if presentationContext.shouldShowBackButton {
            logger.info(message: "🧭 [CardFormScope]   - Action: Navigating back via navigator")
            checkoutScope?.checkoutNavigator.navigateBack()
        } else {
            logger.info(message: "🧭 [CardFormScope]   - Action: Back navigation blocked (direct context)")
        }
    }

    public func onCancel() {
        logger.info(message: "🧭 [CardFormScope] Cancel triggered:")
        logger.info(message: "🧭 [CardFormScope]   - Current context: \(presentationContext)")
        logger.info(message: "🧭 [CardFormScope]   - Cancel behavior: \(presentationContext.cancelBehavior)")

        switch presentationContext.cancelBehavior {
        case .dismiss:
            logger.info(message: "🧭 [CardFormScope]   - Action: Dismissing entire checkout flow")
            checkoutScope?.checkoutNavigator.dismiss()
        case .navigateToPaymentSelection:
            logger.info(message: "🧭 [CardFormScope]   - Action: Navigating back to payment selection")
            checkoutScope?.checkoutNavigator.navigateToPaymentSelection()
        }
    }

    public func navigateToCountrySelection() {
        guard let navigator = checkoutScope?.checkoutNavigator else {
            logger.error(message: "Cannot navigate - checkoutNavigator is nil")
            return
        }

        navigator.navigateToCountrySelection()
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

        // Note: Field-level validation is now handled by updateValidationState()
        // called from CardDetailsView when each field updates its validation state
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
        internalState.isSubmitting = true

        do {
            try await sendBillingAddressIfNeeded()
            let cardData = try await prepareCardPaymentData()
            let result = try await processCardPayment(cardData: cardData)
            await handlePaymentSuccess(result)
        } catch {
            await handlePaymentError(error)
        }
    }

    private func sendBillingAddressIfNeeded() async throws {
        guard !billingAddressSent, let billingAddress = createBillingAddress() else { return }

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

    private func prepareCardPaymentData() async throws -> CardPaymentData {
        guard processCardPaymentInteractor != nil else {
            throw PrimerError.unknown(
                userInfo: ["error": "ProcessCardPaymentInteractor not initialized"],
                diagnosticsId: UUID().uuidString
            )
        }

        let (expiryMonth, fullYear) = try parseExpiryComponents()
        let selectedNetwork = getSelectedCardNetwork()
        let billingAddress = createInteractorBillingAddress()

        logger.debug(message: "Processing payment: card=***\(String(internalState.cardNumber.suffix(4))), month=\(expiryMonth), year=\(fullYear), network=\(selectedNetwork?.rawValue ?? "auto")")

        return CardPaymentData(
            cardNumber: internalState.cardNumber,
            cvv: internalState.cvv,
            expiryMonth: expiryMonth,
            expiryYear: fullYear,
            cardholderName: internalState.cardholderName,
            selectedNetwork: selectedNetwork,
            billingAddress: billingAddress
        )
    }

    private func parseExpiryComponents() throws -> (month: String, year: String) {
        let expiryComponents = internalState.expiryDate.components(separatedBy: "/")
        guard expiryComponents.count == 2 else {
            throw PrimerError.unknown(
                userInfo: ["error": "Invalid expiry date format"],
                diagnosticsId: UUID().uuidString
            )
        }

        let expiryMonth = expiryComponents[0]
        let expiryYear = expiryComponents[1]
        let fullYear = expiryYear.count == 2 ? "20\(expiryYear)" : expiryYear

        return (expiryMonth, fullYear)
    }

    private func getSelectedCardNetwork() -> CardNetwork? {
        guard let networkString = internalState.selectedCardNetwork else { return nil }
        return CardNetwork(rawValue: networkString)
    }

    private func processCardPayment(cardData: CardPaymentData) async throws -> PaymentResult {
        logger.debug(message: "Processing card payment using ProcessCardPaymentInteractor")

        guard let interactor = processCardPaymentInteractor else {
            throw PrimerError.unknown(
                userInfo: ["error": "ProcessCardPaymentInteractor not initialized"],
                diagnosticsId: UUID().uuidString
            )
        }

        let result = try await interactor.execute(cardData: cardData)
        logger.info(message: "Card payment processed successfully via interactor")
        return result
    }

    private func handlePaymentError(_ error: Error) async {
        logger.error(message: "Card form submission failed: \(error)")
        internalState.isSubmitting = false
        let primerError = error as? PrimerError ?? PrimerError.unknown(
            userInfo: nil,
            diagnosticsId: UUID().uuidString
        )
        checkoutScope?.handlePaymentError(primerError)
    }

    private func handlePaymentSuccess(_ result: PaymentResult) async {
        logger.info(message: "Payment processed successfully: \(result.paymentId)")
        internalState.isSubmitting = false

        // Notify the checkout scope about the success
        await MainActor.run {
            logger.info(message: "Notifying checkout scope about payment success")
            checkoutScope?.handlePaymentSuccess(result)
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

    // MARK: - Field-Level Validation State Communication

    /// Updates the form validation state based on field-level validation results.
    /// This method replaces the duplicate validation logic with direct validation states from the UI components.
    public func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool) {
        logger.debug(message: "🔍 [CardForm] Field validation states - Card: \(cardNumber), CVV: \(cvv), Expiry: \(expiry), Cardholder: \(cardholderName)")

        // Check that we have complete, valid data for all required fields
        let hasValidCardNumber = cardNumber && !internalState.cardNumber.replacingOccurrences(of: " ", with: "").isEmpty
        let hasValidCvv = cvv && !internalState.cvv.isEmpty
        let hasValidExpiry = expiry && !internalState.expiryDate.isEmpty
        let hasValidCardholderName = cardholderName && !internalState.cardholderName.isEmpty

        // Update the form validation state - only valid if all required fields are complete and valid
        internalState.isValid = hasValidCardNumber && hasValidCvv && hasValidExpiry && hasValidCardholderName

        logger.debug(message: "🔍 [CardForm] Form validation updated - Overall: \(internalState.isValid) (cardNum: \(hasValidCardNumber), cvv: \(hasValidCvv), expiry: \(hasValidExpiry), name: \(hasValidCardholderName))")

        // Clear any previous error when all fields are valid
        if internalState.isValid {
            internalState.error = nil
        }
    }
}
// swiftlint:enable identifier_name
// swiftlint:enable file_length