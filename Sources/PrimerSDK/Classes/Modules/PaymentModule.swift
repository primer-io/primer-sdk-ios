//
//  PaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 22/7/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentModuleProtocol {
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol { get }
    
    init(paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol)
    func pay(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?>
}

class PaymentModule: PaymentModuleProtocol {
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol
    var paymentCheckoutData: PrimerCheckoutData!
    var resumePaymentId: String!
    
    required init(paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol) {
        self.paymentMethodTokenizationViewModel = paymentMethodTokenizationViewModel
    }
    
    func pay(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            guard let paymentMethodToken = paymentMethodTokenData.token else {
                let err = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if PrimerSettings.current.paymentHandling == .manual {
                firstly {
                    self.payWithManualFlow(with: paymentMethodTokenData)
                }
                .done {
                    seal.fulfill(nil)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                firstly {
                    self.payWithAutoFlow(with: paymentMethodToken)
                }
                .done { checkoutData in
                    seal.fulfill(checkoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    
    private func payWithManualFlow(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                switch resumeDecision.type {
                case .succeed:
                    seal.fulfill()
                    
                case .continueWithNewClientToken(let newClientToken):
                    firstly {
                        ClientTokenService.storeClientToken(newClientToken)
                    }
                    .then { () -> Promise<Void> in
                        let configurationService: PrimerAPIConfigurationServiceProtocol = PrimerAPIConfigurationService(requestDisplayMetadata: true)
                        return configurationService.fetchConfiguration()
                    }
                    .then { () -> Promise<String?> in
                        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            throw err
                        }
                        
                        return self.paymentMethodTokenizationViewModel.handleDecodedClientTokenIfNeeded(decodedClientToken)
                    }
                    .done { resumeToken in
                        if let resumeToken = resumeToken {
                            PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                                switch resumeDecision.type {
                                case .fail(let message):
                                    var merchantErr: Error!
                                    if let message = message {
                                        let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                        merchantErr = err
                                    } else {
                                        merchantErr = NSError.emptyDescriptionError
                                    }
                                    seal.reject(merchantErr)

                                case .succeed:
                                    seal.fulfill()

                                case .continueWithNewClientToken:
                                    seal.fulfill()
                                }
                            }
                        } else {
                            seal.fulfill()
                        }
                        
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                    
                case .fail(let message):
                    var merchantErr: Error!
                    if let message = message {
                        let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        merchantErr = err
                    } else {
                        merchantErr = NSError.emptyDescriptionError
                    }
                    seal.reject(merchantErr)
                }
            }
        }
    }
    
    private func payWithAutoFlow(with paymentMethodToken: String) -> Promise<PrimerCheckoutData> {
        return Promise { seal in
            firstly {
                self.createPayment(with: paymentMethodToken)
            }
            .done { paymentResponse -> Void in
                self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                self.resumePaymentId = paymentResponse.id
                
                if let requiredAction = paymentResponse.requiredAction {
                    guard let resumePaymentId = self.resumePaymentId else {
                        let err = InternalError.invalidValue(key: "payment.id", value: nil, userInfo: nil, diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    firstly {
                        ClientTokenService.storeClientToken(requiredAction.clientToken)
                    }
                    .then { () -> Promise<String?> in
                        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            throw err
                        }
                        
                        return self.paymentMethodTokenizationViewModel.handleDecodedClientTokenIfNeeded(decodedClientToken)
                    }
                    .done { resumeToken in
                        if let resumeToken = resumeToken {
                            firstly {
                                self.resumePayment(resumePaymentId, withResumeToken: resumeToken)
                            }
                            .done { resumePaymentResponse in
                                self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                                seal.fulfill(self.paymentCheckoutData)
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
                    
                } else {
                    seal.fulfill(self.paymentCheckoutData)
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func exchangePaymentMethodTokenIfNeeded(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            if paymentMethodTokenData.tokenType == .singleUse {
                seal.fulfill(paymentMethodTokenData)
                return
            }
            
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
            client.exchangePaymentMethodToken(clientToken: decodedClientToken, paymentMethodId: paymentMethodTokenData.id!) { result in
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
        
    private func createPayment(with paymentMethodToken: String) -> Promise<Payment.Response> {
        return Promise { seal in
            guard let clientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let api: PrimerAPIClientProtocol = PrimerAPIClient()
            api.createPayment(clientToken: clientToken, paymentRequestBody: Payment.CreateRequest(token: paymentMethodToken)) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let paymentResponse):
                    guard paymentResponse.status != .failed else {
                        let err = PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    if let paymentFailureReason = paymentResponse.paymentFailureReason,
                       let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                       let err = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    seal.fulfill(paymentResponse)
                }
            }
        }
    }
    
    private func resumePayment(_ resumePaymentId: String, withResumeToken resumeToken: String) -> Promise<Payment.Response> {
        return Promise { seal in
            guard let clientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let api: PrimerAPIClientProtocol = PrimerAPIClient()
            api.resumePayment(clientToken: clientToken, paymentId: resumePaymentId, paymentResumeRequest: Payment.ResumeRequest(token: resumeToken)) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let resumePaymentResponse):
                    guard resumePaymentResponse.status != .failed else {
                        let err = PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    if let paymentFailureReason = resumePaymentResponse.paymentFailureReason,
                       let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                       let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                        seal.reject(error)
                        return
                    }
                    
                    seal.fulfill(resumePaymentResponse)
                }
            }
        }
    }
}

#endif
