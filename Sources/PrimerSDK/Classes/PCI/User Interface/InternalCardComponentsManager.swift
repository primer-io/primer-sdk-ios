//
//  InternalCardComponentsManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable large_tuple

import UIKit

@objc
internal protocol InternalCardComponentsManagerDelegate {
    /// The cardComponentsManager(_:clientTokenCallback:) can be used to provide the CardComponentsManager
    /// with an access token from the merchants backend.
    /// This delegate function is optional since you can initialize the CardComponentsManager with an access token.
    /// Still, if the access token is not valid, the CardComponentsManager will try to acquire
    /// an access token through this function.
    @objc optional func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager,
                                              clientTokenCallback completion: @escaping (String?, Error?) -> Void)
    /// The cardComponentsManager(_:onTokenizeSuccess:) is the only required method, and it will return the payment method token (which
    /// contains all the information needed)
    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager,
                               onTokenizeSuccess paymentMethodToken: PrimerPaymentMethodTokenData)
    /// The cardComponentsManager(_:tokenizationFailedWith:) will return any tokenization errors that have occured.
    @objc optional func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager,
                                              tokenizationFailedWith errors: [Error])
    /// The cardComponentsManager(_:isLoading:) will return true when the CardComponentsManager
    /// is performing an async operation and waiting for a result, false when loading has finished.
    @objc optional func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager,
                                              isLoading: Bool)
}

protocol InternalCardComponentsManagerProtocol {
    var cardnumberField: PrimerCardNumberFieldView { get }
    var expiryDateField: PrimerExpiryDateFieldView { get }
    var cvvField: PrimerCVVFieldView { get }
    var cardholderField: PrimerCardholderNameFieldView? { get }
    var selectedCardNetwork: CardNetwork? { get }
    var delegate: InternalCardComponentsManagerDelegate { get }
    var customerId: String? { get }
    var merchantIdentifier: String? { get }
    var amount: Int? { get }
    var currency: Currency? { get }
    var decodedJWTToken: DecodedJWTToken? { get }
    var paymentMethodsConfig: PrimerAPIConfiguration? { get }

    func tokenize()
}

typealias BillingAddressField = (fieldView: PrimerTextFieldView,
                                 containerFieldView: PrimerCustomFieldView,
                                 isFieldHidden: Bool)

@objc
final class InternalCardComponentsManager: NSObject, InternalCardComponentsManagerProtocol, LogReporter {

    var cardnumberField: PrimerCardNumberFieldView
    var expiryDateField: PrimerExpiryDateFieldView
    var cvvField: PrimerCVVFieldView
    var cardholderField: PrimerCardholderNameFieldView?
    var selectedCardNetwork: CardNetwork? // Network selected by the customer in Co-Badged Cards feature
    var billingAddressFieldViews: [PrimerTextFieldView]?
    var isRequiringCVVInput: Bool
    var paymentMethodType: String
    let delegate: InternalCardComponentsManagerDelegate
    var customerId: String?
    var merchantIdentifier: String?
    var amount: Int?
    var currency: Currency?
    internal var decodedJWTToken: DecodedJWTToken? {
        return PrimerAPIConfigurationModule.decodedJWTToken
    }
    internal var paymentMethodsConfig: PrimerAPIConfiguration?
    internal var primerPaymentMethodType: PrimerPaymentMethodType
    private(set) public var isLoading: Bool = false
    internal private(set) var paymentMethod: PrimerPaymentMethodTokenData?

    let tokenizationService: TokenizationServiceProtocol

    deinit {
        setIsLoading(false)
    }

    /// The CardComponentsManager can be initialized with/out an access token.
    /// In the case that is initialized without an access token, the delegate function cardComponentsManager(_:clientTokenCallback:) will be called.
    /// You can initialize an instance (representing a session) by registering the necessary PrimerTextFieldViews
    init(
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        billingAddressFieldViews: [PrimerTextFieldView]?,
        paymentMethodType: String? = nil,
        isRequiringCVVInput: Bool = true,
        tokenizationService: TokenizationServiceProtocol,
        delegate: InternalCardComponentsManagerDelegate
    ) {
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderNameField
        self.billingAddressFieldViews = billingAddressFieldViews
        if let paymentMethodType = paymentMethodType,
           let primerPaymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) {
            self.primerPaymentMethodType = primerPaymentMethodType
            self.paymentMethodType = primerPaymentMethodType.rawValue
        } else {
            self.primerPaymentMethodType = .paymentCard
            self.paymentMethodType = self.primerPaymentMethodType.rawValue
        }
        self.isRequiringCVVInput = isRequiringCVVInput

        self.tokenizationService = tokenizationService
        self.delegate = delegate

        super.init()
    }

    internal func setIsLoading(_ isLoading: Bool) {
        if self.isLoading == isLoading { return }
        self.isLoading = isLoading
        delegate.cardComponentsManager?(self, isLoading: isLoading)
    }

    private func fetchClientToken() -> Promise<DecodedJWTToken> {
        return Promise { seal in
            delegate.cardComponentsManager?(self, clientTokenCallback: { clientToken, error in
                guard error == nil, let clientToken = clientToken else {
                    seal.reject(error!)
                    return
                }

                let apiConfigurationModule = PrimerAPIConfigurationModule()
                firstly {
                    apiConfigurationModule.setupSession(
                        forClientToken: clientToken,
                        requestDisplayMetadata: false,
                        requestClientTokenValidation: false,
                        requestVaultedPaymentMethods: false)
                }
                .done {
                    if let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken {
                        seal.fulfill(decodedJWTToken)
                    } else {
                        let preconditionMessage = "Decoded client token should never be null at this point."
                        precondition(false, preconditionMessage)
                        seal.reject(handled(primerError: .invalidValue(key: "self.decodedClientToken")))
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            })
        }
    }

    private func fetchClientTokenIfNeeded() -> Promise<DecodedJWTToken> {
        return Promise { seal in
            do {
                if let decodedJWTToken = decodedJWTToken {
                    try decodedJWTToken.validate()
                    seal.fulfill(decodedJWTToken)
                } else {
                    firstly {
                        self.fetchClientToken()
                    }
                    .done { decodedJWTToken in
                        seal.fulfill(decodedJWTToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }

            } catch {
                switch error {
                case PrimerError.invalidClientToken:
                    firstly {
                        self.fetchClientToken()
                    }
                    .done { decodedJWTToken in
                        seal.fulfill(decodedJWTToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                default:
                    seal.reject(error)
                }
            }

        }
    }

    private func validateCardComponents() throws {
        var errors: [Error] = []

        if cardnumberField.cardnumber.isEmpty {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number can not be blank."))

        } else if !cardnumberField.cardnumber.isValidCardNumber {
            errors.append(PrimerValidationError.invalidCardnumber(message: "Card number is not valid."))
        }

        if expiryDateField.expiryMonth == nil || expiryDateField.expiryYear == nil {
            let message = """
Expiry date is not valid. Valid expiry date format is 2 characters for expiry month\
and 4 characters for expiry year separated by '/'.
"""
            errors.append(PrimerValidationError.invalidExpiryDate(message: message))
        }

        if isRequiringCVVInput {
            if cvvField.cvv.isEmpty {
                errors.append(PrimerValidationError.invalidCvv(message: "CVV cannot be blank."))
            } else if !cvvField.cvv.isValidCVV(cardNetwork: selectedCardNetwork ?? CardNetwork(cardNumber: cardnumberField.cardnumber)) {
                errors.append(PrimerValidationError.invalidCvv(message: "CVV is not valid."))
            }
        }

        billingAddressFieldViews?.filter { $0.isTextValid == false }.forEach {
            if let simpleCardFormTextFieldView = $0 as? PrimerSimpleCardFormTextFieldView {
                switch simpleCardFormTextFieldView.validation {
                case .invalid(let error): errors.append(handled(error: error!))
                default: break
                }
            }
        }

        if !errors.isEmpty {
            throw handled(primerError: .underlyingErrors(errors: errors))
        }
    }

    /// Gets the first two digits of a year component
    /// e.g.
    /// current year = "2022"
    /// first two digits = "20"
    private var cardExpirationYear: String? {
        guard let expiryYear = self.expiryDateField.expiryYear else { return nil }
        return expiryYear.normalizedFourDigitYear()
    }

    private var tokenizationPaymentInstrument: TokenizationRequestBodyPaymentInstrument? {

        guard let cardExpirationYear = cardExpirationYear,
              let expiryMonth = self.expiryDateField.expiryMonth else {
            return nil
        }

        if isRequiringCVVInput {

            let cardPaymentInstrument = CardPaymentInstrument(number: cardnumberField.cardnumber,
                                                              cvv: cvvField.cvv,
                                                              expirationMonth: expiryMonth,
                                                              expirationYear: cardExpirationYear,
                                                              cardholderName: cardholderField?.cardholderName,
                                                              preferredNetwork: selectedCardNetwork?.rawValue)
            return cardPaymentInstrument

        } else if let configId = AppState.current.apiConfiguration?.getConfigId(for: primerPaymentMethodType.rawValue),
                  let cardholderName = cardholderField?.cardholderName {

            let cardOffSessionPaymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                                  paymentMethodType: primerPaymentMethodType.rawValue,
                                                                                  number: cardnumberField.cardnumber,
                                                                                  expirationMonth: expiryMonth,
                                                                                  expirationYear: cardExpirationYear,
                                                                                  cardholderName: cardholderName)
            return cardOffSessionPaymentInstrument
        }

        return nil
    }

    public func tokenize() {
        do {
            setIsLoading(true)

            try validateCardComponents()

            firstly {
                self.fetchClientTokenIfNeeded()
            }
            .done { _ in

                guard let tokenizationPaymentInstrument = self.tokenizationPaymentInstrument else {
                    let err = handled(primerError: .invalidValue(key: "Payment Instrument"))
                    self.delegate.cardComponentsManager?(self, tokenizationFailedWith: [err])
                    return
                }

                // Validate card network before tokenization
                if let cardPaymentInstrument = tokenizationPaymentInstrument as? CardPaymentInstrument {
                    let allowedCardNetworks = Set(Array.allowedCardNetworks)
                    let autoDetectedNetwork = CardNetwork(cardNumber: cardPaymentInstrument.number)
                    
                    // Use user-selected network if available (for co-badged cards)
                    var cardNetwork = self.selectedCardNetwork ?? autoDetectedNetwork
                    
                    // If the auto-detected network is not allowed but this might be a co-badged card,
                    // try to find an allowed network for this card number
                    if !allowedCardNetworks.contains(cardNetwork) && self.selectedCardNetwork == nil {
                        // For co-badged cards, we need to check if there are other networks this card supports
                        // that are in the allowed list. Common co-badged scenarios:
                        // - Visa/Cartes Bancaires co-badged cards
                        if autoDetectedNetwork == .visa && allowedCardNetworks.contains(.cartesBancaires) {
                            // Check if this card could be Cartes Bancaires (starts with 4035, 4360, etc.)
                            let cardNumber = cardPaymentInstrument.number
                            if cardNumber.hasPrefix("4035") || cardNumber.hasPrefix("4360") {
                                cardNetwork = .cartesBancaires
                                self.logger.debug(message: "Co-badged card detected: Using Cartes Bancaires instead of Visa for card starting with \(String(cardNumber.prefix(4)))")
                            }
                        }
                    }
                    
                    self.logger.debug(message: "Network validation - selectedCardNetwork: \(self.selectedCardNetwork?.displayName ?? "nil"), autoDetected: \(autoDetectedNetwork.displayName), using: \(cardNetwork.displayName)")
                    
                    if !allowedCardNetworks.contains(cardNetwork) {
                        let err = PrimerError.invalidValue(key: "cardNetwork",
                                                           value: cardNetwork.displayName)
                        ErrorHandler.handle(error: err)
                        self.delegate.cardComponentsManager?(self, tokenizationFailedWith: [err])
                        return
                    }
                }

                self.paymentMethodsConfig = PrimerAPIConfigurationModule.apiConfiguration
                let requestBody = Request.Body.Tokenization(paymentInstrument: tokenizationPaymentInstrument)

                firstly {
                    return self.tokenizationService.tokenize(requestBody: requestBody)
                }
                .done { paymentMethodTokenData in
                    self.delegate.cardComponentsManager(self, onTokenizeSuccess: paymentMethodTokenData)
                }
                .catch { err in
                    ErrorHandler.handle(error: PrimerError.underlyingErrors(errors: [err]))
                    self.delegate.cardComponentsManager?(self, tokenizationFailedWith: [err])
                }
            }
            .catch { err in
                self.delegate.cardComponentsManager?(self, tokenizationFailedWith: [err])
                self.setIsLoading(false)
            }
        } catch PrimerError.underlyingErrors(let errors, _) {
            delegate.cardComponentsManager?(self, tokenizationFailedWith: errors)
            setIsLoading(false)
        } catch {
            delegate.cardComponentsManager?(self, tokenizationFailedWith: [error])
            setIsLoading(false)
        }
    }
}

// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable large_tuple
// swiftlint:enable file_length
