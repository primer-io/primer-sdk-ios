//
//  PrimerPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

import Foundation

internal class PrimerPaymentModule {
    
    let paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator
    // PrimerCheckoutData will be nil on manual flow
    internal var checkoutData: PrimerCheckoutData?
    private var paymentId: String?
    private var requiredAction: Response.Body.Payment.RequiredAction?
    private var resumeToken: String?
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func start() -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            firstly {
                self.performPrePaymentSteps()
            }
            .then { () -> Promise<Void> in
                return self.performPayment(with: self.paymentMethodOrchestrator.tokenizationModule.paymentMethodTokenData!)
            }
            .then { () -> Promise<Void> in
                return self.performPostPaymentSteps()
            }
            .done {
                seal.fulfill(self.checkoutData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    internal func performPrePaymentSteps() -> Promise<Void> {
        // If not overriden, it will fulfill immediately
        return Promise()
    }
    
    internal func performPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<Void> {
        if PrimerSettings.current.paymentHandling == .auto {
            return self.performAutoPayment(with: paymentMethodTokenData)
        } else {
            // Payment will be performed by the merchant and we'll get the result
            // through the decision handler
            return self.performManualPayment(with: paymentMethodTokenData)
        }
    }
    
    internal func performPostPaymentSteps() -> Promise<Void> {
        // If not overriden, it will emit relevant events and fulfill immediately
        return Promise()
    }
    
    // MARK: - PAYMENT HANDLING: AUTO
    
    private func performAutoPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.createAutoPayment(with: paymentMethodTokenData)
            }
            .then { paymentResponse -> Promise<(paymentId: String?, resumeToken: String?)> in
                return self.handlePaymentResponseOnAutoFlowIfNeeded(for: paymentResponse)
            }
            .then { result -> Promise<Void> in
                return self.resumeAutoPaymentIfNeeded(paymentId: result.paymentId, resumeToken: result.resumeToken)
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func createAutoPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<Response.Body.Payment> {
        return Promise { seal in
            let paymentRequest = Request.Body.Payment.Create(token: paymentMethodTokenData.token!)
            let createPaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            self.paymentMethodOrchestrator.eventEmitter.fireWillStartPaymentCreationEvent()
            
            createPaymentService.createPayment(paymentRequest: paymentRequest) { [weak self] paymentResponse, err in
                self?.paymentMethodOrchestrator.eventEmitter.fireDidFinishPaymentCreationEvent()
                
                if let paymentResponse = paymentResponse {
                    self?.checkoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    self?.requiredAction = paymentResponse.requiredAction
                }
                
                if let err = err {
                    seal.reject(err)
                    
                } else if let paymentResponse = paymentResponse {
                    if paymentResponse.id == nil {
                        let err = PrimerError.paymentFailed(
                            description: "Failed to create payment",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        
                    } else if paymentResponse.status == .failed {
                        let err = PrimerError.failedToProcessPayment(
                            paymentId: paymentResponse.id ?? "nil",
                            status: paymentResponse.status.rawValue,
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        
                    } else {
                        seal.fulfill(paymentResponse)
                    }
                    
                } else {
                    let err = PrimerError.paymentFailed(
                        description: "Failed to create payment",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
    }
    
    private func resumeAutoPaymentIfNeeded(paymentId: String?, resumeToken: String?) -> Promise<Void> {
        if let paymentId = paymentId, let resumeToken = resumeToken {
            return Promise { seal in
                let resumePaymentRequest = Request.Body.Payment.Resume(token: resumeToken)
                let resumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                resumePaymentService.resumePaymentWithPaymentId(paymentId, paymentResumeRequest: resumePaymentRequest, completion: { [weak self] paymentResponse, err in
                    if let paymentResponse = paymentResponse {
                        self?.checkoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    }
                    
                    if let err = err {
                        seal.reject(err)
                        
                    } else if let paymentResponse = paymentResponse {
                        if paymentResponse.id == nil {
                            let err = PrimerError.paymentFailed(
                                description: "Failed to resume payment",
                                userInfo: [
                                    "file": #file,
                                    "class": "\(Self.self)",
                                    "function": #function,
                                    "line": "\(#line)"
                                ],
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            
                        } else if paymentResponse.status == .failed {
                            let err = PrimerError.failedToProcessPayment(
                                paymentId: paymentResponse.id ?? "nil",
                                status: paymentResponse.status.rawValue,
                                userInfo: [
                                    "file": #file,
                                    "class": "\(Self.self)",
                                    "function": #function,
                                    "line": "\(#line)"
                                ],
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            
                        } else {
                            seal.fulfill()
                        }
                        
                    } else {
                        let err = PrimerError.paymentFailed(
                            description: "Failed to create payment",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                })
            }
        } else {
            return Promise()
        }
        
    }
    
    // MARK: - PAYMENT HANDLING: MANUAL
    
    private final func performManualPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.createManualPayment(with: paymentMethodTokenData)
            }
            .then { newClientToken -> Promise<String?> in
                return self.handleNewClientTokenOnManualFlowIfNeeded(newClientToken)
            }
            .then { resumeToken -> Promise<Void> in
                return self.resumeManualPaymentIfNeeded(resumeToken: resumeToken)
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private final func createManualPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in
            PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                if let resumeType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                    switch resumeType {
                    case .complete:
                        seal.fulfill(nil)
                        
                    case .continueWithNewClientToken(let newClientToken):
                        seal.fulfill(newClientToken)
                    }
                    
                } else if let resumeType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                    switch resumeType {
                    case .succeed:
                        seal.fulfill(nil)
                        
                    case .continueWithNewClientToken(let newClientToken):
                        seal.fulfill(newClientToken)
                        
                    case .fail(let errorMessage):
                        var merchantErr: Error!
                        if let message = errorMessage {
                            let err = PrimerError.merchantError(
                                message: message,
                                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                diagnosticsId: UUID().uuidString)
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)
                    }
                }
            }
        }
    }
    
    private final func resumeManualPaymentIfNeeded(resumeToken: String?) -> Promise<Void> {
        return Promise { seal in
            guard let resumeToken = resumeToken else {
                seal.fulfill()
                return
            }
            
            PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                    switch resumeDecisionType {
                    case .continueWithNewClientToken:
                        // In the future we might support flows that receive a new required action
                        // when resuming and go through the flow again.
                        seal.fulfill()
                        
                    case .complete:
                        seal.fulfill()
                    }
                    
                } else if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                    switch resumeDecisionType {
                    case .fail(let message):
                        var merchantErr: Error!
                        if let message = message {
                            let err = PrimerError.merchantError(
                                message: message,
                                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                diagnosticsId: UUID().uuidString)
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)
                        
                    case .succeed:
                        seal.fulfill()
                        
                    case .continueWithNewClientToken:
                        // In the future we might support flows that receive a new required action
                        // when resuming and go through the flow again.
                        seal.fulfill()
                    }
                    
                } else {
                    let err = PrimerError.unknown(
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
    }

    // MARK: - HANDLE REQUIRED ACTIONS
    
    /// Common logic between any actions will get handled in this class, but **handleDecodedClientTokenIfNeeded**
    /// must be overriden and handle payment method specific logic.
    
    private final func handlePaymentResponseOnAutoFlowIfNeeded(for paymentResponse: Response.Body.Payment) -> Promise<(paymentId: String?, resumeToken: String?)> {
        return Promise { seal in
            if let newClientToken = paymentResponse.requiredAction?.clientToken {
                firstly {
                    self.storedNewClientToken(newClientToken)
                }
                .then { () -> Promise<String?> in
                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                    
                    return self.handleDecodedClientTokenIfNeeded(decodedJWTToken)
                }
                .done { resumeToken in
                    guard let paymentId = paymentResponse.id else {
                        let err = PrimerError.invalidValue(
                            key: "id",
                            value: nil,
                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                    
                    self.resumeToken = resumeToken
                    seal.fulfill((paymentId, resumeToken))
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                seal.fulfill((nil, nil))
            }
        }
    }
    
    private final func handleNewClientTokenOnManualFlowIfNeeded(_ newClientToken: String?) -> Promise<String?> {
        return Promise { seal in
            if let newClientToken = newClientToken {
                firstly {
                    self.storedNewClientToken(newClientToken)
                }
                .then { () -> Promise<String?> in
                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                    
                    return self.handleDecodedClientTokenIfNeeded(decodedJWTToken)
                }
                .done { resumeToken in
                    self.resumeToken = resumeToken
                    seal.fulfill(resumeToken)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                seal.fulfill(nil)
            }
        }
    }
    
    private func storedNewClientToken(_ newClientToken: String) -> Promise<Void> {
        return Promise { seal in
            let apiConfigurationModule = PrimerAPIConfigurationModule()
            
            firstly {
                apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    internal func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
    }
}
