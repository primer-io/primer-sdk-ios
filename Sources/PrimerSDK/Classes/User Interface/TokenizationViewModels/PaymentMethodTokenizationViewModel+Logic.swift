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

            if PrimerInternal.shared.intent == .vault {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { _ in }
                self.handleSuccessfulFlow()
                
            } else {
                self.didStartPayment?()
                self.didStartPayment = nil
                
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
                
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
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }
                .catch { err in
                    self.didFinishPayment?(err)
                    self.nullifyEventCallbacks()
                    
                    let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                    
                    if let primerErr = err as? PrimerError,
                       case .cancelled = primerErr
                    {
                        if PrimerHeadlessUniversalCheckout.current.delegate != nil {
                            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: primerErr, checkoutData: self.paymentCheckoutData)
                        }
                        
                        firstly {
                            clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        }
                        .done { merchantErrorMessage in
                            if PrimerHeadlessUniversalCheckout.current.delegate == nil {
                                if PrimerInternal.shared.selectedPaymentMethodType == nil {
                                    PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
                                } else {
                                    PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
                                }
                            }
                            
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
                                primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: UUID().uuidString)
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
            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
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
                    PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
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
                        primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: UUID().uuidString)
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
            var cancelledError: PrimerError?
            self.didCancel = {
                self.isCancelled = true
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: cancelledError!)
                seal.reject(cancelledError!)
            }
            
            firstly { () -> Promise<DecodedJWTToken?> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { decodedJWTToken in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                
                if let decodedJWTToken = decodedJWTToken {
                    firstly { () -> Promise<String?> in
                        if let cancelledError = cancelledError {
                            throw cancelledError
                        }
                        return self.handleDecodedClientTokenIfNeeded(decodedJWTToken)
                    }
                    .done { resumeToken in
                        if let cancelledError = cancelledError {
                            throw cancelledError
                        }
                        
                        if let resumeToken = resumeToken {
                            firstly { () -> Promise<PrimerCheckoutData?> in
                                if let cancelledError = cancelledError {
                                    throw cancelledError
                                }
                                return self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                            }
                            .done { checkoutData in
                                if let cancelledError = cancelledError {
                                    throw cancelledError
                                }
                                seal.fulfill(checkoutData)
                            }
                            .catch { err in
                                if cancelledError == nil {
                                    seal.reject(err)
                                }
                            }
                        } else if let checkoutData = self.paymentCheckoutData {
                            seal.fulfill(checkoutData)
                        } else {
                            seal.fulfill(nil)
                        }
                    }
                    .catch { err in
                        if cancelledError == nil {
                            seal.reject(err)
                        }
                    }
                } else {
                    seal.fulfill(self.paymentCheckoutData)
                }
            }
            .catch { err in
                if cancelledError == nil {
                    seal.reject(err)
                }
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
    
    func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?> {
        return Promise { seal in
            if PrimerSettings.current.paymentHandling == .manual {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                    if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .succeed:
                            seal.fulfill(nil)
                            
                        case .continueWithNewClientToken(let newClientToken):
                            let apiConfigurationModule = PrimerAPIConfigurationModule()
                        
                        firstly {
                            apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                        }
                        .done {
                            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                throw err
                            }
                            
                            seal.fulfill(decodedJWTToken)
                        }
                            .catch { err in
                                seal.reject(err)
                            }
                            
                        case .fail(let message):
                            var merchantErr: Error!
                            if let message = message {
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                merchantErr = err
                            } else {
                                merchantErr = NSError.emptyDescriptionError
                            }
                            seal.reject(merchantErr)
                        }
                        
                    } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .continueWithNewClientToken(let newClientToken):
                            let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
                            
                            firstly {
                                apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                            }
                            .done {
                                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                    ErrorHandler.handle(error: err)
                                    throw err
                                }
                                
                                seal.fulfill(decodedJWTToken)
                            }
                            .catch { err in
                                seal.reject(err)
                            }
                            
                        case .complete:
                            seal.fulfill(nil)
                        }
                        
                    } else {
                        precondition(false)
                    }
                }

            } else {
                guard let paymentMethodTokenString = paymentMethodTokenData.token else {
                    let paymentMethodTokenError = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: paymentMethodTokenError)
                    throw paymentMethodTokenError
                }
                
                firstly {
                    self.handleCreatePaymentEvent(paymentMethodTokenString)
                }
                .done { paymentResponse -> Void in
                    guard paymentResponse != nil else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        throw err
                    }

                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse!))
                    self.resumePaymentId = paymentResponse!.id
                    
                    if let requiredAction = paymentResponse!.requiredAction {
                        let apiConfigurationModule = PrimerAPIConfigurationModule()
                        
                        firstly {
                            apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
                        }
                        .done {
                            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                throw err
                            }
                            
                            seal.fulfill(decodedJWTToken)
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
                    if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .fail(let message):
                            var merchantErr: Error!
                            if let message = message {
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                merchantErr = err
                            } else {
                                merchantErr = NSError.emptyDescriptionError
                            }
                            seal.reject(merchantErr)

                    case .succeed:
                        seal.fulfill(nil)
                        case .succeed:
                            seal.fulfill(nil)

                    case .continueWithNewClientToken:
                        seal.fulfill(nil)
                        case .continueWithNewClientToken:
                            seal.fulfill(nil)
                        }
                        
                    } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .continueWithNewClientToken:
                            seal.fulfill(nil)
                        case .complete:
                            seal.fulfill(nil)
                        }
                        
                    } else {
                      precondition(false)
                    }
                }
                
            } else {
                guard let resumePaymentId = self.resumePaymentId else {
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: resumePaymentIdError)
                    seal.reject(resumePaymentIdError)
                    return
                }
                
                firstly {
                    self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                }
                .done { paymentResponse -> Void in
                    guard let paymentResponse = paymentResponse else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
    
    
    func handleFailureFlow(errorMessage: String?) {
        PrimerUIManager.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
        
    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                seal.fulfill()
            } else {
                let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        seal.reject(error)
                    case .continue:
                        seal.fulfill()
                    }
                })
            }
        }
    }

    // Create payment with Payment method token

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            createResumePaymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)) { paymentResponse, error in
                if let paymentResponse {
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                }
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(
                        description: paymentResponse?.id != nil ? "Failed to create payment with id \(paymentResponse!.id!)" : "Failed to create payment",
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString))
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
    
    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment?> {
        
        return Promise { seal in
            
            let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)) { paymentResponse, error in
                if let paymentResponse {
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                }
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(
                        description: paymentResponse?.id != nil ? "Failed to resume payment with id \(paymentResponse!.id!)" : "Failed to resume payment",
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString))
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
