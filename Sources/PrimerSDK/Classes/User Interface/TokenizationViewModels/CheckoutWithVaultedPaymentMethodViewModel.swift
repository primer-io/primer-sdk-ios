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

                self.handleSuccessfulFlow()
                seal.fulfill()
            }
            .catch { err in
                self.didFinishPayment?(err)

                var primerErr: PrimerError!
                if let error = err as? PrimerError {
                    primerErr = error
                } else {
                    primerErr = PrimerError.underlyingErrors(errors: [err],
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                }

                firstly {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    seal.fulfill()
                }
                .catch { _ in }
            }
        }
    }

    func start() async throws {
        do {
            _ = try await startTokenizationFlow()
            let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
            if let checkoutData = checkoutData {
                PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            } else if let checkoutData = paymentCheckoutData {
                PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            }

            handleSuccessfulFlow()
        } catch {
            didFinishPayment?(error)

            var primerErr: PrimerError!
            if let error = error as? PrimerError {
                primerErr = error
            } else {
                primerErr = PrimerError.underlyingErrors(errors: [error], userInfo: .errorUserInfoDictionary(), diagnosticsId: UUID().uuidString)
            }

            do {
                let merchantErrorMessage = try await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: paymentCheckoutData)
                handleFailureFlow(errorMessage: merchantErrorMessage)
            } catch {
                // No need to handle the error here, it will be handled by the delegate proxy
            }
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
                    let err = PrimerError.invalidValue(
                        key: "paymentMethodTokenId",
                        value: nil,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: err)
                    throw err
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
        try await config.tokenizationViewModel!.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        guard let paymentMethodTokenId = selectedPaymentMethodTokenData.id else {
            let err = PrimerError.invalidValue(
                key: "paymentMethodTokenId",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }

        let paymentMethodTokenData = try await tokenizationService.exchangePaymentMethodToken(
            paymentMethodTokenId,
            vaultedPaymentMethodAdditionalData: additionalData
        )
        self.paymentMethodTokenData = paymentMethodTokenData
        try await config.tokenizationViewModel!.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    func performPostTokenizationSteps() async throws {}

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
        var network: String?
        if config.type == PrimerPaymentMethodType.paymentCard.rawValue {
            network = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
        }

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: network)
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
                    }
                )

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

    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        guard PrimerInternal.shared.intent != .vault else {
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

        return try await withCheckedThrowingContinuation { continuation in
            PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                decisionHandlerHasBeenCalled = true
                switch paymentCreationDecision.type {
                case .abort(let errorMessage):
                    let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                          userInfo: .errorUserInfoDictionary(),
                                                          diagnosticsId: UUID().uuidString)
                    continuation.resume(throwing: error)
                case .continue:
                    continuation.resume()
                }
            })
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) -> Promise<PrimerCheckoutData?> {
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

        if let decodedJWTToken = decodedJWTToken {
            let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
            if let resumeToken = resumeToken {
                let checkoutData = try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                return checkoutData
            } else {
                return nil
            }
        }
        return paymentCheckoutData
    }

    private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
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
                        preconditionFailure()
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
                .done { paymentResponse in
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
            return try await withCheckedThrowingContinuation { continuation in
                PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                    if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .fail(let message):
                            let err: Error
                            if let message = message {
                                err = PrimerError.merchantError(message: message,
                                                                userInfo: .errorUserInfoDictionary(),
                                                                diagnosticsId: UUID().uuidString)
                            } else {
                                err = NSError.emptyDescriptionError
                            }
                            continuation.resume(throwing: err)

                        case .succeed:
                            continuation.resume(returning: nil)

                        case .continueWithNewClientToken:
                            continuation.resume(returning: nil)
                        }
                    } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .continueWithNewClientToken:
                            continuation.resume(returning: nil)
                        case .complete:
                            continuation.resume(returning: nil)
                        }
                    } else {
                        preconditionFailure()
                    }
                }
            }
        } else {
            guard let resumePaymentId = resumePaymentId else {
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
    }

    // Resume payment with Resume payment ID

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
        let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
        return createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                     paymentResumeRequest: resumeRequest)
    }

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
        let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
        return try await createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                               paymentResumeRequest: resumeRequest)
    }

    func startPaymentFlowAndFetchDecodedClientToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) -> Promise<DecodedJWTToken?> {
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
                        preconditionFailure()
                    }
                }

            } else {
                guard let token = paymentMethodTokenData.token else {
                    let err = PrimerError.invalidClientToken(
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                firstly {
                    self.handleCreatePaymentEvent(token)
                }
                .done { paymentResponse in
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
            return try await withCheckedThrowingContinuation { continuation in
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                    if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .fail(let message):
                            let err: Error
                            if let message {
                                err = PrimerError.merchantError(message: message,
                                                                userInfo: .errorUserInfoDictionary(),
                                                                diagnosticsId: UUID().uuidString)
                            } else {
                                err = NSError.emptyDescriptionError
                            }
                            continuation.resume(throwing: err)

                        case .succeed:
                            continuation.resume(returning: nil)

                        case .continueWithNewClientToken(let newClientToken):
                            Task {
                                do {
                                    let apiConfigurationModule = PrimerAPIConfigurationModule()
                                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                                 diagnosticsId: UUID().uuidString)
                                        ErrorHandler.handle(error: err)
                                        throw err
                                    }
                                    continuation.resume(returning: decodedJWTToken)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                        }
                    } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .continueWithNewClientToken(let newClientToken):
                            Task {
                                do {
                                    let apiConfigurationModule = PrimerAPIConfigurationModule()
                                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                                 diagnosticsId: UUID().uuidString)
                                        ErrorHandler.handle(error: err)
                                        throw err
                                    }
                                    continuation.resume(returning: decodedJWTToken)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                        case .complete:
                            continuation.resume(returning: nil)
                        }
                    } else {
                        preconditionFailure()
                    }
                }
            }
        } else {
            guard let token = paymentMethodTokenData.token else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
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
            }
        }
        return nil
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
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(
                    paymentMethodTokenData: paymentMethodTokenData,
                    sdkDismissed: nil
                ) { result in
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
                let err = PrimerError.invalidValue(key: "resumeToken",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }

    private func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        if decodedJWTToken.intent?.contains("STRIPE_ACH") == true {
            if let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
               let sdkCompleteUrl = URL(string: sdkCompleteUrlString) {
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }
                try await createResumePaymentService.completePayment(clientToken: decodedJWTToken,
                                                                     completeUrl: sdkCompleteUrl,
                                                                     body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
            } else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
            // REVIEW_CHECK: This is a workaround to ensure the 3DS service is executed on the detached task.
            // And the result is returned on the main thread.
            let resumeTokenResult = await Task.detached {
                let threeDSService = ThreeDSService()
                return try await threeDSService.perform3DS(
                    paymentMethodTokenData: paymentMethodTokenData,
                    sdkDismissed: nil
                )
            }.result

            return try await MainActor.run {
                switch resumeTokenResult {
                case .success(let resumeToken):
                    return resumeToken
                case .failure(let error):
                    throw error
                }
            }
        } else {
            let err = PrimerError.invalidValue(key: "resumeToken",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        return nil
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
        let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
        return createResumePaymentService.createPayment(paymentRequest: paymentRequest)
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
        return try await createResumePaymentService.createPayment(paymentRequest: paymentRequest)
    }

    func handleSuccessfulFlow() {
        if let paymentMethodType = config.internalPaymentMethodType,
           paymentMethodType == .stripeAch {
            PrimerUIManager.showResultScreen(for: paymentMethodType, error: nil)
        } else {
            let categories = config.paymentMethodManagerCategories
            PrimerUIManager.dismissOrShowResultScreen(type: .success,
                                                      paymentMethodManagerCategories: categories ?? [])
        }
    }

    func handleFailureFlow(errorMessage: String?) {
        let categories = config.paymentMethodManagerCategories
        PrimerUIManager.dismissOrShowResultScreen(type: .failure,
                                                  paymentMethodManagerCategories: categories ?? [],
                                                  withMessage: errorMessage)
    }

    private var paymentMethodType: String {
        paymentMethodTokenData?.paymentInstrumentData?.paymentMethodType ?? "UNKNOWN"
    }
}

// swiftlint:enable type_name
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
