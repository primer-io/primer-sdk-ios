//
//  PaymentMethodTokenizationViewModel+Logic.swift
//  PrimerSDK
//
//  Created by Evangelos on 6/5/22.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length

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
            self.processPaymentMethodTokenData()
        }
        .ensure {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        }
        .catch { err in
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            if let primerErr = err as? PrimerError,
               case .cancelled = primerErr,
               PrimerInternal.shared.sdkIntegrationType == .dropIn,
               self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done { _ in
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

    func processPaymentMethodTokenData() {
        if PrimerInternal.shared.intent == .vault {
            if config.internalPaymentMethodType != .klarna {
                processVaultPaymentMethodTokenData()
                return
            }
            processCheckoutPaymentMethodTokenData()
        } else {
            processCheckoutPaymentMethodTokenData()
        }
    }

    func processVaultPaymentMethodTokenData() {
        PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.paymentMethodTokenData!) { _ in }
        self.handleSuccessfulFlow()
    }

    func processCheckoutPaymentMethodTokenData() {
        self.didStartPayment?()
        self.didStartPayment = nil

        if config.internalPaymentMethodType != .klarna {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
                imageView: self.uiModule.makeIconImageView(withDimension: 24.0),
                message: nil)
        }

        firstly {
            self.startPaymentFlow(withPaymentMethodTokenData: self.paymentMethodTokenData!)
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
               case .cancelled = primerErr,
               PrimerInternal.shared.sdkIntegrationType == .dropIn,
               PrimerInternal.shared.selectedPaymentMethodType == nil,
               self.config.implementationType == .webRedirect ||
                self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done { _ in
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
                self.isCancelled = false
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
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                                        "class": "\(Self.self)",
                                                                                        "function": #function,
                                                                                        "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file,
                                                                                                 "class": "\(Self.self)",
                                                                                                 "function": #function,
                                                                                                 "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                                        "class": "\(Self.self)",
                                                                                        "function": #function,
                                                                                        "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                guard let token = paymentMethodTokenData.token else {
                    let err = PrimerError.invalidClientToken(
                        userInfo: ["file": #file,
                                   "class": "\(Self.self)",
                                   "function": #function,
                                   "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                firstly {
                    self.handleCreatePaymentEvent(token)
                }
                .done { paymentResponse -> Void in
                    guard paymentResponse != nil else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file,
                                                                                                          "class": "\(Self.self)",
                                                                                                          "function": #function,
                                                                                                          "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                                    "class": "\(Self.self)",
                                                                                    "function": #function,
                                                                                    "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file,
                                                                                                 "class": "\(Self.self)",
                                                                                                 "function": #function,
                                                                                                 "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId",
                                                                        value: "Resume Payment ID not valid",
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: resumePaymentIdError)
                    seal.reject(resumePaymentIdError)
                    return
                }

                firstly {
                    self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                }
                .done { paymentResponse -> Void in
                    guard let paymentResponse = paymentResponse else {
                        let err = PrimerError.invalidValue(key: "paymentResponse",
                                                           value: nil,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
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

                var decisionHandlerHasBeenCalled = false

                PrimerDelegateProxy.primerWillCreatePaymentWithData(
                    checkoutPaymentMethodData,
                    decisionHandler: { paymentCreationDecision in
                        decisionHandlerHasBeenCalled = true
                        switch paymentCreationDecision.type {
                        case .abort(let errorMessage):
                            let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                                  userInfo: ["file": #file,
                                                                             "class": "\(Self.self)",
                                                                             "function": #function,
                                                                             "line": "\(#line)"],
                                                                  diagnosticsId: UUID().uuidString)
                            seal.reject(error)
                        case .continue:
                            seal.fulfill()
                        }
                    })

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    if !decisionHandlerHasBeenCalled {
                        let message =
                            """
The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
Make sure you call the decision handler otherwise the SDK will hang.
"""
                        self?.logger.warn(message: message)
                    }
                }
            }
        }
    }

    // Create payment with Payment method token

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            let body = Request.Body.Payment.Create(token: paymentMethodData)
            createResumePaymentService.createPayment(paymentRequest: body) { paymentResponse, error in

                if let error = error {
                    if let paymentResponse {
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    }

                    seal.reject(error)

                } else if let paymentResponse = paymentResponse {
                    if paymentResponse.id == nil {
                        let err = PrimerError.paymentFailed(
                            paymentMethodType: self.paymentMethodType,
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
                            paymentMethodType: self.paymentMethodType,
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
                        paymentMethodType: self.paymentMethodType,
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

    // Resume payment with Resume payment ID

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            let body = Request.Body.Payment.Resume(token: resumeToken)
            createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: body) { paymentResponse, error in

                if let error = error {
                    if let paymentResponse {
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    }

                    seal.reject(error)

                } else if let paymentResponse = paymentResponse {
                    if paymentResponse.id == nil {
                        let err = PrimerError.paymentFailed(
                            paymentMethodType: self.paymentMethodType,
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
                            paymentMethodType: self.paymentMethodType,
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
                        paymentMethodType: self.paymentMethodType,
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
                }
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

extension PaymentMethodTokenizationViewModel: PaymentMethodTypeViaPaymentMethodTokenDataProviding {}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable file_length
