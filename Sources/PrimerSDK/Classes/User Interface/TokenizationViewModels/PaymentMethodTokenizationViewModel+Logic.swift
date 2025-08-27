//
//  PaymentMethodTokenizationViewModel+Logic.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length

import Foundation
import UIKit

extension PaymentMethodTokenizationViewModel {
    @objc
    func start() {
        Task {
            do {
                paymentMethodTokenData = try await startTokenizationFlow()
                await processPaymentMethodTokenData()
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
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        await PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
                    } catch {}
                } else {
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        let primerErr = (error as? PrimerError) ?? PrimerError.underlyingErrors(errors: [error])
                        await showResultScreenIfNeeded(error: primerErr)
                        let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                        await handleFailureFlow(errorMessage: merchantErrorMessage)
                    } catch {}
                }
            }
        }
    }

    @objc
    func start_async() {
        Task {
            do {
                paymentMethodTokenData = try await startTokenizationFlow()
                await processPaymentMethodTokenData()
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
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        await PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
                    } catch {}
                } else {
                    do {
                        try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                        let primerErr = (error as? PrimerError) ?? PrimerError.underlyingErrors(errors: [error])
                        await showResultScreenIfNeeded(error: primerErr)
                        let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                        await handleFailureFlow(errorMessage: merchantErrorMessage)
                    } catch {}
                }
            }
        }
    }

    func processPaymentMethodTokenData() async {
        if PrimerInternal.shared.intent == .vault {
            await processVaultPaymentMethodTokenData()
        } else {
            await processCheckoutPaymentMethodTokenData()
        }
    }

    @MainActor
    func processVaultPaymentMethodTokenData() {
        PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.paymentMethodTokenData!) { _ in }
        handleSuccessfulFlow()
    }

    func processCheckoutPaymentMethodTokenData() async {
        didStartPayment?()
        didStartPayment = nil

        if config.internalPaymentMethodType != .klarna {
            await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
                imageView: uiModule.makeIconImageView(withDimension: 24.0),
                message: nil
            )
        }

        defer {
            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }
        }
        do {
            guard let paymentMethodTokenData else {
                throw PrimerError.invalidValue(
                    key: "paymentMethodTokenData",
                    value: "Payment method token data is not valid"
                )
            }
            let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)

            didFinishPayment?(nil)
            nullifyEventCallbacks()

            if PrimerSettings.current.paymentHandling == .auto, let checkoutData {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            }

            await showResultScreenIfNeeded()
            await handleSuccessfulFlow()
        } catch {
            didFinishPayment?(error)
            nullifyEventCallbacks()

            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            try? await clientSessionActionsModule.unselectPaymentMethodIfNeeded()

            if let primerErr = error as? PrimerError,
               case .cancelled = primerErr,
               PrimerInternal.shared.sdkIntegrationType == .dropIn,
               PrimerInternal.shared.selectedPaymentMethodType == nil,
               self.config.implementationType == .webRedirect ||
               self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
               self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
               self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                await PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
            } else {
                let primerErr = (error as? PrimerError) ?? PrimerError.underlyingErrors(errors: [error])
                setCheckoutDataFromError(primerErr)
                await showResultScreenIfNeeded(error: primerErr)
                let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                await handleFailureFlow(errorMessage: merchantErrorMessage)
            }
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        defer {
            startPaymentFlowTask = nil
        }

        let task = CancellableTask<PrimerCheckoutData?> {
            try Task.checkCancellation()

            let decodedJWTToken = try await self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            try Task.checkCancellation()

            if let decodedJWTToken {
                let resumeToken = try await self.handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
                try Task.checkCancellation()

                if let resumeToken {
                    let checkoutData = try await self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                    try Task.checkCancellation()

                    return checkoutData
                }
            }

            return self.paymentCheckoutData
        }
        startPaymentFlowTask = task

        if isCancelled {
            await task.cancel(with: handled(primerError: .cancelled(paymentMethodType: self.config.type)))
        }

        return try await task.wait()
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
        let resumeDecision = await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)
        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .succeed:
                return nil

            case .continueWithNewClientToken(let newClientToken):
                let apiConfigurationModule = PrimerAPIConfigurationModule()

                try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    throw handled(primerError: .invalidClientToken())
                }

                return decodedJWTToken

            case .fail(let message):
                let merchantErr: Error
                if let message {
                    merchantErr = PrimerError.merchantError(message: message)
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
                    throw handled(primerError: .invalidClientToken())
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
            throw handled(primerError: .invalidClientToken())
        }

        let paymentResponse = try await handleCreatePaymentEvent(token)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        resumePaymentId = paymentResponse.id

        if let requiredAction = paymentResponse.requiredAction {
            let apiConfigurationModule = PrimerAPIConfigurationModule()

            try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                throw handled(primerError: .invalidClientToken())
            }

            return decodedJWTToken

        } else {
            return nil
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
        let resumeDecision = await PrimerDelegateProxy.primerDidResumeWith(resumeToken)

        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .fail(let message):
                let merchantErr: Error
                if let message {
                    merchantErr = PrimerError.merchantError(message: message)
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
            throw handled(primerError: .invalidValue(key: "resumePaymentId",
                                                     value: "Resume Payment ID not valid"))
        }

        let paymentResponse = try await handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        return paymentCheckoutData
    }

    // This method will show the new design for result screen with a specific state: e.g. Error state or Success state
    // For now we will use it only for STRIPE_ACH implementation
    @MainActor
    func showResultScreenIfNeeded(error: PrimerError? = nil) {
        guard let paymentMethodType = config.internalPaymentMethodType,
              paymentMethodType == .stripeAch else {
            return
        }
        PrimerUIManager.showResultScreen(for: paymentMethodType, error: error)
    }

    @MainActor
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

        let paymentCreationDecision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)
        decisionHandlerHasBeenCalled = true

        switch paymentCreationDecision.type {
        case .abort(let errorMessage): throw PrimerError.merchantError(message: errorMessage ?? "")
        case .continue: return
        }
    }

    // Create payment with Payment method token

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
        )
    }

    // Resume payment with Resume payment ID

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.resumePaymentWithPaymentId(
            resumePaymentId,
            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
        )
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
        case .paymentFailed(_, let paymentId, let orderId, _, _):
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
