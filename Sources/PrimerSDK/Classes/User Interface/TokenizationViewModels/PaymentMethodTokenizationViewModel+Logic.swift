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
            self.uiManager.primerRootViewController?.enableUserInteraction(true)
        }
        .catch { err in
            self.uiManager.primerRootViewController?.enableUserInteraction(true)
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
                        primerErr = PrimerError.underlyingErrors(errors: [err],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                    }

                    self.showResultScreenIfNeeded(error: primerErr)
                    return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                }
                // The above promises will never end up on error.
                .catch { _ in
                    self.logger.error(message: "Unselection of payment method failed - this should never happen ...")
                }
            }
        }
    }
    
    @objc
    func start_async() {
        Task {
            do {
                self.paymentMethodTokenData = try await startTokenizationFlow()
                processPaymentMethodTokenData()
                await uiManager.primerRootViewController?.enableUserInteraction(true)
            } catch {
                await uiManager.primerRootViewController?.enableUserInteraction(true)
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

                if let primerErr = error as? PrimerError,
                   case .cancelled = primerErr,
                   PrimerInternal.shared.sdkIntegrationType == .dropIn,
                   self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                   self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                   self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                    
                    try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                    await PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)

                } else {
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()

                        let primerErr: PrimerError
                        if let error = error as? PrimerError {
                            primerErr = error
                        } else {
                            primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)
                        }
                        showResultScreenIfNeeded(error: primerErr)

                        let merchantErrorMessage = try await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                        handleFailureFlow(errorMessage: merchantErrorMessage)
                    } catch {
                        logger.error(message: "Unselection of payment method failed - this should never happen ...")
                    }
                }
            }
        }
    }

    @objc
    func start_async() {
        Task {
            do {
                self.paymentMethodTokenData = try await startTokenizationFlow()
                processPaymentMethodTokenData()
                await uiManager.primerRootViewController?.enableUserInteraction(true)
            } catch {
                await uiManager.primerRootViewController?.enableUserInteraction(true)
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

                if let primerErr = error as? PrimerError,
                   case .cancelled = primerErr,
                   PrimerInternal.shared.sdkIntegrationType == .dropIn,
                   self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                   self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                   self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                    try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                    await PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)

                } else {
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()

                        let primerErr: PrimerError
                        if let error = error as? PrimerError {
                            primerErr = error
                        } else {
                            primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)
                        }
                        showResultScreenIfNeeded(error: primerErr)

                        let merchantErrorMessage = try await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                        handleFailureFlow(errorMessage: merchantErrorMessage)
                    } catch {
                        logger.error(message: "Unselection of payment method failed - this should never happen ...")
                    }
                }
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

            self.showResultScreenIfNeeded()
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
                        primerErr = PrimerError.underlyingErrors(errors: [err],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                    }
                    self.setCheckoutDataFromError(primerErr)
                    self.showResultScreenIfNeeded(error: primerErr)
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
    
    func processCheckoutPaymentMethodTokenData_async() {
        didStartPayment?()
        didStartPayment = nil

        if config.internalPaymentMethodType != .klarna {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
                imageView: uiModule.makeIconImageView(withDimension: 24.0),
                message: nil
            )
        }

        Task {
            defer {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }
            do {
                guard let paymentMethodTokenData else {
                    throw PrimerError.invalidValue(
                        key: "paymentMethodTokenData",
                        value: "Payment method token data is not valid",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                }
                let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)

                didFinishPayment?(nil)
                nullifyEventCallbacks()

                if PrimerSettings.current.paymentHandling == .auto, let checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }

                showResultScreenIfNeeded()
                handleSuccessfulFlow()
            } catch {
                didFinishPayment?(error)
                nullifyEventCallbacks()

                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

                if let primerErr = error as? PrimerError,
                   case .cancelled = primerErr,
                   PrimerInternal.shared.sdkIntegrationType == .dropIn,
                   PrimerInternal.shared.selectedPaymentMethodType == nil,
                   self.config.implementationType == .webRedirect ||
                   self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                   self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                   self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                    try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                } else {
                    try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()

                    let primerErr: PrimerError
                    if let error = error as? PrimerError {
                        primerErr = error
                    } else {
                        primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                    }
                    setCheckoutDataFromError(primerErr)
                    showResultScreenIfNeeded(error: primerErr)
                    let merchantErrorMessage = try? await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                    handleFailureFlow(errorMessage: merchantErrorMessage)
                }
            }
        }
    }

    func processCheckoutPaymentMethodTokenData_async() {
        didStartPayment?()
        didStartPayment = nil

        if config.internalPaymentMethodType != .klarna {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
                imageView: uiModule.makeIconImageView(withDimension: 24.0),
                message: nil
            )
        }

        Task {
            defer {
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }
            }
            do {
                guard let paymentMethodTokenData else {
                    throw PrimerError.invalidValue(
                        key: "paymentMethodTokenData",
                        value: "Payment method token data is not valid",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                }
                let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)

                didFinishPayment?(nil)
                nullifyEventCallbacks()

                if PrimerSettings.current.paymentHandling == .auto, let checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }

                showResultScreenIfNeeded()
                handleSuccessfulFlow()
            } catch {
                didFinishPayment?(error)
                nullifyEventCallbacks()

                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

                if let primerErr = error as? PrimerError,
                   case .cancelled = primerErr,
                   PrimerInternal.shared.sdkIntegrationType == .dropIn,
                   PrimerInternal.shared.selectedPaymentMethodType == nil,
                   self.config.implementationType == .webRedirect ||
                   self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                   self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                   self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                    try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                } else {
                    try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()

                    let primerErr: PrimerError
                    if let error = error as? PrimerError {
                        primerErr = error
                    } else {
                        primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                    }
                    setCheckoutDataFromError(primerErr)
                    showResultScreenIfNeeded(error: primerErr)
                    let merchantErrorMessage = try? await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                    handleFailureFlow(errorMessage: merchantErrorMessage)
                }
            }
        }
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            var cancelledError: PrimerError?
            self.didCancel = {
                self.isCancelled = true
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
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
                        return self.handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
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

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        startPaymentFlowTask = Task {
            do {
                try Task.checkCancellation()

                let decodedJWTToken = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
                try Task.checkCancellation()

                if let decodedJWTToken {
                    let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
                    try Task.checkCancellation()

                    if let resumeToken {
                        let checkoutData = try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                        try Task.checkCancellation()

                        return checkoutData
                    }
                }

                return paymentCheckoutData
            } catch is CancellationError {
                let cancelledError = PrimerError.cancelled(paymentMethodType: config.type,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: cancelledError)
                throw cancelledError
            } catch {
                throw error
            }
        }

        let checkoutData = try await startPaymentFlowTask?.value
        startPaymentFlowTask = nil
        return checkoutData
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
                                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                             diagnosticsId: UUID().uuidString)
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
                                let err = PrimerError.merchantError(message: message,
                                                                    userInfo: .errorUserInfoDictionary(),
                                                                    diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                             diagnosticsId: UUID().uuidString)
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
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                firstly {
                    self.handleCreatePaymentEvent(token)
                }
                .done { paymentResponse -> Void in
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    self.resumePaymentId = paymentResponse.id

                    if let requiredAction = paymentResponse.requiredAction {
                        let apiConfigurationModule = PrimerAPIConfigurationModule()

                        firstly {
                            apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
                        }
                        .done {
                            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                         diagnosticsId: UUID().uuidString)
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

    func startPaymentFlowAndFetchDecodedClientToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> DecodedJWTToken? {
        if PrimerSettings.current.paymentHandling == .manual {
            try await startManualPaymentFlowAndFetchToken(withPaymentMethodTokenData: paymentMethodTokenData)
        } else {
            try await startAutomaticPaymentFlowAndFetchToken(withPaymentMethodTokenData: paymentMethodTokenData)
        }
    }

    func startManualPaymentFlowAndFetchToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> DecodedJWTToken? {
        let resumeDecision = try await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)

        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .succeed:
                return nil

            case .continueWithNewClientToken(let newClientToken):
                let apiConfigurationModule = PrimerAPIConfigurationModule()

                try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }

                return decodedJWTToken

            case .fail(let message):
                let merchantErr: Error
                if let message = message {
                    let err = PrimerError.merchantError(message: message,
                                                        userInfo: .errorUserInfoDictionary(),
                                                        diagnosticsId: UUID().uuidString)
                    merchantErr = err
                } else {
                    merchantErr = NSError.emptyDescriptionError
                }
                throw merchantErr
            }
        } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .continueWithNewClientToken(let newClientToken):
                let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()

                try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }

                return decodedJWTToken

            case .complete:
                return nil
            }

        } else {
            preconditionFailure()
        }
    }

    func startAutomaticPaymentFlowAndFetchToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> DecodedJWTToken? {
        guard let token = paymentMethodTokenData.token else {
            let err = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }

        let paymentResponse = try await handleCreatePaymentEvent(token)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        resumePaymentId = paymentResponse.id

        if let requiredAction = paymentResponse.requiredAction {
            let apiConfigurationModule = PrimerAPIConfigurationModule()

            try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return decodedJWTToken

        } else {
            return nil
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
                                let err = PrimerError.merchantError(message: message,
                                                                    userInfo: .errorUserInfoDictionary(),
                                                                    diagnosticsId: UUID().uuidString)
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
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        if PrimerSettings.current.paymentHandling == .manual {
            try await handleManualResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
        } else {
            try await handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
        }
    }

    private func handleManualResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        let resumeDecision = try await PrimerDelegateProxy.primerDidResumeWith(resumeToken)

        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .fail(let message):
                let merchantErr: Error
                if let message {
                    let err = PrimerError.merchantError(message: message,
                                                        userInfo: .errorUserInfoDictionary(),
                                                        diagnosticsId: UUID().uuidString)
                    merchantErr = err
                } else {
                    merchantErr = NSError.emptyDescriptionError
                }
                throw merchantErr

            case .succeed, .continueWithNewClientToken:
                return nil
            }
        } else if resumeDecision.type is PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
            return nil
        } else {
            preconditionFailure()
        }
    }

    private func handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        guard let resumePaymentId else {
            let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId",
                                                                value: "Resume Payment ID not valid",
                                                                userInfo: .errorUserInfoDictionary(),
                                                                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: resumePaymentIdError)
            throw resumePaymentIdError
        }

        let paymentResponse = try await handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        return paymentCheckoutData
    }

    // This method will show the new design for result screen with a specific state: e.g. Error state or Success state
    // For now we will use it only for STRIPE_ACH implementation
    func showResultScreenIfNeeded(error: PrimerError? = nil) {
        guard let paymentMethodType = config.internalPaymentMethodType,
              paymentMethodType == .stripeAch else {
            return
        }
        PrimerUIManager.showResultScreen(for: paymentMethodType, error: error)
    }

    func handleFailureFlow(errorMessage: String?) {
        if config.internalPaymentMethodType != .stripeAch {
            let categories = config.paymentMethodManagerCategories
            PrimerUIManager.dismissOrShowResultScreen(
                type: .failure,
                paymentMethodManagerCategories: categories ?? [],
                withMessage: errorMessage
            )
        }
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
                                                                  userInfo: .errorUserInfoDictionary(),
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

    func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        if PrimerInternal.shared.intent == .vault {
            return
        }

        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
        let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

        var decisionHandlerHasBeenCalled = false

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

        let paymentCreationDecision = try await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)
        decisionHandlerHasBeenCalled = true

        switch paymentCreationDecision.type {
        case .abort(let errorMessage):
            let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                  userInfo: .errorUserInfoDictionary(),
                                                  diagnosticsId: UUID().uuidString)
            throw error
        case .continue:
            return
        }
    }

    // Create payment with Payment method token

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
        let body = Request.Body.Payment.Create(token: paymentMethodData)
        return createResumePaymentService.createPayment(paymentRequest: body)
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
        )
    }

    // Resume payment with Resume payment ID

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
        let body = Request.Body.Payment.Resume(token: resumeToken)
        return createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: body)
    }

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.resumePaymentWithPaymentId(
            resumePaymentId,
            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
        )
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

    func setCheckoutDataFromError(_ error: PrimerError) {
        if let checkoutData = error.checkoutData {
            self.paymentCheckoutData = checkoutData
        }
    }
}

extension PrimerError {
    var checkoutData: PrimerCheckoutData? {
        switch self {
        case .paymentFailed(_, let paymentId, let orderId, _, _, _):
            return PrimerCheckoutData(
                payment: PrimerCheckoutDataPayment(id: paymentId,
                                                   orderId: orderId,
                                                   paymentFailureReason: PrimerPaymentErrorCode.failed))
        default:
            return nil
        }
    }
}

extension PaymentMethodTokenizationViewModel: PaymentMethodTypeViaPaymentMethodTokenDataProviding {}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable file_length
