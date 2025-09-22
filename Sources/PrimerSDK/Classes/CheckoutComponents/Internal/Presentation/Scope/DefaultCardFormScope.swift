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

    /// The presentation context determining navigation behavior
    public private(set) var presentationContext: PresentationContext = .fromPaymentSelection

    /// State stream for external observation
    public var state: AsyncStream<StructuredCardFormState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await _ in $structuredState.values {
                    continuation.yield(structuredState)
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
    private var processCardPaymentInteractor: ProcessCardPaymentInteractor?
    private var validateInputInteractor: ValidateInputInteractor?
    private var cardNetworkDetectionInteractor: CardNetworkDetectionInteractor?

    /// Track if billing address has been sent to avoid duplicate requests
    private var billingAddressSent = false

    /// Store the current card data
    private var currentCardData: PrimerCardData?

    /// Field validation states for proper scope integration
    private var fieldValidationStates = FieldValidationStates()

    /// Structured state for form data
    @Published internal var structuredState = StructuredCardFormState()

    /// Form configuration determining which fields are displayed
    private var formConfiguration: CardFormConfiguration = .default

    /// Computed property to get the selected country from the country code
    private var selectedCountryFromCode: CountryCode.PhoneNumberCountryCode? {
        let countryCode = structuredState.data[.countryCode]
        // Computing selectedCountryFromCode
        guard !countryCode.isEmpty else {
            // Country code is empty, returning nil
            return nil
        }
        let country = CountryCode.phoneNumberCountryCodes.first { $0.code.uppercased() == countryCode.uppercased() }
        // Found country for code
        return country
    }

    // MARK: - Initialization

    init(checkoutScope: DefaultCheckoutScope, presentationContext: PresentationContext = .fromPaymentSelection) {
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext

        // Log the presentation context initialization
        // Initialized with presentation context
        // Should show back button setting logged
        // Cancel behavior setting logged
        // Instance ID logged
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

            // Resolve interactors from DI container (proper dependency injection)
            processCardPaymentInteractor = try await container.resolve(ProcessCardPaymentInteractor.self)
            cardNetworkDetectionInteractor = try await container.resolve(CardNetworkDetectionInteractor.self)

            // Interactors resolved from DI container successfully

            // Setup network detection stream through the interactor
            setupNetworkDetectionStream()
        } catch {
            // Failed to resolve interactors from DI container
        }
    }

    private func getCardNetworkForCvv() -> CardNetwork {
        if let selectedNetwork = structuredState.selectedNetwork {
            return selectedNetwork.network
        } else {
            return CardNetwork(cardNumber: structuredState.data[.cardNumber])
        }
    }

    private func updateFieldValidationState() {
        // Current field validation states

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
        guard let interactor = cardNetworkDetectionInteractor else {
            // CardNetworkDetectionInteractor not initialized
            return
        }

        Task {
            for await networks in interactor.networkDetectionStream {
                await MainActor.run {
                    // Received networks from stream
                    self.structuredState.availableNetworks = networks.map { PrimerCardNetwork(network: $0) }

                    // If multiple networks detected, clear any automatic selection
                    if networks.count > 1 {
                        self.structuredState.selectedNetwork = nil
                        self.updateSurchargeAmount(for: nil)
                        // Multiple networks detected, clearing selection
                    } else if networks.count == 1 {
                        // Single network - auto-select it
                        let network = networks[0]
                        self.structuredState.selectedNetwork = PrimerCardNetwork(network: network)
                        self.updateSurchargeAmount(for: network)
                        // Single network detected, auto-selecting
                    } else {
                        // No networks detected - clear surcharge
                        self.updateSurchargeAmount(for: nil)
                    }
                }
            }
        }
    }

    // MARK: - Update Methods

    /// Generic field update method for internal use
    public func updateField(_ fieldType: PrimerInputElementType, value: String) {
        structuredState.data[fieldType] = value

        // Call specific update method if needed for additional logic
        switch fieldType {
        case .cardNumber:
            updateCardNumber(value)
        case .cvv:
            updateCvv(value)
        case .expiryDate:
            updateExpiryDate(value)
        case .cardholderName:
            updateCardholderName(value)
        case .postalCode:
            updatePostalCode(value)
        case .countryCode:
            updateCountryCode(value)
        case .city:
            updateCity(value)
        case .state:
            updateState(value)
        case .addressLine1:
            updateAddressLine1(value)
        case .addressLine2:
            updateAddressLine2(value)
        case .phoneNumber:
            updatePhoneNumber(value)
        case .firstName:
            updateFirstName(value)
        case .lastName:
            updateLastName(value)
        case .email:
            updateEmail(value)
        case .retailer:
            updateRetailOutlet(value)
        case .otp:
            updateOtpCode(value)
        default:
            break
        }
    }

    public func updateCardNumber(_ cardNumber: String) {
        // Updating card number
        structuredState.data[.cardNumber] = cardNumber
        updateCardData()

        // Trigger network detection via interactor
        Task {
            await triggerNetworkDetection(for: cardNumber)
        }
    }

    /// Trigger network detection for the given card number
    private func triggerNetworkDetection(for cardNumber: String) async {
        guard let interactor = cardNetworkDetectionInteractor else {
            // CardNetworkDetectionInteractor not initialized
            return
        }

        // Triggering network detection
        await interactor.detectNetworks(for: cardNumber)
    }

    public func updateCvv(_ cvv: String) {
        // Updating CVV
        structuredState.data[.cvv] = cvv
        updateCardData()
    }

    public func updateExpiryDate(_ expiryDate: String) {
        // Updating expiry date
        structuredState.data[.expiryDate] = expiryDate
        updateCardData()
    }

    public func updateExpiryMonth(_ month: String) {
        // Updating expiry month
        // Parse current expiry date and update month component
        let currentExpiry = structuredState.data[.expiryDate]
        let components = currentExpiry.components(separatedBy: "/")
        let year = components.count >= 2 ? components[1] : ""
        structuredState.data[.expiryDate] = "\(month)/\(year)"
        updateCardData()
    }

    public func updateExpiryYear(_ year: String) {
        // Updating expiry year
        // Parse current expiry date and update year component
        let currentExpiry = structuredState.data[.expiryDate]
        let components = currentExpiry.components(separatedBy: "/")
        let month = components.count >= 1 ? components[0] : ""
        structuredState.data[.expiryDate] = "\(month)/\(year)"
        updateCardData()
    }

    public func updateCardholderName(_ name: String) {
        // Updating cardholder name
        structuredState.data[.cardholderName] = name
        updateCardData()
    }

    public func updateFirstName(_ firstName: String) {
        // Updating first name
        structuredState.data[.firstName] = firstName
    }

    public func updateLastName(_ lastName: String) {
        // Updating last name
        structuredState.data[.lastName] = lastName
    }

    public func updateEmail(_ email: String) {
        // Updating email
        structuredState.data[.email] = email
    }

    public func updatePhoneNumber(_ phoneNumber: String) {
        // Updating phone number
        structuredState.data[.phoneNumber] = phoneNumber
    }

    public func updateAddressLine1(_ addressLine1: String) {
        // Updating address line 1
        structuredState.data[.addressLine1] = addressLine1
    }

    public func updateAddressLine2(_ addressLine2: String) {
        // Updating address line 2
        structuredState.data[.addressLine2] = addressLine2
    }

    public func updateCity(_ city: String) {
        // Updating city
        structuredState.data[.city] = city
    }

    public func updateState(_ state: String) {
        // Updating state
        structuredState.data[.state] = state
    }

    public func updatePostalCode(_ postalCode: String) {
        // Updating postal code
        structuredState.data[.postalCode] = postalCode
    }

    public func updateCountryCode(_ countryCode: String) {
        // Updating country code
        structuredState.data[.countryCode] = countryCode

        // Update selected country in structured state
        if let country = CountryCode.phoneNumberCountryCodes.first(where: { $0.code.uppercased() == countryCode.uppercased() }) {
            structuredState.selectedCountry = PrimerCountry(
                code: country.code,
                name: country.name,
                dialCode: country.dialCode
            )
        }

        // Force UI update by publishing the change
        objectWillChange.send()
    }

    public func updateOtpCode(_ otpCode: String) {
        // Updating OTP code
        structuredState.data[.otp] = otpCode
    }

    public func updateSelectedCardNetwork(_ network: String) {
        // User selected card network

        // Update structured state
        if let cardNetwork = CardNetwork(rawValue: network) {
            structuredState.selectedNetwork = PrimerCardNetwork(network: cardNetwork)
            updateSurchargeAmount(for: cardNetwork)
        }

        updateCardData()

        // Notify interactor about the selection
        Task {
            await handleNetworkSelection(network)
        }
    }

    /// Handle user selection of a card network for co-badged cards
    private func handleNetworkSelection(_ networkString: String) async {
        guard let interactor = cardNetworkDetectionInteractor,
              let cardNetwork = CardNetwork(rawValue: networkString) else { return }

        // Handling network selection
        await interactor.selectNetwork(cardNetwork)
    }

    /// Handle detected networks from CardDetailsView
    func handleDetectedNetworks(_ networks: [CardNetwork]) {
        // CardDetailsView detected networks
        // The actual network detection is handled via the stream in setupNetworkDetectionStream
    }

    public func updateRetailOutlet(_ retailOutlet: String) {
        // Updating retail outlet
        structuredState.data[.retailer] = retailOutlet
    }

    // MARK: - Navigation Methods

    public func onSubmit() {
        Task {
            await submit()
        }
    }

    public func onBack() {
        // Back navigation triggered
        // Current context logged
        // Should show back button setting logged

        // Only navigate back if we came from payment selection
        if presentationContext.shouldShowBackButton {
            // Action: Navigating back via navigator
            checkoutScope?.checkoutNavigator.navigateBack()
        } else {
            // Action: Back navigation blocked (direct context)
        }
    }

    public func onCancel() {
        // Cancel triggered
        // Current context logged
        // Cancel behavior setting logged

        switch presentationContext.cancelBehavior {
        case .dismiss:
            // Action: Dismissing entire checkout flow
            checkoutScope?.checkoutNavigator.dismiss()
        case .navigateToPaymentSelection:
            // Action: Navigating back to payment selection
            checkoutScope?.checkoutNavigator.navigateToPaymentSelection()
        }
    }

    public func navigateToCountrySelection() {
        guard let navigator = checkoutScope?.checkoutNavigator else {
            // Cannot navigate - checkoutNavigator is nil
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
        // This method is no longer needed since we update expiryDate directly
        // in updateExpiryMonth and updateExpiryYear methods
    }

    private func updateCardData() {
        // Create PrimerCardData
        let cardData = PrimerCardData(
            cardNumber: structuredState.data[.cardNumber].replacingOccurrences(of: " ", with: ""),
            expiryDate: structuredState.data[.expiryDate],
            cvv: structuredState.data[.cvv],
            cardholderName: structuredState.data[.cardholderName].isEmpty ? nil : structuredState.data[.cardholderName]
        )

        // Set card network if selected (for co-badged cards)
        if let selectedNetwork = structuredState.selectedNetwork {
            cardData.cardNetwork = selectedNetwork.network
        }

        currentCardData = cardData

        // Note: Field-level validation is now handled by updateValidationState()
        // called from CardDetailsView when each field updates its validation state
    }

    // Network detection is now handled by CardNetworkDetectionInteractor

    private func createBillingAddress() -> ClientSession.Address? {
        // Only create address if we have required fields
        guard !structuredState.data[.postalCode].isEmpty else { return nil }

        return ClientSession.Address(
            firstName: structuredState.data[.firstName].isEmpty ? nil : structuredState.data[.firstName],
            lastName: structuredState.data[.lastName].isEmpty ? nil : structuredState.data[.lastName],
            addressLine1: structuredState.data[.addressLine1].isEmpty ? nil : structuredState.data[.addressLine1],
            addressLine2: structuredState.data[.addressLine2].isEmpty ? nil : structuredState.data[.addressLine2],
            city: structuredState.data[.city].isEmpty ? nil : structuredState.data[.city],
            postalCode: structuredState.data[.postalCode],
            state: structuredState.data[.state].isEmpty ? nil : structuredState.data[.state],
            countryCode: structuredState.data[.countryCode].isEmpty ? nil : CountryCode(rawValue: structuredState.data[.countryCode])
        )
    }

    private func createInteractorBillingAddress() -> BillingAddress? {
        // Only create address if we have required fields
        guard !structuredState.data[.postalCode].isEmpty else { return nil }

        return BillingAddress(
            firstName: structuredState.data[.firstName].isEmpty ? nil : structuredState.data[.firstName],
            lastName: structuredState.data[.lastName].isEmpty ? nil : structuredState.data[.lastName],
            addressLine1: structuredState.data[.addressLine1].isEmpty ? nil : structuredState.data[.addressLine1],
            addressLine2: structuredState.data[.addressLine2].isEmpty ? nil : structuredState.data[.addressLine2],
            city: structuredState.data[.city].isEmpty ? nil : structuredState.data[.city],
            state: structuredState.data[.state].isEmpty ? nil : structuredState.data[.state],
            postalCode: structuredState.data[.postalCode].isEmpty ? nil : structuredState.data[.postalCode],
            countryCode: structuredState.data[.countryCode].isEmpty ? nil : structuredState.data[.countryCode],
            phoneNumber: nil // Not currently collected in this form
        )
    }

    // MARK: - Public Submit Method

    func submit() async {
        // Card form submit initiated
        structuredState.isLoading = true

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

        // Sending billing address via Client Session Actions

        do {
            try await ClientSessionActionsModule.updateBillingAddressViaClientSessionActionWithAddressIfNeeded(billingAddress)
            self.billingAddressSent = true
        } catch {
            // Failed to send billing address
            // Re-throw the error to be handled by the caller
            throw error
        }
    }

    private func prepareCardPaymentData() async throws -> CardPaymentData {
        guard processCardPaymentInteractor != nil else {
            throw PrimerError.invalidArchitecture(
                description: "ProcessCardPaymentInteractor not initialized",
                recoverSuggestion: "Ensure proper initialization of payment components",
            )
        }

        let (expiryMonth, fullYear) = try parseExpiryComponents()
        let selectedNetwork = getSelectedCardNetwork()
        let billingAddress = createInteractorBillingAddress()

        // Processing payment with selected network

        return CardPaymentData(
            cardNumber: structuredState.data[.cardNumber],
            cvv: structuredState.data[.cvv],
            expiryMonth: expiryMonth,
            expiryYear: fullYear,
            cardholderName: structuredState.data[.cardholderName],
            selectedNetwork: selectedNetwork,
            billingAddress: billingAddress
        )
    }

    private func parseExpiryComponents() throws -> (month: String, year: String) {
        let expiryComponents = structuredState.data[.expiryDate].components(separatedBy: "/")
        guard expiryComponents.count == 2 else {
            throw PrimerError.invalidValue(
                key: "expiryDate",
                value: structuredState.data[.expiryDate],
                reason: "Invalid expiry date format. Expected MM/YY or MM/YYYY"
            )
        }

        let expiryMonth = expiryComponents[0]
        let expiryYear = expiryComponents[1]
        let fullYear = expiryYear.count == 2 ? "20\(expiryYear)" : expiryYear

        return (expiryMonth, fullYear)
    }

    private func getSelectedCardNetwork() -> CardNetwork? {
        return structuredState.selectedNetwork?.network
    }

    private func processCardPayment(cardData: CardPaymentData) async throws -> PaymentResult {
        // Processing card payment using ProcessCardPaymentInteractor

        guard let interactor = processCardPaymentInteractor else {
            throw PrimerError.invalidArchitecture(
                description: "ProcessCardPaymentInteractor not initialized",
                recoverSuggestion: "Ensure proper initialization of payment components"
            )
        }

        let result = try await interactor.execute(cardData: cardData)
        // Card payment processed successfully via interactor
        return result
    }

    private func handlePaymentError(_ error: Error) async {
        // Card form submission failed
        structuredState.isLoading = false
        let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
        checkoutScope?.handlePaymentError(primerError)
    }

    private func handlePaymentSuccess(_ result: PaymentResult) async {
        // Payment processed successfully
        structuredState.isLoading = false

        // Notify the checkout scope about the success
        await MainActor.run {
            // Notifying checkout scope about payment success
            checkoutScope?.handlePaymentSuccess(result)
        }
    }

    // MARK: - Surcharge Management

    /// Updates the surcharge amount based on the selected card network
    private func updateSurchargeAmount(for network: CardNetwork?) {
        guard let network = network else {
            structuredState.surchargeAmount = nil
            // Clearing surcharge (no network)
            return
        }

        // Check if surcharge should be displayed (same logic as Drop-in)
        guard let surcharge = network.surcharge,
              PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
              let currency = AppState.current.currency else {
            structuredState.surchargeAmount = nil
            // No surcharge for network
            return
        }

        // Format surcharge amount similar to Drop-in implementation
        let formattedSurcharge = "+ \(surcharge.toCurrencyString(currency: currency))"
        structuredState.surchargeAmount = formattedSurcharge
        // Updated surcharge for network
    }

    // MARK: - Field-Level Validation State Communication

    /// Updates the form validation state based on field-level validation results.
    /// This method replaces the duplicate validation logic with direct validation states from the UI components.
    public func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool) {
        // Field validation states

        // Check that we have complete, valid data for all required fields
        let hasValidCardNumber = cardNumber && !structuredState.data[.cardNumber].replacingOccurrences(of: " ", with: "").isEmpty
        let hasValidCvv = cvv && !structuredState.data[.cvv].isEmpty
        let hasValidExpiry = expiry && !structuredState.data[.expiryDate].isEmpty
        let hasValidCardholderName = cardholderName && !structuredState.data[.cardholderName].isEmpty

        // Update the form validation state - only valid if all required fields are complete and valid
        structuredState.isValid = hasValidCardNumber && hasValidCvv && hasValidExpiry && hasValidCardholderName

        // Form validation updated

        // Clear any previous field errors when all fields are valid
        if structuredState.isValid {
            structuredState.fieldErrors.removeAll()
        }
    }

    // MARK: - Individual Field Validation Methods

    /// Updates validation state for card number field specifically
    public func updateCardNumberValidationState(_ isValid: Bool) {
        fieldValidationStates.cardNumber = isValid
        updateFieldValidationState()
        // CardNumber validation state updated
    }

    /// Updates validation state for CVV field specifically
    public func updateCvvValidationState(_ isValid: Bool) {
        fieldValidationStates.cvv = isValid
        updateFieldValidationState()
        // CVV validation state updated
    }

    /// Updates validation state for expiry date field specifically
    public func updateExpiryValidationState(_ isValid: Bool) {
        fieldValidationStates.expiry = isValid
        updateFieldValidationState()
        // Expiry validation state updated
    }

    /// Updates validation state for cardholder name field specifically
    public func updateCardholderNameValidationState(_ isValid: Bool) {
        fieldValidationStates.cardholderName = isValid
        updateFieldValidationState()
        // CardholderName validation state updated
    }

    /// Updates validation state for postal code field specifically
    public func updatePostalCodeValidationState(_ isValid: Bool) {
        fieldValidationStates.postalCode = isValid
        updateFieldValidationState()
        // PostalCode validation state updated
    }

    /// Updates validation state for city field specifically
    public func updateCityValidationState(_ isValid: Bool) {
        fieldValidationStates.city = isValid
        updateFieldValidationState()
        // City validation state updated
    }

    /// Updates validation state for state field specifically
    public func updateStateValidationState(_ isValid: Bool) {
        fieldValidationStates.state = isValid
        updateFieldValidationState()
        // State validation state updated
    }

    /// Updates validation state for address line 1 field specifically
    public func updateAddressLine1ValidationState(_ isValid: Bool) {
        fieldValidationStates.addressLine1 = isValid
        updateFieldValidationState()
        // AddressLine1 validation state updated
    }

    /// Updates validation state for address line 2 field specifically
    public func updateAddressLine2ValidationState(_ isValid: Bool) {
        fieldValidationStates.addressLine2 = isValid
        updateFieldValidationState()
        // AddressLine2 validation state updated
    }

    /// Updates validation state for first name field specifically
    public func updateFirstNameValidationState(_ isValid: Bool) {
        fieldValidationStates.firstName = isValid
        updateFieldValidationState()
        // FirstName validation state updated
    }

    /// Updates validation state for last name field specifically
    public func updateLastNameValidationState(_ isValid: Bool) {
        fieldValidationStates.lastName = isValid
        updateFieldValidationState()
        // LastName validation state updated
    }

    /// Updates validation state for email field specifically
    public func updateEmailValidationState(_ isValid: Bool) {
        fieldValidationStates.email = isValid
        updateFieldValidationState()
        // Email validation state updated
    }

    /// Updates validation state for phone number field specifically
    public func updatePhoneNumberValidationState(_ isValid: Bool) {
        fieldValidationStates.phoneNumber = isValid
        updateFieldValidationState()
        // PhoneNumber validation state updated
    }

    /// Updates validation state for country code field specifically
    public func updateCountryCodeValidationState(_ isValid: Bool) {
        fieldValidationStates.countryCode = isValid
        updateFieldValidationState()
        // CountryCode validation state updated
    }

    // MARK: - Structured State Implementation

    /// Implementation of getFieldValue using structured state
    public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
        return structuredState.data[fieldType]
    }

    /// Implementation of setFieldError using structured state
    public func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String? = nil) {
        structuredState.setError(message, for: fieldType, errorCode: errorCode)
        // Set error for field
    }

    /// Implementation of clearFieldError using structured state
    public func clearFieldError(_ fieldType: PrimerInputElementType) {
        structuredState.clearError(for: fieldType)
        // Cleared error for field
    }

    /// Implementation of getFieldError using structured state
    public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
        return structuredState.errorMessage(for: fieldType)
    }

    /// Implementation of getFormConfiguration
    public func getFormConfiguration() -> CardFormConfiguration {
        return formConfiguration
    }

    /// Update form configuration (for dynamic field management)
    func updateFormConfiguration(_ configuration: CardFormConfiguration) {
        formConfiguration = configuration
        structuredState.configuration = configuration
        // Updated form configuration
    }

    // MARK: - ViewBuilder Method Implementations

    @ViewBuilder
    public func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> any View {
        CardNumberInputField(
            label: label,
            placeholder: "1234 1234 1234 1234",
            scope: self,
            selectedNetwork: structuredState.selectedNetwork?.network,
            styling: styling ?? defaultFieldStyling?["cardNumber"]
        )
    }

    @ViewBuilder
    public func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> any View {
        ExpiryDateInputField(
            label: label,
            placeholder: "12/25",
            scope: self,
            styling: styling ?? defaultFieldStyling?["expiryDate"]
        )
    }

    @ViewBuilder
    public func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> any View {
        CVVInputField(
            label: label,
            placeholder: getCardNetworkForCvv() == .amex ? "1234" : "123",
            scope: self,
            cardNetwork: structuredState.selectedNetwork?.network ?? getCardNetworkForCvv(),
            styling: styling ?? defaultFieldStyling?["cvv"]
        )
    }

    @ViewBuilder
    public func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> any View {
        CardholderNameInputField(
            label: label,
            placeholder: "Full name",
            scope: self,
            styling: styling ?? defaultFieldStyling?["cardholderName"]
        )
    }

    @ViewBuilder
    public func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> any View {
        CountryInputFieldWrapper(
            scope: self,
            label: label,
            placeholder: "Select Country",
            styling: styling ?? defaultFieldStyling?["country"],
            onValidationChange: nil,
            onOpenCountrySelector: nil
        )
    }
    @ViewBuilder
    public func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> any View {
        PostalCodeInputField(
            label: label,
            placeholder: "Postal Code",
            scope: self,
            styling: styling ?? defaultFieldStyling?["postalCode"]
        )
    }

    @ViewBuilder
    public func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> any View {
        CityInputField(
            label: label,
            placeholder: "City",
            scope: self,
            styling: styling ?? defaultFieldStyling?["city"]
        )
    }

    @ViewBuilder
    public func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> any View {
        StateInputField(
            label: label,
            placeholder: "State",
            scope: self,
            styling: styling ?? defaultFieldStyling?["state"]
        )
    }

    @ViewBuilder
    public func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> any View {
        AddressLineInputField(
            label: label,
            placeholder: "Address Line 1",
            isRequired: true,
            inputType: .addressLine1,
            scope: self,
            styling: styling ?? defaultFieldStyling?["addressLine1"]
        )
    }

    @ViewBuilder
    public func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> any View {
        AddressLineInputField(
            label: label,
            placeholder: "Address Line 2",
            isRequired: false,
            inputType: .addressLine2,
            scope: self,
            styling: styling ?? defaultFieldStyling?["addressLine2"]
        )
    }

    @ViewBuilder
    public func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> any View {
        NameInputField(
            label: label,
            placeholder: "First Name",
            inputType: .firstName,
            scope: self,
            styling: styling ?? defaultFieldStyling?["firstName"]
        )
    }

    @ViewBuilder
    public func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> any View {
        NameInputField(
            label: label,
            placeholder: "Last Name",
            inputType: .lastName,
            scope: self,
            styling: styling ?? defaultFieldStyling?["lastName"]
        )
    }

    @ViewBuilder
    public func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> any View {
        EmailInputField(
            label: label,
            placeholder: "Email",
            scope: self,
            styling: styling ?? defaultFieldStyling?["email"]
        )
    }

    @ViewBuilder
    public func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> any View {
        // Note: PhoneNumberInputField might not exist, using NameInputField as placeholder
        NameInputField(
            label: label,
            placeholder: "Phone Number",
            inputType: .phoneNumber,
            scope: self,
            styling: styling ?? defaultFieldStyling?["phoneNumber"]
        )
    }

    @ViewBuilder
    public func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> any View {
        // Note: RetailOutletInputField might not exist, using NameInputField as placeholder
        NameInputField(
            label: label,
            placeholder: "Retail Outlet",
            inputType: .retailer,
            scope: self,
            styling: styling ?? defaultFieldStyling?["retailOutlet"]
        )
    }

    @ViewBuilder
    public func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> any View {
        OTPCodeInputField(
            label: label,
            placeholder: "OTP Code",
            scope: self,
            styling: styling ?? defaultFieldStyling?["otpCode"]
        )
    }
}

// swiftlint:enable identifier_name
// swiftlint:enable file_length
