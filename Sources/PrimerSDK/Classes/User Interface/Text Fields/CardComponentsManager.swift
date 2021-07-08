//
//  CardComponentsManager.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/7/21.
//

import Foundation

public protocol CardComponentsManagerDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<String, Error>) -> Void)
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken)
    func tokenizationFailed(with errors: [Error])
    func isLoading(_ isLoading: Bool)
}

protocol CardComponentsManagerProtocol {
    var cardnumberField: PrimerCardNumberFieldView { get }
    var expiryDateField: PrimerExpiryDateFieldView { get }
    var cvvField: PrimerCVVFieldView { get }
    var cardholderField: PrimerCardholderFieldView? { get }
    var flow: PaymentFlow { get }
    var delegate: CardComponentsManagerDelegate? { get }
    var customerId: String? { get }
    var merchantIdentifier: String? { get }
    var amount: Int? { get }
    var currency: Currency? { get }
    var decodedClientToken: DecodedClientToken? { get }
    var paymentMethodsConfig: PaymentMethodConfig? { get }
    
    func tokenize()
}

public class CardComponentsManager: CardComponentsManagerProtocol {
    
    public var cardnumberField: PrimerCardNumberFieldView
    public var expiryDateField: PrimerExpiryDateFieldView
    public var cvvField: PrimerCVVFieldView
    public var cardholderField: PrimerCardholderFieldView?
    
    private(set) public var flow: PaymentFlow
    public var delegate: CardComponentsManagerDelegate?
    public var customerId: String?
    public var merchantIdentifier: String?
    public var amount: Int?
    public var currency: Currency?
    internal var decodedClientToken: DecodedClientToken?
    internal var paymentMethodsConfig: PaymentMethodConfig?
    private(set) public var isLoading: Bool = false
    
    deinit {
        setIsLoading(false)
    }
    
    public init(accessToken: String? = nil, flow: PaymentFlow, cardnumberField: PrimerCardNumberFieldView, expiryDateField: PrimerExpiryDateFieldView, cvvField: PrimerCVVFieldView, cardholderField: PrimerCardholderFieldView?) {
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        
        self.flow = flow
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderField
        
        if let accessToken = accessToken, let decodedClientToken = accessToken.jwtTokenPayload {
            self.decodedClientToken = decodedClientToken
        }
    }
    
    private func setIsLoading(_ isLoading: Bool) {
        if self.isLoading == isLoading { return }
        self.isLoading = isLoading
        delegate?.isLoading(self.isLoading)
    }
    
    private func fetchAccessToken() -> Promise<DecodedClientToken> {
        return Promise { seal in
            guard let delegate = delegate else {
                print("Warning: Delegate has not been set")
                seal.reject(PrimerError.delegateNotSet)
                return
            }
            
            delegate.clientTokenCallback({ result in
                switch result {
                case .success(let accessToken):
                    if let decodedClientToken = accessToken.jwtTokenPayload {
                        seal.fulfill(decodedClientToken)
                    } else {
                        let err = PrimerError.clientTokenNull
                        seal.reject(err)
                    }
                    
                case .failure(let err):
                    seal.reject(err)
                }
            })
        }
    }
    
    private func fetchAccessTokenIfNeeded() -> Promise<DecodedClientToken> {
        return Promise { seal in
            do {
                if let decodedClientToken = decodedClientToken {
                    try decodedClientToken.validate()
                    seal.fulfill(decodedClientToken)
                } else {
                    firstly {
                        self.fetchAccessToken()
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
                        self.fetchAccessToken()
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
    
    private func fetchPaymentMethodConfigIfNeeded() -> Promise<PaymentMethodConfig> {
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
        
        if !cvvField.cvv.isValidCVV {
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
                self.fetchAccessTokenIfNeeded()
            }
            .then { decodedClientToken -> Promise<PaymentMethodConfig> in
                self.decodedClientToken = decodedClientToken
                return self.fetchPaymentMethodConfigIfNeeded()
            }
            .done { paymentMethodsConfig in
                self.paymentMethodsConfig = paymentMethodsConfig
                
                if self.paymentMethodsConfig?.getConfigId(for: .paymentCard) == nil {
                    throw PrimerError.configFetchFailed
                }
                
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
                    case .success(let paymentMethodToken):
                        self.delegate?.onTokenizeSuccess(paymentMethodToken)
                    case .failure(let err):
                        self.delegate?.tokenizationFailed(with: [PrimerError.tokenizationRequestFailed])
                    }
                    
                    self.setIsLoading(false)
                }
            }
            .catch { err in
                self.delegate?.tokenizationFailed(with: [err])
                self.setIsLoading(false)
            }
        } catch PrimerError.containerError(let errors) {
            delegate?.tokenizationFailed(with: errors)
            setIsLoading(false)
        } catch {
            delegate?.tokenizationFailed(with: [error])
            setIsLoading(false)
        }
    }
    
}
