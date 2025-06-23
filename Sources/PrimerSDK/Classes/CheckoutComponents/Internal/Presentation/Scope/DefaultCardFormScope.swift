//
//  DefaultCardFormScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default implementation of PrimerCardFormScope
@available(iOS 15.0, *)
@MainActor
internal final class DefaultCardFormScope: PrimerCardFormScope, ObservableObject, LogReporter {
    // MARK: - Properties
    
    /// The current card form state
    @Published private var internalState = PrimerCardFormScope.State()
    
    /// State stream for external observation
    public var state: AsyncStream<PrimerCardFormScope.State> {
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
    
    public var cardNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var cvvInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var expiryDateInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var cardholderNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var firstNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var lastNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var emailInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var phoneNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var addressLine1Input: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var addressLine2Input: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var cityInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var stateInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var postalCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var countryInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var otpCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)?
    public var container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)?
    public var errorView: (@ViewBuilder (_ error: String) -> any View)?
    public var cobadgedCardsView: (@ViewBuilder (_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> any View)?
    
    // MARK: - Private Properties
    
    private weak var checkoutScope: DefaultCheckoutScope?
    private let diContainer: DIContainer
    private var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
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
        self.diContainer = DIContainer.global
        
        Task {
            await setupInteractors()
            await initializeRawDataManager()
        }
    }
    
    // MARK: - Setup
    
    private func setupInteractors() async {
        do {
            processCardPaymentInteractor = try await diContainer.resolve(ProcessCardPaymentInteractor.self)
            validateInputInteractor = try await diContainer.resolve(ValidateInputInteractor.self)
        } catch {
            log(logLevel: .error, message: "Failed to setup interactors: \\(error)")
        }
    }
    
    private func initializeRawDataManager() async {
        do {
            // Initialize RawDataManager for payment card
            rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
                paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                delegate: self,
                isUsedInDropIn: false
            )
            
            log(logLevel: .debug, message: "RawDataManager initialized for payment card")
        } catch {
            log(logLevel: .error, message: "Failed to initialize RawDataManager: \\(error)")
            checkoutScope?.handlePaymentError(error as? PrimerError ?? PrimerError.failedToLoadAvailablePaymentMethods(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            ))
        }
    }
    
    // MARK: - Update Methods
    
    public func updateCardNumber(_ cardNumber: String) {
        log(logLevel: .debug, message: "Updating card number")
        internalState.cardNumber = cardNumber
        updateCardData()
        
        // Check for co-badged cards
        detectAvailableNetworks(from: cardNumber)
    }
    
    public func updateCvv(_ cvv: String) {
        log(logLevel: .debug, message: "Updating CVV")
        internalState.cvv = cvv
        updateCardData()
    }
    
    public func updateExpiryDate(_ expiryDate: String) {
        log(logLevel: .debug, message: "Updating expiry date: \\(expiryDate)")
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
        log(logLevel: .debug, message: "Updating expiry month: \\(month)")
        internalState.expiryMonth = month
        updateExpiryDateFromComponents()
        updateCardData()
    }
    
    public func updateExpiryYear(_ year: String) {
        log(logLevel: .debug, message: "Updating expiry year: \\(year)")
        internalState.expiryYear = year
        updateExpiryDateFromComponents()
        updateCardData()
    }
    
    public func updateCardholderName(_ name: String) {
        log(logLevel: .debug, message: "Updating cardholder name")
        internalState.cardholderName = name
        updateCardData()
    }
    
    public func updateFirstName(_ firstName: String) {
        log(logLevel: .debug, message: "Updating first name")
        internalState.firstName = firstName
    }
    
    public func updateLastName(_ lastName: String) {
        log(logLevel: .debug, message: "Updating last name")
        internalState.lastName = lastName
    }
    
    public func updateEmail(_ email: String) {
        log(logLevel: .debug, message: "Updating email")
        internalState.email = email
    }
    
    public func updatePhoneNumber(_ phoneNumber: String) {
        log(logLevel: .debug, message: "Updating phone number")
        internalState.phoneNumber = phoneNumber
    }
    
    public func updateAddressLine1(_ addressLine1: String) {
        log(logLevel: .debug, message: "Updating address line 1")
        internalState.addressLine1 = addressLine1
    }
    
    public func updateAddressLine2(_ addressLine2: String) {
        log(logLevel: .debug, message: "Updating address line 2")
        internalState.addressLine2 = addressLine2
    }
    
    public func updateCity(_ city: String) {
        log(logLevel: .debug, message: "Updating city")
        internalState.city = city
    }
    
    public func updateState(_ state: String) {
        log(logLevel: .debug, message: "Updating state")
        internalState.state = state
    }
    
    public func updatePostalCode(_ postalCode: String) {
        log(logLevel: .debug, message: "Updating postal code")
        internalState.postalCode = postalCode
    }
    
    public func updateCountryCode(_ countryCode: String) {
        log(logLevel: .debug, message: "Updating country code: \\(countryCode)")
        internalState.countryCode = countryCode
    }
    
    public func updateOtpCode(_ otpCode: String) {
        log(logLevel: .debug, message: "Updating OTP code")
        internalState.otpCode = otpCode
    }
    
    public func updateSelectedCardNetwork(_ network: String) {
        log(logLevel: .debug, message: "Updating selected card network: \\(network)")
        internalState.selectedCardNetwork = network
        updateCardData()
    }
    
    // MARK: - Private Methods
    
    private func updateExpiryDateFromComponents() {
        let month = internalState.expiryMonth
        let year = internalState.expiryYear
        
        if !month.isEmpty && !year.isEmpty {
            internalState.expiryDate = "\\(month)/\\(year)"
        }
    }
    
    private func updateCardData() {
        guard let rawDataManager = rawDataManager else { return }
        
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
        rawDataManager.rawData = cardData
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
            state: internalState.state.isEmpty ? nil : internalState.state,
            postalCode: internalState.postalCode,
            countryCode: internalState.countryCode.isEmpty ? nil : internalState.countryCode
        )
    }
    
    // MARK: - Public Submit Method
    
    func submit() async {
        log(logLevel: .debug, message: "Card form submit initiated")
        
        // Update state to submitting
        internalState.isSubmitting = true
        
        do {
            // Send billing address first if needed
            if !billingAddressSent, let billingAddress = createBillingAddress() {
                log(logLevel: .debug, message: "Sending billing address via Client Session Actions")
                
                await withCheckedContinuation { continuation in
                    ClientSessionActionsModule.updateBillingAddressViaClientSessionActionWithAddressIfNeeded(billingAddress)
                        .done {
                            self.billingAddressSent = true
                            continuation.resume()
                        }
                        .catch { error in
                            self.log(logLevel: .error, message: "Failed to send billing address: \\(error)")
                            continuation.resume()
                        }
                }
            }
            
            // Submit card data via RawDataManager
            guard let rawDataManager = rawDataManager else {
                throw PrimerError.invalidValue(
                    key: "rawDataManager",
                    value: nil,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
            }
            
            // RawDataManager submit is synchronous and uses delegates
            rawDataManager.submit()
            
        } catch {
            log(logLevel: .error, message: "Card form submission failed: \\(error)")
            internalState.isSubmitting = false
            checkoutScope?.handlePaymentError(error as? PrimerError ?? PrimerError.unknown(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            ))
        }
    }
}

// MARK: - RawDataManager Delegate

@available(iOS 15.0, *)
extension DefaultCardFormScope: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?) {
        log(logLevel: .debug, message: "Card data validation result: \\(isValid)")
        
        internalState.isValid = isValid
        
        if let errors = errors {
            let errorMessages = errors.compactMap { ($0 as? PrimerError)?.errorDescription }
            internalState.error = errorMessages.first
        } else {
            internalState.error = nil
        }
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState state: PrimerValidationState) {
        log(logLevel: .debug, message: "Will fetch metadata for state: \\(state)")
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState state: PrimerValidationState) {
        log(logLevel: .debug, message: "Received metadata for state: \\(state)")
        
        // Handle card network metadata for co-badged cards
        if let cardMetadata = metadata as? PrimerCardNumberEntryMetadata {
            if let networks = cardMetadata.cardNetworks, networks.count > 1 {
                // Multiple networks available - co-badged card
                availableCardNetworks = networks
                internalState.availableCardNetworks = networks.map { $0.rawValue }
                
                // Auto-select first network if none selected
                if internalState.selectedCardNetwork == nil {
                    internalState.selectedCardNetwork = networks.first?.rawValue
                }
            }
        }
    }
}

// MARK: - PrimerHeadlessUniversalCheckoutDelegate

@available(iOS 15.0, *)
extension DefaultCardFormScope: PrimerHeadlessUniversalCheckoutDelegate {
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckout(with data: PrimerCheckoutData) {
        log(logLevel: .debug, message: "Checkout completed successfully")
        internalState.isSubmitting = false
        
        // Create payment result
        let paymentResult = PaymentResult(
            id: data.payment?.id ?? UUID().uuidString,
            orderId: data.payment?.orderId,
            status: "SUCCESS"
        )
        
        checkoutScope?.handlePaymentSuccess(paymentResult)
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError error: any Error, checkoutData: PrimerCheckoutData?) {
        log(logLevel: .error, message: "Checkout failed: \\(error)")
        internalState.isSubmitting = false
        
        checkoutScope?.handlePaymentError(error as? PrimerError ?? PrimerError.unknown(
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        ))
    }
}