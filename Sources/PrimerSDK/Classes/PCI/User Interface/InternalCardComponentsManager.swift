//
//  InternalCardComponentsManager.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/7/21.
//

import UIKit

@objc
internal protocol InternalCardComponentsManagerDelegate {
    /// The cardComponentsManager(_:clientTokenCallback:) can be used to provide the CardComponentsManager with an access token from the merchants backend.
    /// This delegate function is optional since you can initialize the CardComponentsManager with an access token. Still, if the access token is not valid, the CardComponentsManager
    /// will try to acquire an access token through this function.
    @objc optional func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void)
    /// The cardComponentsManager(_:onTokenizeSuccess:) is the only required method, and it will return the payment method token (which
    /// contains all the information needed)
    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, onTokenizeSuccess paymentMethodToken: PrimerPaymentMethodTokenData)
    /// The cardComponentsManager(_:tokenizationFailedWith:) will return any tokenization errors that have occured.
    @objc optional func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, tokenizationFailedWith errors: [Error])
    /// The cardComponentsManager(_:isLoading:) will return true when the CardComponentsManager is performing an async operation and waiting for a result, false
    /// when loading has finished.
    @objc optional func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager, isLoading: Bool)
}

protocol InternalCardComponentsManagerProtocol {
    var cardnumberField: PrimerCardNumberFieldView { get }
    var expiryDateField: PrimerExpiryDateFieldView { get }
    var cvvField: PrimerCVVFieldView { get }
    var cardholderField: PrimerCardholderNameFieldView? { get }
    var delegate: InternalCardComponentsManagerDelegate? { get }
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
internal class InternalCardComponentsManager: NSObject, InternalCardComponentsManagerProtocol, LogReporter {

    var cardnumberField: PrimerCardNumberFieldView
    var expiryDateField: PrimerExpiryDateFieldView
    var cvvField: PrimerCVVFieldView
    var cardholderField: PrimerCardholderNameFieldView?
    var billingAddressFieldViews: [PrimerTextFieldView]?
    var isRequiringCVVInput: Bool
    var paymentMethodType: String
    var delegate: InternalCardComponentsManagerDelegate?
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

    deinit {
        setIsLoading(false)
    }

    /// The CardComponentsManager can be initialized with/out an access token. In the case that is initialized without an access token, the delegate function cardComponentsManager(_:clientTokenCallback:) will be called. You can initialize an instance (representing a session) by registering the necessary PrimerTextFieldViews
    init(
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        billingAddressFieldViews: [PrimerTextFieldView]?,
        paymentMethodType: String? = nil,
        isRequiringCVVInput: Bool = true
    ) {
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderNameField
        self.billingAddressFieldViews = billingAddressFieldViews
        if let paymentMethodType = paymentMethodType, let primerPaymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) {
            self.primerPaymentMethodType = primerPaymentMethodType
            self.paymentMethodType = primerPaymentMethodType.rawValue
        } else {
            self.primerPaymentMethodType = .paymentCard
            self.paymentMethodType = self.primerPaymentMethodType.rawValue
        }
        self.isRequiringCVVInput = isRequiringCVVInput
        super.init()
    }

    internal func setIsLoading(_ isLoading: Bool) {
        if self.isLoading == isLoading { return }
        self.isLoading = isLoading
        delegate?.cardComponentsManager?(self, isLoading: isLoading)
    }

    private func fetchClientToken() -> Promise<DecodedJWTToken> {
        return Promise { seal in
            guard let delegate = delegate else {
                logger.warn(message: "Delegate has not been set for InternalCardComponentsManager")
                let err = PrimerError.missingPrimerDelegate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

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
                        precondition(false, "Decoded client token should never be null at this point.")
                        let err = PrimerError.invalidValue(key: "self.decodedClientToken", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
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
            let err = PrimerValidationError.invalidCardnumber(
                message: "Card number can not be blank.",
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString)
            errors.append(err)

        } else if !cardnumberField.cardnumber.isValidCardNumber {
            let err = PrimerValidationError.invalidCardnumber(
                message: "Card number is not valid.",
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString)
            errors.append(err)
        }

        if expiryDateField.expiryMonth == nil || expiryDateField.expiryYear == nil {
            errors.append(PrimerValidationError.invalidExpiryDate(
                message: "Expiry date is not valid. Valid expiry date format is 2 characters for expiry month and 4 characters for expiry year separated by '/'.",
                userInfo: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ],
                diagnosticsId: UUID().uuidString))
        }

        if isRequiringCVVInput {
            if cvvField.cvv.isEmpty {
                let err = PrimerValidationError.invalidCvv(
                    message: "CVV cannot be blank.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)

            } else if !cvvField.cvv.isValidCVV(cardNetwork: CardNetwork(cardNumber: cardnumberField.cardnumber)) {
                let err = PrimerValidationError.invalidCvv(
                    message: "CVV is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
            }
        }

        billingAddressFieldViews?.filter { $0.isTextValid == false }.forEach {
            if let simpleCardFormTextFieldView = $0 as? PrimerSimpleCardFormTextFieldView,
               let validationError = simpleCardFormTextFieldView.validationError {
                ErrorHandler.handle(error: validationError)
                errors.append(validationError)
            }
        }

        if !errors.isEmpty {
            let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    /// Gets the first two digits of a year component
    /// e.g.
    /// current year = "2022"
    /// first two digits = "20"
    private var cardExpirationYear: String? {
        guard let expiryYear = self.expiryDateField.expiryYear else { return nil }
        let currentYearAsString = Date().yearComponentAsString
        let milleniumAndCenturyOfCurrentYearAsString = currentYearAsString.prefix(upTo: currentYearAsString.index(currentYearAsString.startIndex, offsetBy: 2))
        return "\(milleniumAndCenturyOfCurrentYearAsString)\(expiryYear)"
    }

    private var tokenizationPaymentInstrument: TokenizationRequestBodyPaymentInstrument? {

        guard let cardExpirationYear = cardExpirationYear,
              let expiryMonth = self.expiryDateField.expiryMonth else {
            return nil
        }

        if isRequiringCVVInput {

            let cardPaymentInstrument = CardPaymentInstrument(number: self.cardnumberField.cardnumber,
                                                              cvv: self.cvvField.cvv,
                                                              expirationMonth: expiryMonth,
                                                              expirationYear: cardExpirationYear,
                                                              cardholderName: self.cardholderField?.cardholderName)
            return cardPaymentInstrument

        } else if let configId = AppState.current.apiConfiguration?.getConfigId(for: self.primerPaymentMethodType.rawValue),
                  let cardholderName = self.cardholderField?.cardholderName {

            let cardOffSessionPaymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                                  paymentMethodType: self.primerPaymentMethodType.rawValue,
                                                                                  number: self.cardnumberField.cardnumber,
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
                    let err = PrimerError.invalidValue(key: "Payment Instrument", value: self.tokenizationPaymentInstrument, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                    return
                }

                self.paymentMethodsConfig = PrimerAPIConfigurationModule.apiConfiguration
                let tokenizationService: TokenizationServiceProtocol = TokenizationService()
                let requestBody = Request.Body.Tokenization(paymentInstrument: tokenizationPaymentInstrument)

                firstly {
                    return tokenizationService.tokenize(requestBody: requestBody)
                }
                .done { paymentMethodTokenData in
                    self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethodTokenData)
                }
                .catch { err in
                    let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: containerErr)
                    self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                }
            }
            .catch { err in
                self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                self.setIsLoading(false)
            }
        } catch PrimerError.underlyingErrors(errors: let errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString) {
            delegate?.cardComponentsManager?(self, tokenizationFailedWith: errors)
            setIsLoading(false)
        } catch {
            delegate?.cardComponentsManager?(self, tokenizationFailedWith: [error])
            setIsLoading(false)
        }
    }

}

internal class MockCardComponentsManager: InternalCardComponentsManagerProtocol {

    var cardnumberField: PrimerCardNumberFieldView

    var expiryDateField: PrimerExpiryDateFieldView

    var cvvField: PrimerCVVFieldView

    var cardholderField: PrimerCardholderNameFieldView?

    var postalCodeField: PrimerPostalCodeFieldView?

    var delegate: InternalCardComponentsManagerDelegate?

    var customerId: String?

    var merchantIdentifier: String?

    var amount: Int?

    var currency: Currency?

    var decodedJWTToken: DecodedJWTToken? {
        return PrimerAPIConfigurationModule.decodedJWTToken
    }

    var paymentMethodsConfig: PrimerAPIConfiguration?

    public init(
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        postalCodeField: PrimerPostalCodeFieldView
    ) {
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderNameField
        self.postalCodeField = postalCodeField
    }

    convenience init(
        cardnumber: String?
    ) {
        let cardnumberFieldView = PrimerCardNumberFieldView()
        cardnumberFieldView.textField._text = cardnumber
        self.init(
            cardnumberField: cardnumberFieldView,
            expiryDateField: PrimerExpiryDateFieldView(),
            cvvField: PrimerCVVFieldView(),
            cardholderNameField: PrimerCardholderNameFieldView(),
            postalCodeField: PrimerPostalCodeFieldView()
        )
    }

    func tokenize() {

    }

}
