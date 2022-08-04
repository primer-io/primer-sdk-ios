//
//  PaymentMethodTokenizationViewModel+Logic.swift
//  PrimerSDK
//
//  Created by Evangelos on 6/5/22.
//

#if canImport(UIKit)

import Foundation
import UIKit

extension PaymentMethodTokenizationViewModel {
        
    @objc
    func start() {
        firstly {
            self.startTokenizationFlow()
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData

            if Primer.shared.intent == .vault {
                self.handleSuccessfulFlow()
            } else {
                self.didStartPayment?()
                self.didStartPayment = nil
                
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
                
                firstly {
                    self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
                }
                .done { checkoutData in
                    
                    self.didFinishPayment?(nil)
                    self.nullifyEventCallbacks()
                    
                    if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                    }
                    
                    self.handleSuccessfulFlow()
                }
                .ensure {
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
                .catch { err in
                    
                    var error: Error?
                    
                    if let primerErr = err as? PrimerError {
                        error = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: primerErr.errorUserInfo as? [String: String], diagnosticsId: primerErr.diagnosticsId)
                    }
                    
                    self.didFinishPayment?(error)
                    self.nullifyEventCallbacks()
                    
                    let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                    
                    if let primerErr = error as? PrimerError,
                       case .cancelled = primerErr,
                       PrimerHeadlessUniversalCheckout.current.delegate == nil {
                        
                        firstly {
                            clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        }
                        .done { merchantErrorMessage in
                            Primer.shared.primerRootVC?.popToMainScreen(completion: nil)
                        }
                        // The above promises will never end up on error.
                        .catch { _ in }
                        
                    } else {
                        firstly {
                            clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        }
                        .then { () -> Promise<String?> in
                            var primerErr: PrimerError!
                            if let error = err as? PrimerError {
                                primerErr = error
                            } else {
                                primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: nil)
                            }
                            
                            return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                        }
                        .done { merchantErrorMessage in
                            self.handleFailureFlow(errorMessage: merchantErrorMessage)
                        }
                        // The above promises will never end up on error.
                        .catch { _ in }
                    }
                }
            }
        }
        .ensure {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        .catch { err in
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            if let primerErr = err as? PrimerError,
               case .cancelled = primerErr,
               self.config.type == PrimerPaymentMethodType.applePay.rawValue,
               PrimerHeadlessUniversalCheckout.current.delegate == nil
            {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done { merchantErrorMessage in
                    Primer.shared.primerRootVC?.popToMainScreen(completion: nil)
                }
                // The above promises will never end up on error.
                .catch { _ in }
                
            } else {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .then { () -> Promise<String?> in
                    var primerErr: PrimerError!
                    if let error = err as? PrimerError {
                        primerErr = error
                    } else {
                        primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: nil)
                    }
                    
                    return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                }
                // The above promises will never end up on error.
                .catch { _ in }
            }
        }
    }
    
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
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
    
    // This function will do one of the two following:
    //     - Wait a response from the merchant, via the delegate function. The response can be:
    //         - A new client token
    //         - Success
    //         - Error
    //     - Perform the payment internally, and get a response from our BE. The response will
    //       be a Payment response. The can contain:
    //         - A required action with a new client token
    //         - Be successful
    //         - Has failed
    //
    // Therefore, return:
    //     - A decoded client token
    //     - nil for success
    //     - Reject with an error
    
    func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedClientToken?> {
        return Promise { seal in
            if PrimerSettings.current.paymentHandling == .manual {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                    switch resumeDecision.type {
                    case .succeed:
                        seal.fulfill(nil)
                        
                    case .continueWithNewClientToken(let newClientToken):
                        firstly {
                            ClientTokenService.storeClientToken(newClientToken)
                        }
                        .then { () -> Promise<Void> in
                            let configurationService: PrimerAPIConfigurationServiceProtocol = PrimerAPIConfigurationService(requestDisplayMetadata: true)
                            return configurationService.fetchConfiguration()
                        }
                        .done {
                            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                            let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)
                    }
                }

            } else {
                guard let paymentMethodTokenString = paymentMethodTokenData.token else {
                    let paymentMethodTokenError = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: paymentMethodTokenError)
                    throw paymentMethodTokenError
                }
                
                firstly {
                    self.handleCreatePaymentEvent(paymentMethodTokenString)
                }
                .done { paymentResponse -> Void in
                    guard paymentResponse != nil else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        throw err
                    }

                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse!))
                    self.resumePaymentId = paymentResponse!.id
                    
                    if let requiredAction = paymentResponse!.requiredAction {
                        firstly {
                            ClientTokenService.storeClientToken(requiredAction.clientToken)
                        }
                        .done { checkoutData in
                            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
    
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in            
            if PrimerSettings.current.paymentHandling == .manual {
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
                        seal.fulfill(nil)

                    case .continueWithNewClientToken:
                        seal.fulfill(nil)
                    }
                }
                
            } else {
                guard let resumePaymentId = self.resumePaymentId else {
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: resumePaymentIdError)
                    seal.reject(resumePaymentIdError)
                    return
                }
                
                firstly {
                    self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                }
                .done { paymentResponse -> Void in
                    guard let paymentResponse = paymentResponse else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                    
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    
    func handleSuccessfulFlow() {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .success, withMessage: self.successMessage)
    }
    
    func handleFailureFlow(errorMessage: String?) {
        Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
        
    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if Primer.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        seal.reject(error)
                    case .continue:
                        seal.fulfill()
                    }
                })
            }
        }
    }

    // Create payment with Payment method token

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Payment.Response?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.createPayment(paymentRequest: Payment.CreateRequest(token: paymentMethodData)) { paymentResponse, error in
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                    return
                }
                
                if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                   let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                    seal.reject(error)
                    return
                }
                                
                seal.fulfill(paymentResponse)
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
                    seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                    return
                }
                
                if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                   let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                    seal.reject(error)
                    return
                }
                                
                seal.fulfill(paymentResponse)
            }
        }
    }
    
    func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            do {
                try self.validate()
                seal.fulfill()
            } catch {
                seal.reject(error)
            }
        }
    }
    
    func nullifyEventCallbacks() {
        self.didStartPayment = nil
        self.didFinishPayment = nil
    }
}

#endif
