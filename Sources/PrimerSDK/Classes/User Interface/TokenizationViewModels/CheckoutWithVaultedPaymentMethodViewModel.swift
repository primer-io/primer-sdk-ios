//
//  CheckoutWithVaultedPaymentMethodViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/5/22.
//

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

    func start() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.startTokenizationFlow()
            }
            .then { _ -> Promise<PrimerCheckoutData?> in
                return self.startPaymentFlow(withPaymentMethodTokenData: self.paymentMethodTokenData)
            }
            .done { checkoutData in
                if let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                } else if let checkoutData = self.paymentCheckoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
                DispatchQueue.main.async {
                    self.handleSuccessfulFlow()
                }
                seal.fulfill()
            }
            .catch { err in
                self.didFinishPayment?(err)

                var primerErr: PrimerError!
                if let error = err as? PrimerError {
                    primerErr = error
                } else {
                    primerErr = PrimerError.underlyingErrors(errors: [err])
                }

                firstly {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    DispatchQueue.main.async {
                        self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    }
                    seal.fulfill()
                }
                .catch { _ in }
            }
        }
    }
    
    func start_async() async throws {
        do {
            _ = try await self.startTokenizationFlow()

            if let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData) {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            } else if let paymentCheckoutData {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(paymentCheckoutData)
            }

            await handleSuccessfulFlow()
        } catch {
            self.didFinishPayment?(error)
            let primerErr = (error as? PrimerError) ?? PrimerError.underlyingErrors(errors: [error])
            let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
            await handleFailureFlow(errorMessage: merchantErrorMessage)
        }
    }

    func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.dispatchActions(config: self.config, selectedPaymentMethod: self.selectedPaymentMethodTokenData)
            }
            .then { () -> Promise<Void> in
                self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func performPreTokenizationSteps() async throws {
        try await dispatchActions(config: config, selectedPaymentMethod: selectedPaymentMethodTokenData)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.config.tokenizationViewModel!.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                guard let paymentMethodTokenId = self.selectedPaymentMethodTokenData.id else {
                    throw PrimerError.invalidValue(key: "paymentMethodTokenId")
                }

                return self.tokenizationService.exchangePaymentMethodToken(paymentMethodTokenId,
                                                                           vaultedPaymentMethodAdditionalData: self.additionalData)
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.config.tokenizationViewModel!.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func performTokenizationStep() async throws {
        guard let tokenizationViewModel = config.tokenizationViewModel else {
            throw handled(primerError: .invalidValue(key: "config.tokenizationViewModel"))
        }

        try await tokenizationViewModel.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()

        guard let paymentMethodTokenId = self.selectedPaymentMethodTokenData.id else {
            throw handled(primerError: .invalidValue(key: "paymentMethodTokenId"))
        }

        self.paymentMethodTokenData = try await tokenizationService.exchangePaymentMethodToken(
            paymentMethodTokenId,
            vaultedPaymentMethodAdditionalData: additionalData
        )

        try await tokenizationViewModel.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(self.paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        try await performPreTokenizationSteps()
        try await performTokenizationStep()
        try await performPostTokenizationSteps()
        return paymentMethodTokenData
    }

    private func dispatchActions(config: PrimerPaymentMethod, selectedPaymentMethod: PrimerPaymentMethodTokenData) -> Promise<Void> {
        return Promise { seal in
            var network: String?
            if config.type == PrimerPaymentMethodType.paymentCard.rawValue {
                network = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
            }

            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            firstly {
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: network)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
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
                            seal.reject(PrimerError.merchantError(message: errorMessage ?? ""))
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

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData)
    -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            firstly {
                self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { decodedJWTToken in
                if let decodedJWTToken = decodedJWTToken {
                    firstly {
                        self.handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
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

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        let decodedJWTToken = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
        guard let decodedJWTToken else {
            return self.paymentCheckoutData
        }

        let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
        guard let resumeToken else {
            return nil
        }

        return try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
    }

    private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            if PrimerSettings.current.paymentHandling == .manual {
                PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                    if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .fail(let message):
                            var merchantErr: Error!
                            if let message {
                                merchantErr = PrimerError.merchantError(message: message)
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
                    return seal.reject(
                        handled(
                            primerError: .invalidValue(
                                key: "resumePaymentId",
                                value: "Resume Payment ID not valid"
                            )
                        )
                    )
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
            precondition(false)
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

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
        let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
        return self.createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                          paymentResumeRequest: resumeRequest)
    }

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.resumePaymentWithPaymentId(
            resumePaymentId,
            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
        )
    }

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
                                    throw handled(primerError: .invalidClientToken())
                                }

                                seal.fulfill(decodedJWTToken)
                            }
                            .catch { err in
                                seal.reject(err)
                            }

                        case .fail(let message):
                            var merchantErr: Error!
                            if let message {
                                merchantErr = PrimerError.merchantError(message: message)
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
                                    throw handled(primerError: .invalidClientToken())
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
                    return seal.reject(handled(primerError: .invalidClientToken()))
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
                                throw handled(primerError: .invalidClientToken())
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

    func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws
        -> DecodedJWTToken? {
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

    private func startAutomaticPaymentFlowAndFetchToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws
        -> DecodedJWTToken? {
        guard let token = paymentMethodTokenData.token else {
            throw handled(primerError: .invalidClientToken())
        }

        let paymentResponse = try await self.handleCreatePaymentEvent(token)
        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        self.resumePaymentId = paymentResponse.id

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

    private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in

            if decodedJWTToken.intent?.contains("STRIPE_ACH") == true {
                if let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
                   let sdkCompleteUrl = URL(string: sdkCompleteUrlString) {

                    DispatchQueue.main.async {
                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                    }

                    firstly {
                        self.createResumePaymentService.completePayment(clientToken: decodedJWTToken,
                                                                        completeUrl: sdkCompleteUrl,
                                                                        body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
                    }
                    .done {
                        seal.fulfill(nil)
                    }
                    .catch { err in
                        seal.reject(err)
                    }

                } else {
                    seal.reject(handled(primerError: .invalidClientToken()))
                }
            } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {

                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(
                    paymentMethodTokenData: paymentMethodTokenData,
                    sdkDismissed: nil) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let resumeToken):
                            seal.fulfill(resumeToken)

                        case .failure(let err):
                            seal.reject(err)
                        }
                    }
                }

            } else {
                seal.reject(handled(primerError: .invalidValue(key: "resumeToken")))
            }
        }
    }

    private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                  paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
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
        try await createResumePaymentService.completePayment(clientToken: decodedJWTToken,
                                                             completeUrl: sdkCompleteUrl,
                                                             body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
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

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
        let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
        return createResumePaymentService.createPayment(paymentRequest: paymentRequest)
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodData))
    }

    @MainActor
    func handleSuccessfulFlow() {
        if let paymentMethodType = config.internalPaymentMethodType,
           paymentMethodType == .stripeAch {
            PrimerUIManager.showResultScreen(for: paymentMethodType, error: nil)
        } else {
            PrimerUIManager.dismissOrShowResultScreen(type: .success,
                                                      paymentMethodManagerCategories: config.paymentMethodManagerCategories ?? [])
        }
    }

    @MainActor
    func handleFailureFlow(errorMessage: String?) {
        PrimerUIManager.dismissOrShowResultScreen(type: .failure,
                                                  paymentMethodManagerCategories: config.paymentMethodManagerCategories ?? [],
                                                  withMessage: errorMessage)
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
