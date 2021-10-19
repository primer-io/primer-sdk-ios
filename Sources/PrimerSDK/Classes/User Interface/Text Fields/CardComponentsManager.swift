//
//  CardComponentsManager.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/7/21.
//

import Foundation

@objc
public protocol CardComponentsManagerDelegate {
    /// The cardComponentsManager(_:clientTokenCallback:) can be used to provide the CardComponentsManager with an access token from the merchants backend.
    /// This delegate function is optional since you can initialize the CardComponentsManager with an access token. Still, if the access token is not valid, the CardComponentsManager
    /// will try to acquire an access token through this function.
    @objc optional func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void)
    /// The cardComponentsManager(_:onTokenizeSuccess:) is the only required method, and it will return the payment method token (which
    /// contains all the information needed)
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethod: PaymentMethod)
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
    var paymentMethodsConfig: PrimerConfiguration? { get }
    
    func tokenize()
}

@objc
public class CardComponentsManager: NSObject, CardComponentsManagerProtocol {
    
    public var cardnumberField: PrimerCardNumberFieldView
    public var expiryDateField: PrimerExpiryDateFieldView
    public var cvvField: PrimerCVVFieldView
    public var cardholderField: PrimerCardholderNameFieldView?
    
    private(set) public var flow: PaymentFlow
    public var delegate: CardComponentsManagerDelegate?
    public var customerId: String?
    public var merchantIdentifier: String?
    public var amount: Int?
    public var currency: Currency?
    internal var decodedClientToken: DecodedClientToken? {
        return ClientTokenService.decodedClientToken
    }
    internal var paymentMethodsConfig: PrimerConfiguration?
    private(set) public var isLoading: Bool = false
    internal private(set) var paymentMethod: PaymentMethod?
    
    deinit {
        setIsLoading(false)
    }
    
    /// The CardComponentsManager can be initialized with/out an access token. In the case that is initialized without an access token, the delegate function cardComponentsManager(_:clientTokenCallback:) will be called. You can initialize an instance (representing a session) by providing the flow (checkout or vault) and registering the necessary PrimerTextFieldViews
    public init(clientToken: String? = nil, flow: PaymentFlow, cardnumberField: PrimerCardNumberFieldView, expiryDateField: PrimerExpiryDateFieldView, cvvField: PrimerCVVFieldView, cardholderNameField: PrimerCardholderNameFieldView?) {
        self.flow = flow
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        
        super.init()
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        
        self.cardholderField = cardholderNameField
        
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
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
                seal.reject(PrimerError.delegateNotSet)
                return
            }
            
            delegate.cardComponentsManager?(self, clientTokenCallback: { clientToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let clientToken = clientToken {
                    do {
                        try ClientTokenService.storeClientToken(clientToken)
                        if let decodedClientToken = ClientTokenService.decodedClientToken {
                            seal.fulfill(decodedClientToken)
                        } else {
                            seal.reject(PrimerError.clientTokenNull)
                        }
                        
                    } catch {
                        seal.reject(error)
                    }
                } else {
                    assert(true, "Should always return token or error")
                }
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
                case PrimerError.clientTokenNull,
                     PrimerError.clientTokenExpirationMissing,
                     PrimerError.clientTokenExpired:
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
    
    private func fetchPaymentMethodConfigIfNeeded() -> Promise<PrimerConfiguration> {
        return Promise { seal in
            if let paymentMethodsConfig = paymentMethodsConfig {
                seal.fulfill(paymentMethodsConfig)
            } else {
                guard let decodedClientToken = decodedClientToken else {
                    seal.reject(PrimerError.clientTokenNull)
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
            errors.append(PrimerError.invalidCardnumber)
        }
        
        if expiryDateField.expiryMonth == nil || expiryDateField.expiryYear == nil {
            errors.append(PrimerError.invalidExpiryDate)
        }
        
        if !cvvField.cvv.isValidCVV(cardNetwork: CardNetwork(cardNumber: cardnumberField.cardnumber)) {
            errors.append(PrimerError.invalidCVV)
        }
        
        if let cardholderField  = cardholderField {
            if !cardholderField.cardholderName.isValidCardholderName {
                errors.append(PrimerError.invalidCardholderName)
            }
        }
        
        if !errors.isEmpty {
            throw PrimerError.containerError(errors: errors)
        }
    }
    
    public func tokenize() {
        do {
            setIsLoading(true)
            
            try validateCardComponents()
            
            firstly {
                self.fetchClientTokenIfNeeded()
            }
            .then { decodedClientToken -> Promise<PrimerConfiguration> in
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
                
                let paymentMethodTokenizationRequest = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, paymentFlow: PaymentFlow.vault, customerId: self.customerId)
                
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.tokenizePaymentMethod(clientToken: self.decodedClientToken!, paymentMethodTokenizationRequest: paymentMethodTokenizationRequest) { result in
                    switch result {
                    case .success(let paymentMethod):
                        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                        let state: AppStateProtocol = DependencyContainer.resolve()
                                                
                        var isThreeDSEnabled: Bool = false
                        if state.paymentMethodConfig?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                            isThreeDSEnabled = true
                        }

                        /// 3DS requirements on tokenization are:
                        ///     - The payment method has to be a card
                        ///     - It has to be a vault flow
                        ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                        ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                        if paymentMethod.paymentInstrumentType == .paymentCard,
                           Primer.shared.flow.internalSessionFlow.vaulted,
                           settings.is3DSOnVaultingEnabled,
                           paymentMethod.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess,
                           isThreeDSEnabled {
                            #if canImport(Primer3DS)
                            let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                            DependencyContainer.register(threeDSService)
                            
                            var beginAuthExtraData: ThreeDS.BeginAuthExtraData
                            do {
                                beginAuthExtraData = try ThreeDSService.buildBeginAuthExtraData()
                            } catch {
                                self.paymentMethod = paymentMethod
                                self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethod)
                                return
                            }

                            threeDSService.perform3DS(
                                paymentMethod: paymentMethod,
                                protocolVersion: ClientTokenService.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2,
                                beginAuthExtraData: beginAuthExtraData,
                                    sdkDismissed: { () in

                                    }, completion: { result in
                                        switch result {
                                        case .success(let res):
                                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: res.0)
                                            
                                        case .failure(let err):
                                            // Even if 3DS fails, continue...
                                            log(logLevel: .error, message: "3DS failed with error: \(err as NSError), continue without 3DS")
                                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethod)
                                            
                                        }
                                    })
                            
                            #else
                            print("\nWARNING!\nCannot perform 3DS, Primer3DS SDK is missing. Continue without 3DS\n")
                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethod)
                            #endif
                            
                        } else {
                            self.delegate?.cardComponentsManager(self, onTokenizeSuccess: paymentMethod)
                        }
                
                    case .failure(let err):
                        self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [PrimerError.tokenizationRequestFailed])
                    }
                }
            }
            .catch { err in
                self.delegate?.cardComponentsManager?(self, tokenizationFailedWith: [err])
                self.setIsLoading(false)
            }
        } catch PrimerError.containerError(let errors) {
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
    
    var flow: PaymentFlow
    
    var delegate: CardComponentsManagerDelegate?
    
    var customerId: String?
    
    var merchantIdentifier: String?
    
    var amount: Int?
    
    var currency: Currency?
    
    var decodedClientToken: DecodedClientToken? {
        return ClientTokenService.decodedClientToken
    }
    
    var paymentMethodsConfig: PrimerConfiguration?
    
    public init(clientToken: String? = nil, flow: PaymentFlow, cardnumberField: PrimerCardNumberFieldView, expiryDateField: PrimerExpiryDateFieldView, cvvField: PrimerCVVFieldView, cardholderNameField: PrimerCardholderNameFieldView?) {
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        self.flow = flow
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderNameField
        
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
    }
    
    convenience init(
        clientToken: String,
        cardnumber: String?
    ) {
        let cardnumberFieldView = PrimerCardNumberFieldView()
        cardnumberFieldView.textField._text = cardnumber
        self.init(clientToken: clientToken, flow: .checkout, cardnumberField: cardnumberFieldView, expiryDateField: PrimerExpiryDateFieldView(), cvvField: PrimerCVVFieldView(), cardholderNameField: PrimerCardholderNameFieldView())
        
        try? ClientTokenService.storeClientToken(clientToken)
    }
    
    func tokenize() {
        
    }

}
