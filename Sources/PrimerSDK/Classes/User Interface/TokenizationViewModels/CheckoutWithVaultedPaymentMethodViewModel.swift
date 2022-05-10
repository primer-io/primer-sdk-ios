//
//  VaultedPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/5/22.
//

#if canImport(UIKit)

import Foundation

class CheckoutWithVaultedPaymentMethodViewModel {
    
    var config: PaymentMethodConfig
    var selectedPaymentMethodTokenData: PaymentMethodTokenData
    var singleUsePaymentMethodTokenData: PaymentMethodTokenData?
    var paymentCheckoutData: CheckoutData?
    var successMessage: String?
    
    var resumePaymentId: String?
    
    // Events
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    
    init(configuration: PaymentMethodConfig, selectedPaymentMethodTokenData: PaymentMethodTokenData) {
        self.config = configuration
        self.selectedPaymentMethodTokenData = selectedPaymentMethodTokenData
    }
    
    func start() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.startTokenizationFlow()
            }
            .then { paymentMethodTokenData -> Promise<CheckoutData?> in
                self.singleUsePaymentMethodTokenData = paymentMethodTokenData
                return self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { checkoutData in
                if let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
                
                self.handleSuccessfulFlow()
                seal.fulfill()
            }
            .catch { err in
                self.didFinishPayment?(err)
                firstly {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    seal.fulfill()
                }
                .catch { _ in }
            }
        }
    }
    
    func startTokenizationFlow() -> Promise<PaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.dispatchActions(config: self.config, selectedPaymentMethod: self.selectedPaymentMethodTokenData)
            }
            .then { () -> Promise<Void> in
                self.handlePrimerWillCreatePaymentEvent(PaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PaymentMethodToken> in
                self.exchangePaymentMethodToken(self.selectedPaymentMethodTokenData)
            }
            .done { singleUsePaymentMethodTokenData in
                seal.fulfill(singleUsePaymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func dispatchActions(config: PaymentMethodConfig, selectedPaymentMethod: PaymentMethodToken) -> Promise<Void> {
        
        return Promise { seal in
            
            var params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            if config.type == .paymentCard {
                var network = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
                
                params = [
                    "paymentMethodType": "PAYMENT_CARD",
                    "binData": [
                        "network": network,
                    ]
                ]
            }
            
            firstly {
                ClientSession.Action.selectPaymentMethodWithParametersIfNeeded(params)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if Primer.shared.flow.internalSessionFlow.vaulted {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = CheckoutPaymentMethodType(type: paymentMethodData.type.rawValue)
                let checkoutPaymentMethodData = CheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    guard paymentCreationDecision?.type != .abort else {
                        let message = paymentCreationDecision?.additionalInfo?[.message] as? String ?? ""
                        let error = PrimerError.generic(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        seal.reject(error)
                        return
                    }
                    
                    if let modifiedClientToken = paymentCreationDecision?.additionalInfo?[.clientToken] as? RawJWTToken {
                        ClientTokenService.storeClientToken(modifiedClientToken) { error in
                            guard error == nil else {
                                seal.reject(error!)
                                return
                            }
                            seal.fulfill()
                        }
                    } else {
                        seal.fulfill()
                    }
                })
            }
        }
    }
    
    private func exchangePaymentMethodToken(_ paymentMethodToken: PaymentMethodToken) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
            client.exchangePaymentMethodToken(clientToken: decodedClientToken, paymentMethodId: paymentMethodToken.id!) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let singleUsePaymentMethod):
                        seal.fulfill(singleUsePaymentMethod)
                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
        }
    }
    
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PaymentMethodTokenData) -> Promise<CheckoutData?> {
        return Promise { seal in
            firstly {
                self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { decodedClientToken in
                if let decodedClientToken = decodedClientToken {
                    firstly {
                        self.handleDecodedClientTokenIfNeeded(decodedClientToken)
                    }
                    .done { resumeToken in
                        if let resumeToken = resumeToken {
                            firstly {
                                self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                            }
                            .done { checkoutData in
                                seal.fulfill(checkoutData)
                            }
                            .catch { err in
                                seal.reject(err)
                            }
                        } else {
                            seal.fulfill(nil)
                        }
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    seal.fulfill(self.paymentCheckoutData)
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<CheckoutData?> {
        return Promise { seal in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if settings.isManualPaymentHandlingEnabled {
                PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                    switch resumeDecision.type {
                    case .fail(let message):
                        var merchantErr: Error!
                        if let message = message {
                            let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)

                    case .succeed:
                        seal.fulfill(nil)

                    case .handleNewClientToken:
                        seal.fulfill(nil)
                    }
                }
                
            } else {
                guard let resumePaymentId = self.resumePaymentId else {
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: resumePaymentIdError)
                    seal.reject(resumePaymentIdError)
                    return
                }
                
                firstly {
                    self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                }
                .done { paymentResponse -> Void in
                    guard let paymentResponse = paymentResponse else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                    
                    self.paymentCheckoutData = CheckoutData(payment: CheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    
    // Resume payment with Resume payment ID
    
    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Payment.Response?> {
        
        return Promise { seal in
            
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Payment.ResumeRequest(token: resumeToken)) { paymentResponse, error in
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]))
                    return
                }
                
                if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                let paymentErrorCode = PaymentErrorCode(rawValue: paymentFailureReason),
                   let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                    seal.reject(error)
                    return
                }
                                
                seal.fulfill(paymentResponse)
            }
        }
    }
    
    func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PaymentMethodTokenData) -> Promise<DecodedClientToken?> {
        return Promise { seal in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if settings.isManualPaymentHandlingEnabled {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                    switch resumeDecision.type {
                    case .succeed:
                        seal.fulfill(nil)
                        
                    case .handleNewClientToken(let newClientToken):
                        firstly {
                            ClientTokenService.storeClientToken(newClientToken)
                        }
                        .then { () -> Promise<Void> in
                            let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                            return configService.fetchConfig()
                        }
                        .done {
                            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                ErrorHandler.handle(error: err)
                                throw err
                            }
                            
                            seal.fulfill(decodedClientToken)
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                        
                    case .fail(let message):
                        var merchantErr: Error!
                        if let message = message {
                            let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)
                    }
                }

            } else {
                guard let paymentMethodTokenString = paymentMethodTokenData.token else {
                    let paymentMethodTokenError = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: paymentMethodTokenError)
                    throw paymentMethodTokenError
                }
                
                firstly {
                    self.handleCreatePaymentEvent(paymentMethodTokenString)
                }
                .done { paymentResponse -> Void in
                    guard paymentResponse != nil else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        throw err
                    }

                    self.paymentCheckoutData = CheckoutData(payment: CheckoutDataPayment(from: paymentResponse!))
                    self.resumePaymentId = paymentResponse!.id
                    
                    if let requiredAction = paymentResponse!.requiredAction {
                        firstly {
                            ClientTokenService.storeClientToken(requiredAction.clientToken)
                        }
                        .done { checkoutData in
                            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                ErrorHandler.handle(error: err)
                                throw err
                            }
                            
                            seal.fulfill(decodedClientToken)
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                        
                    } else {
                        seal.fulfill(nil)
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    
    private func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
        return Promise { seal in
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
    #if canImport(Primer3DS)
                guard let paymentMethodTokenData = singleUsePaymentMethodTokenData else {
                    let err = ParserError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                    return
                }
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethodTokenData, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        DispatchQueue.main.async {
                            guard let threeDSPostAuthResponse = paymentMethodToken.1,
                                  let resumeToken = threeDSPostAuthResponse.resumeToken else {
                                let decoderError = ParserError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                let err = PrimerError.failedToPerform3DS(error: decoderError, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                ErrorHandler.handle(error: err)
                                seal.reject(err)
                                return
                            }
                            
                            seal.fulfill(resumeToken)
                        }
                        
                    case .failure(let err):
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                    }
                }
    #else
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
    #endif
                
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Payment.Response?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.createPayment(paymentRequest: Payment.CreateRequest(token: paymentMethodData)) { paymentResponse, error in
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]))
                    return
                }
                
                if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                let paymentErrorCode = PaymentErrorCode(rawValue: paymentFailureReason),
                   let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                    seal.reject(error)
                    return
                }
                                
                seal.fulfill(paymentResponse)
            }
        }
    }
    
    func handleSuccessfulFlow() {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .success)
    }
    
    func handleFailureFlow(errorMessage: String?) {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
}

#endif
