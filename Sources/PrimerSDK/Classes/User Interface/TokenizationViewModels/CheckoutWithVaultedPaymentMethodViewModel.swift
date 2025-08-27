//
//  CheckoutWithVaultedPaymentMethodViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation

final class CheckoutWithVaultedPaymentMethodViewModel: LogReporter {

    let tokenizationService: TokenizationServiceProtocol

    let createResumePaymentService: CreateResumePaymentServiceProtocol

    var config: PrimerPaymentMethod
    var selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData
    var paymentMethodTokenData: PrimerPaymentMethodTokenData!
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?
    var resumePaymentId: String?
    var additionalData: PrimerVaultedCardAdditionalData?

    // Events
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?

    init(configuration: PrimerPaymentMethod,
         selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData,
         additionalData: PrimerVaultedCardAdditionalData?,
         tokenizationService: TokenizationServiceProtocol = TokenizationService(),
         createResumePaymentService: CreateResumePaymentServiceProtocol) {
        self.config = configuration
        self.selectedPaymentMethodTokenData = selectedPaymentMethodTokenData
        self.additionalData = additionalData

        self.tokenizationService = tokenizationService
        self.createResumePaymentService = createResumePaymentService
    }

    func start() async throws {
        do {
            _ = try await startTokenizationFlow()

            if let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData) {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            } else if let paymentCheckoutData {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(paymentCheckoutData)
            }

            await handleSuccessfulFlow()
        } catch {
            didFinishPayment?(error)
            let primerErr = (error as? PrimerError) ?? PrimerError.underlyingErrors(errors: [error])
            let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
            await handleFailureFlow(errorMessage: merchantErrorMessage)
        }
    }

    func performPreTokenizationSteps() async throws {
        try await dispatchActions(config: config, selectedPaymentMethod: selectedPaymentMethodTokenData)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    func performTokenizationStep() async throws {
        guard let tokenizationViewModel = config.tokenizationViewModel else {
            throw handled(primerError: .invalidValue(key: "config.tokenizationViewModel"))
        }

        try await tokenizationViewModel.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()

        guard let paymentMethodTokenId = selectedPaymentMethodTokenData.id else {
            throw handled(primerError: .invalidValue(key: "paymentMethodTokenId"))
        }

        self.paymentMethodTokenData = try await tokenizationService.exchangePaymentMethodToken(
            paymentMethodTokenId,
            vaultedPaymentMethodAdditionalData: additionalData
        )

        try await tokenizationViewModel.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        try await performPreTokenizationSteps()
        try await performTokenizationStep()
        try await performPostTokenizationSteps()
        return paymentMethodTokenData
    }

    private func dispatchActions(config: PrimerPaymentMethod, selectedPaymentMethod: PrimerPaymentMethodTokenData) async throws {
        let network: String? = {
            guard config.type == PrimerPaymentMethodType.paymentCard.rawValue else { return nil }
            let networkName = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
            return (networkName == nil || networkName == "UNKNOWN") ? "OTHER" : networkName
        }()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: network)
    }

    private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        guard PrimerInternal.shared.intent != .vault else {
            return
        }

        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
        let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
        var decisionHandlerHasBeenCalled = false

        // MARK: Check this cancellation (5 seconds?)

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
        case .abort(let errorMessage):
            throw PrimerError.merchantError(message: errorMessage ?? "")
        case .continue:
            return
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        let decodedJWTToken = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
        guard let decodedJWTToken else {
            return paymentCheckoutData
        }

        let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
        guard let resumeToken else {
            return nil
        }

        return try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
    }

    private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        if PrimerSettings.current.paymentHandling == .manual {
            try await handleManualResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
        } else {
            try await handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
        }
    }

    func handleManualResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        let resumeDecision = await PrimerDelegateProxy.primerDidResumeWith(resumeToken)
        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .fail(let message):
                if let message = message {
                    throw PrimerError.merchantError(message: message)
                } else {
                    throw NSError.emptyDescriptionError
                }
            case .succeed, .continueWithNewClientToken:
                return nil
            }
        } else if resumeDecision.type is PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
            return nil
        } else {
            preconditionFailure()
        }
    }

    func handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        guard let resumePaymentId else {
            throw handled(primerError: .invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid"))
        }

        let paymentResponse = try await handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        return paymentCheckoutData
    }

    // Resume payment with Resume payment ID

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.resumePaymentWithPaymentId(
            resumePaymentId,
            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
        )
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

    private func startManualPaymentFlowAndFetchToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws
        -> DecodedJWTToken? {
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
                if let message = message {
                    throw PrimerError.merchantError(message: message)
                } else {
                    throw NSError.emptyDescriptionError
                }
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

    private func startAutomaticPaymentFlowAndFetchToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> DecodedJWTToken? {
        guard let token = paymentMethodTokenData.token else {
            throw handled(primerError: .invalidClientToken())
        }

        let paymentResponse = try await handleCreatePaymentEvent(token)
        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        self.resumePaymentId = paymentResponse.id

        guard let requiredAction = paymentResponse.requiredAction else {
            return nil
        }

        let apiConfigurationModule = PrimerAPIConfigurationModule()
        try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        return decodedJWTToken
    }

    private func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        if decodedJWTToken.intent?.contains("STRIPE_ACH") == true {
            return try await handleStripeACHForDecodedClientToken(decodedJWTToken)
        } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
            return try await handle3DSAuthenticationForDecodedClientToken(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
        } else {
            throw handled(primerError: .invalidValue(key: "resumeToken"))
        }
    }

    private func handleStripeACHForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
        guard let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
              let sdkCompleteUrl = URL(string: sdkCompleteUrlString) else {
            throw handled(primerError: .invalidClientToken())
        }

        await PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        try await createResumePaymentService.completePayment(
            clientToken: decodedJWTToken,
            completeUrl: sdkCompleteUrl,
            body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp
        )
        return nil
    }

    private func handle3DSAuthenticationForDecodedClientToken(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        try await ThreeDSService().perform3DS(
            paymentMethodTokenData: paymentMethodTokenData,
            sdkDismissed: nil
        )
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodData))
    }

    @MainActor
    func handleSuccessfulFlow() {
        if let paymentMethodType = config.internalPaymentMethodType, paymentMethodType == .stripeAch {
            PrimerUIManager.showResultScreen(for: paymentMethodType, error: nil)
        } else {
            PrimerUIManager.dismissOrShowResultScreen(
                type: .success,
                paymentMethodManagerCategories: config.paymentMethodManagerCategories ?? []
            )
        }
    }

    @MainActor
    func handleFailureFlow(errorMessage: String?) {
        PrimerUIManager.dismissOrShowResultScreen(
            type: .failure,
            paymentMethodManagerCategories: config.paymentMethodManagerCategories ?? [],
            withMessage: errorMessage
        )
    }

    private var paymentMethodType: String {
        self.paymentMethodTokenData?.paymentInstrumentData?.paymentMethodType ?? "UNKNOWN"
    }
}
// swiftlint:enable type_name
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
