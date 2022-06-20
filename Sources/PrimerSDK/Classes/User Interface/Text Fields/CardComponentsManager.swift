//
//  CardComponentsManager.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/7/21.
//

#if canImport(UIKit)

import Foundation

@objc
public protocol CardComponentsManagerDelegate {
    /// The cardComponentsManager(_:clientTokenCallback:) can be used to provide the CardComponentsManager with an access token from the merchants backend.
    /// This delegate function is optional since you can initialize the CardComponentsManager with an access token. Still, if the access token is not valid, the CardComponentsManager
    /// will try to acquire an access token through this function.
    @objc optional func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void)
    /// The cardComponentsManager(_:onTokenizeSuccess:) is the only required method, and it will return the payment method token (which
    /// contains all the information needed)
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken)
    /// The cardComponentsManager(_:tokenizationFailedWith:) will return any tokenization errors that have occured.
    @objc optional func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error])
    /// The cardComponentsManager(_:isLoading:) will return true when the CardComponentsManager is performing an async operation and waiting for a result, false
    /// when loading has finished.
    @objc optional func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool)
}

protocol CardComponentsManagerProtocol {
    var cardnumberField: PrimerCardNumberFieldView { get }
    var expiryDateField: PrimerExpiryDateFieldView { get }
    var cvvField: PrimerCVVFieldView { get }
    var cardholderField: PrimerCardholderNameFieldView? { get }
    var flow: PaymentFlow { get }
    var delegate: CardComponentsManagerDelegate? { get }
    var customerId: String? { get }
    var merchantIdentifier: String? { get }
    var amount: Int? { get }
    var currency: Currency? { get }
    var decodedClientToken: DecodedClientToken? { get }
    var paymentMethodsConfig: PrimerAPIConfiguration? { get }
    
    func tokenize()
}

@objc
public class CardComponentsManager: NSObject, CardComponentsManagerProtocol {
    
    public var cardnumberField: PrimerCardNumberFieldView
    public var expiryDateField: PrimerExpiryDateFieldView
    public var cvvField: PrimerCVVFieldView
    public var cardholderField: PrimerCardholderNameFieldView?
    public var postalCodeField: PrimerPostalCodeFieldView?
    
    private(set) public var flow: PaymentFlow
    public var delegate: CardComponentsManagerDelegate?
    public var customerId: String?
    public var merchantIdentifier: String?
    public var amount: Int?
    public var currency: Currency?
    internal var decodedClientToken: DecodedClientToken? {
        return ClientTokenService.decodedClientToken
    }
    internal var paymentMethodsConfig: PrimerAPIConfiguration?
    private(set) public var isLoading: Bool = false
    internal private(set) var paymentMethod: PaymentMethodToken?
    
    deinit {
        setIsLoading(false)
    }
    
    /// The CardComponentsManager can be initialized with/out an access token. In the case that is initialized without an access token, the delegate function cardComponentsManager(_:clientTokenCallback:) will be called. You can initialize an instance (representing a session) by providing the flow (checkout or vault) and registering the necessary PrimerTextFieldViews
    public init(
        flow: PaymentFlow,
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        postalCodeField: PrimerPostalCodeFieldView?
    ) {
        self.flow = flow
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.postalCodeField = postalCodeField
        
        super.init()
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        
        self.cardholderField = cardholderNameField
    }
    
    internal func setIsLoading(_ isLoading: Bool) {
        if self.isLoading == isLoading { return }
        self.isLoading = isLoading
        delegate?.cardComponentsManager?(self, isLoading: isLoading)
    }
    
    private func fetchClientToken() -> Promise<DecodedClientToken> {
        return Promise { seal in
            
            guard let delegate = delegate else {
                print("Warning: Delegate has not been set")
                let err = PrimerError.missingPrimerDelegate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            delegate.cardComponentsManager?(self, clientTokenCallback: { clientToken, error in
                                
                guard error == nil, let clientToken = clientToken else {
                    seal.reject(error!)
                    return
                }
                
                ClientTokenService.storeClientToken(clientToken, completion: { error in
                    
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }

                    if let decodedClientToken = self.decodedClientToken {
                        seal.fulfill(decodedClientToken)
                    }
                })
            })
        }
    }
    
    private func fetchClientTokenIfNeeded() -> Promise<DecodedClientToken> {
        return Promise { seal in
            do {
                if let decodedClientToken = decodedClientToken {
                    try decodedClientToken.validate()
                    seal.fulfill(decodedClientToken)
                } else {
                    firstly {
                        self.fetchClientToken()
                    }
                    .done { decodedClientToken in
                        seal.fulfill(decodedClientToken)
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
                    .done { decodedClientToken in
                        seal.fulfill(decodedClientToken)
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
    
    private func fetchPaymentMethodConfigIfNeeded() -> Promise<PrimerAPIConfiguration> {
        return Promise { seal in
            if let paymentMethodsConfig = paymentMethodsConfig {
                seal.fulfill(paymentMethodsConfig)
            } else {
                guard let decodedClientToken = decodedClientToken else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                do {
                    try decodedClientToken.validate()
                } catch {
                    seal.reject(error)
                    return
                }
                
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.fetchConfiguration(clientToken: decodedClientToken) { result in
                    switch result {
                    case .success(let paymentMethodsConfig):
                        seal.fulfill(paymentMethodsConfig)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
    }
    
    private func validateCardComponents() throws {
        var errors: [Error] = []
        if !cardnumberField.cardnumber.isValidCardNumber {
            errors.append(PrimerValidationError.invalidCardnumber(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
        }
        
        if expiryDateField.expiryMonth == nil || expiryDateField.expiryYear == nil {
            errors.append(PrimerValidationError.invalidExpiryDate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
        }
        
        if !cvvField.cvv.isValidCVV(cardNetwork: CardNetwork(cardNumber: cardnumberField.cardnumber)) {
            errors.append(PrimerValidationError.invalidCvv(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
        }
        
        if let cardholderField  = cardholderField {
            if !cardholderField.cardholderName.isValidCardholderName {
                errors.append(PrimerValidationError.invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
            }
        }
        
        if let postalCodeField = postalCodeField {
            if !postalCodeField.postalCode.isValidPostalCode {
                let err = PrimerValidationError.invalidPostalCode(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                errors.append(err)
            }
        }
        
        if !errors.isEmpty {
            let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    public func tokenize() {
        do {
            setIsLoading(true)
            
            try validateCardComponents()
            
            firstly {
                self.fetchClientTokenIfNeeded()
            }
            .then { decodedClientToken -> Promise<PrimerAPIConfiguration> in
                return self.fetchPaymentMethodConfigIfNeeded()
            }
            .done { paymentMethodsConfig in
                self.paymentMethodsConfig = paymentMethodsConfig
                
                let paymentInstrument = PaymentInstrument(
                    number: self.cardnumberField.cardnumber,
                    cvv: self.cvvField.cvv,
                    expirationMonth: self.expiryDateField.expiryMonth!,
                    expirationYear: "20" + self.expiryDateField.expiryYear!,
                    cardholderName: self.cardholderField?.cardholderName,
                    paypalOrderId: nil,
                    paypalBillingAgreementId: nil,
                    shippingAddress: nil,
                    externalPayerInfo: nil,
                    paymentMethodConfigId: nil,
                    token: nil,
                    sourceConfig: nil,
                    gocardlessMandateId: nil,
                    klarnaAuthorizationToken: nil,
                    klarnaCustomerToken: nil,
                    sessionData: nil)
                
                let paymentMethodTokenizationRequest = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, paymentFlow: Primer.shared.intent == .vault ? .vault : .checkout)
                
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.tokenizePaymentMethod(clientToken: self.decodedClientToken!, paymentMethodTokenizationRequest: paymentMethodTokenizationRequest) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                                                
                        var isThreeDSEnabled: Bool = false
                        if AppState.current.apiConfiguration?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                            isThreeDSEnabled = true
                        }

                        /// 3DS requirements on tokenization are:
                        ///     - The payment method has to be a card
                        ///     - It has to be a vault flow
                        ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                        ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                        if paymentMethodToken.paymentInstrumentType == .paymentCard,
                           Primer.shared.intent == .vault,
                           PrimerSettings.current.paymentMethodOptions.cardPaymentOptions.is3DSOnVaultingEnabled,
                           paymentMethodToken.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess,
                           isThreeDSEnabled {
                            #if canImport(Primer3DS)
                            let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                            DependencyContainer.register(threeDSService)
                            
                            var beginAuthExtraData: ThreeDS.BeginAuthExtraData
                            do {
                                beginAuthExtraData = try ThreeDSService.buildBeginAuthExtraData()
                            } catch {
                                self.paymentMethod = paymentMethodToken
                                self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethodToken)
                                return
                            }
                            
                            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                ErrorHandler.handle(error: err)
                                self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                                return
                            }

                            threeDSService.perform3DS(
                                    paymentMethodToken: paymentMethodToken,
                                protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2,
                                beginAuthExtraData: beginAuthExtraData,
                                    sdkDismissed: { () in

                                    }, completion: { result in
                                        switch result {
                                        case .success(let res):
                                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: res.0)
                                            
                                        case .failure(let err):
                                            // Even if 3DS fails, continue...
                                            log(logLevel: .error, message: "3DS failed with error: \(err as NSError), continue without 3DS")
                                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethodToken)
                                            
                                        }
                                    })
                            
                            #else
                            print("\nWARNING!\nCannot perform 3DS, Primer3DS SDK is missing. Continue without 3DS\n")
                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethodToken)
                            #endif
                            
                        } else {
                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethodToken)
                        }
                
                    case .failure(let err):
                        let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                    }
                }
            }
            .catch { err in
                self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                self.setIsLoading(false)
            }
        } catch PrimerError.underlyingErrors(errors: let errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil) {
            delegate?.cardComponentsManager?(self, tokenizationFailedWith: errors)
            setIsLoading(false)
        } catch {
            delegate?.cardComponentsManager?(self, tokenizationFailedWith: [error])
            setIsLoading(false)
        }
    }
    
}


internal class MockCardComponentsManager: CardComponentsManagerProtocol {
    
    var cardnumberField: PrimerCardNumberFieldView
    
    var expiryDateField: PrimerExpiryDateFieldView
    
    var cvvField: PrimerCVVFieldView
    
    var cardholderField: PrimerCardholderNameFieldView?
    
    var postalCodeField: PrimerPostalCodeFieldView?
    
    var flow: PaymentFlow
    
    var delegate: CardComponentsManagerDelegate?
    
    var customerId: String?
    
    var merchantIdentifier: String?
    
    var amount: Int?
    
    var currency: Currency?
    
    var decodedClientToken: DecodedClientToken? {
        return ClientTokenService.decodedClientToken
    }
    
    var paymentMethodsConfig: PrimerAPIConfiguration?
    
    public init(
        flow: PaymentFlow,
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        postalCodeField: PrimerPostalCodeFieldView
    ) {
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        self.flow = flow
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
            flow: .checkout,
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

#endif
