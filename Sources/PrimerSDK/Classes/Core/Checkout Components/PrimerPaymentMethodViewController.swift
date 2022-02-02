//
//  PrimerPaymentMethodViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//


#if canImport(UIKit)

import UIKit

extension PrimerCheckoutComponents {
    open class PaymentMethodViewController: UIViewController, PrimerPaymentMethodViewControllerProtocol {
        
        open var paymentMethodType: PaymentMethodConfigType!
        open var delegate: PrimerCheckoutComponentsDelegate!
        open var resumeHandler: ResumeHandlerProtocol?
        open var inputElements: [PrimerInputElement] = []
        open var paymentButton: UIButton! {
            didSet {
                self.paymentButton.addTarget(self, action: #selector(startTokenization), for: .touchUpInside)
            }
        }
        open var clientToken: String?
        private let appState: AppStateProtocol = DependencyContainer.resolve()
        
        public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
            self.initialize()
        }
        
        required public init?(coder: NSCoder) {
            super.init(coder: coder)
            self.initialize()
        }
        
        private func initialize() {
            let appState: AppStateProtocol = DependencyContainer.resolve()
            self.clientToken = appState.clientToken
        }
        
        open override func viewDidLoad() {
            super.viewDidLoad()
        }
        
        public func listInputElementTypes() -> [PrimerInputElementType] {
            if paymentMethodType == nil { return [] }
            return PrimerCheckoutComponents.listInputElementTypes(for: paymentMethodType!)
        }
        
        internal func validateUI() -> Promise<Void> {
            return Promise { seal in
                switch self.paymentMethodType {
                case .paymentCard:
                    guard let _ = inputElements.filter({ $0.type == .cardNumber }).first as? PrimerCheckoutComponents.TextField,
                          let _ = inputElements.filter({ $0.type == .expiryDate }).first as? PrimerCheckoutComponents.TextField,
                          let _ = inputElements.filter({ $0.type == .cvv }).first as? PrimerCheckoutComponents.TextField
                    else {
                        seal.reject(PrimerError.generic(message: "", userInfo: nil))
                        return
                    }
                    
                    seal.fulfill()
                    
                default:
                    seal.fulfill()
                }
            }
        }
        
        internal func setClientToken() -> Promise<Void> {
            return Promise { seal in
                guard let clienToken = self.clientToken else {
                    seal.reject(PrimerError.invalidClientToken(userInfo: nil))
                    return
                }
                
                do {
                    try ClientTokenService.storeClientToken(clienToken)
                    seal.fulfill()
                } catch {
                    seal.reject(error)
                }
            }
        }
        
        internal func buildRequestBody() -> Promise<PaymentMethodTokenizationRequest> {
            return Promise { seal in
                do {
                    switch self.paymentMethodType {
                    case .paymentCard:
                        guard let cardnumberField = inputElements.filter({ $0.type == .cardNumber }).first as? PrimerCheckoutComponents.TextField,
                              let expiryDateField = inputElements.filter({ $0.type == .expiryDate }).first as? PrimerCheckoutComponents.TextField,
                              let cvvField = inputElements.filter({ $0.type == .cvv }).first as? PrimerCheckoutComponents.TextField
                        else {
                            seal.reject(PrimerError.generic(message: "", userInfo: nil))
                            return
                        }
                        
                        guard cardnumberField.isValid,
                              expiryDateField.isValid,
                              cvvField.isValid
                        else {
                            seal.reject(PrimerError.generic(message: "", userInfo: nil))
                            return
                        }
                        
                        guard let cardNumber = cardnumberField._text,
                              let expiryDate = expiryDateField._text,
                              let cvv = cvvField._text
                        else {
                            seal.reject(PrimerError.generic(message: "", userInfo: nil))
                            return
                        }
                        
                        let expiryArr = expiryDate.components(separatedBy: expiryDateField.type.delimiter!)
                        let expiryMonth = expiryArr[0]
                        let expiryYear = "20" + expiryArr[1]
                        
                        var cardholderName: String?
                        if let cardholderNameField = inputElements.filter({ $0.type == .cardholderName }).first as? PrimerCheckoutComponents.TextField {
                            if !cardholderNameField.isValid {
                                seal.reject(PrimerError.generic(message: "", userInfo: nil))
                                return
                            }
                            
                            cardholderName = cardholderNameField._text
                        }
                        
                        let paymentInstrument = PaymentInstrument(
                            number: PrimerInputElementType.cardNumber.clearFormatting(value: cardNumber) as! String,
                            cvv: cvv,
                            expirationMonth: expiryMonth,
                            expirationYear: expiryYear,
                            cardholderName: cardholderName,
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
                        
                        let primerSettings: PrimerSettingsProtocol = DependencyContainer.resolve()
                        let customerId = primerSettings.customerId
                        let request = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, paymentFlow: nil, customerId: nil)
                        seal.fulfill(request)
                        
                    default:
                        fatalError()
                    }
                } catch {
                    seal.reject(error)
                }
            }
        }
        
        internal func tokenize(request: PaymentMethodTokenizationRequest) -> Promise<PaymentMethodToken> {
            return Promise { seal in
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.tokenizePaymentMethod(clientToken: ClientTokenService.decodedClientToken!, paymentMethodTokenizationRequest: request) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

                        var isThreeDSEnabled: Bool = false
                        if self.appState.primerConfiguration?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                            isThreeDSEnabled = true
                        }

                        /// 3DS requirements on tokenization are:
                        ///     - The payment method has to be a card
                        ///     - It has to be a vault flow
                        ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                        ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                        if paymentMethodToken.paymentInstrumentType == .paymentCard,
                           settings.is3DSOnVaultingEnabled,
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
                                seal.fulfill(paymentMethodToken)
                                return
                            }

                            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                ErrorHandler.handle(error: err)
                                seal.reject(err)
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
                            seal.fulfill(paymentMethodToken)
                            #endif

                        } else {
                            seal.fulfill(paymentMethodToken)
                        }

                    case .failure(let err):
                        let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(err)
                    }
                }
            }
        }
        
        @objc
        private func startTokenization() {
            self.delegate.onEvent(.tokenizationStarted)

            firstly {
                self.validateUI()
            }
            .then { () -> Promise<Void> in
                return self.setClientToken()
            }
            .then { () -> Promise<Void> in
                let primerConfigurationService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                return primerConfigurationService.fetchConfig()
            }
            .then { () -> Promise<PaymentMethodTokenizationRequest> in
                return self.buildRequestBody()
            }
            .then { requestbody -> Promise<PaymentMethodToken> in
                return self.tokenize(request: requestbody)
            }
            .done { paymentMethodToken in
                self.delegate.onEvent(.tokenizationSuccess(paymentMethodToken: paymentMethodToken, resumeHandler: self.resumeHandler))
            }
            .catch { err in
                self.delegate.onEvent(.error(err: err))
            }
        }
    }
    
}

#endif
