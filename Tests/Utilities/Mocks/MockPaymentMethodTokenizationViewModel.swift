//
//  MockPaymentMethodTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class MockPaymentMethodTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol {

    let config: PrimerPaymentMethod

    let uiManager: PrimerUIManaging

    let tokenizationService: TokenizationServiceProtocol

    var uiModule: UserInterfaceModule!
    var position: Int = 0
    var checkoutEventsNotifierModule: CheckoutEventsNotifierModule
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?

    var intent: PrimerSessionIntent?
    var validationError: Error?
    var tokenizationResult: (PrimerPaymentMethodTokenData?, Error?)?
    var paymentCreationDecision: PrimerPaymentCreationDecision?
    var paymentResult: (PrimerCheckoutData?, Error?)?

    convenience init(config: PrimerPaymentMethod) {
        self.init(config: config,
                  uiManager: PrimerUIManager.shared,
                  tokenizationService: TokenizationService())
    }

    required init(config: PrimerPaymentMethod,
                  uiManager: PrimerUIManaging,
                  tokenizationService: TokenizationServiceProtocol) {
        self.config = config
        self.uiManager = uiManager
        self.tokenizationService = tokenizationService
        self.checkoutEventsNotifierModule = CheckoutEventsNotifierModule()
    }

    convenience init(
        config: PrimerPaymentMethod,
        intent: PrimerSessionIntent,
        validationError: Error?,
        tokenizationResult: (PrimerPaymentMethodTokenData?, Error?),
        paymentCreationDecision: PrimerPaymentCreationDecision,
        paymentResult: (PrimerCheckoutData?, Error?)
    ) {
        self.init(config: config)
        PrimerInternal.shared.intent = intent
        self.validationError = validationError
        self.tokenizationResult = tokenizationResult
        self.paymentCreationDecision = paymentCreationDecision
        self.paymentResult = paymentResult
    }

    func validate() throws {
        if let validationError = validationError {
            throw validationError
        }
    }

    func start() {
        firstly {
            self.startTokenizationFlow()
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData

            if PrimerInternal.shared.intent == .vault {
                DispatchQueue.main.async{
                    self.handleSuccessfulFlow()
                }
            } else {
                self.didStartPayment?()
                self.didStartPayment = nil

                firstly {
                    self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
                }
                .done { _ in
                    self.didFinishPayment?(nil)
                    self.nullifyEventCallbacks()
                    DispatchQueue.main.async {
                        self.handleSuccessfulFlow()
                    }
                }
                .catch { err in
                    self.didFinishPayment?(err)
                    self.nullifyEventCallbacks()
                    XCTAssert(false, err.localizedDescription)
                }
            }
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
    }

    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                return self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                return self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(self.paymentMethodTokenData!)
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
        return paymentMethodTokenData!
    }

    func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            //            .then { () -> Promise<Void> in
            //                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            //                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            //            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
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
        try validate()
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

            firstly {
                self.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
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
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        let paymentMethodTokenData = try await tokenize()
        self.paymentMethodTokenData = paymentMethodTokenData
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise()
    }

    func performPostTokenizationSteps() async throws {}

    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let tokenizationResult = tokenizationResult,
                  tokenizationResult.0 != nil || tokenizationResult.1 != nil else {
                XCTAssert(false, "Set 'tokenizationResult' on your MockPaymentMethodTokenizationViewModel")
                return
            }

            if let err = tokenizationResult.1 {
                seal.reject(err)
            } else if let res = tokenizationResult.0 {
                seal.fulfill(res)
            }
        }
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let tokenizationResult = tokenizationResult,
              tokenizationResult.0 != nil || tokenizationResult.1 != nil else {
            XCTAssert(false, "Set 'tokenizationResult' on your MockPaymentMethodTokenizationViewModel")
            throw PrimerError.invalidValue(key: "tokenizationResult",
                                           value: nil,
                                           userInfo: .errorUserInfoDictionary(),
                                           diagnosticsId: UUID().uuidString)
        }

        if let err = tokenizationResult.1 {
            throw err
        } else if let res = tokenizationResult.0 {
            return res
        } else {
            throw PrimerError.invalidValue(key: "tokenizationResult",
                                           value: nil,
                                           userInfo: .errorUserInfoDictionary(),
                                           diagnosticsId: UUID().uuidString)
        }
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        return self.handleResumeStepsBasedOnSDKSettings(resumeToken: "mock_resume_token")
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        return try await handleResumeStepsBasedOnSDKSettings(resumeToken: "mock_resume_token")
    }

    func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Timer.delay(2)
    }

    func presentPaymentMethodUserInterface() async throws {
        try await Timer.delay(2)
    }

    func awaitUserInput() -> Promise<Void> {
        return Timer.delay(2)
    }

    func awaitUserInput() async throws {
        try await Timer.delay(2)
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken, paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in
            seal.fulfill("mock_resume_token")
        }
    }

    func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        return "mock_resume_token"
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            guard let paymentResult = paymentResult,
                  paymentResult.0 != nil || paymentResult.1 != nil else {
                XCTAssert(false, "Set 'paymentResult' on your MockPaymentMethodTokenizationViewModel")
                return
            }

            if let err = paymentResult.1 {
                seal.reject(err)
            } else if let res = paymentResult.0 {
                seal.fulfill(res)
            }
        }
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        guard let paymentResult = paymentResult,
              paymentResult.0 != nil || paymentResult.1 != nil else {
            XCTAssert(false, "Set 'paymentResult' on your MockPaymentMethodTokenizationViewModel")
            throw PrimerError.invalidValue(key: "paymentResult",
                                           value: nil,
                                           userInfo: .errorUserInfoDictionary(),
                                           diagnosticsId: UUID().uuidString)
        }

        if let err = paymentResult.1 {
            throw err
        } else if let res = paymentResult.0 {
            return res
        } else {
            throw PrimerError.invalidValue(key: "paymentResult",
                                           value: nil,
                                           userInfo: .errorUserInfoDictionary(),
                                           diagnosticsId: UUID().uuidString)
        }
    }

    @MainActor
    func handleSuccessfulFlow() {}

    @MainActor
    func handleFailureFlow(errorMessage: String?) {}

    func submitButtonTapped() {}

    func cancel() {}

    private func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            do {
                try self.validate()
                seal.fulfill()
            } catch {
                seal.reject(error)
            }
        }
    }

    private func validateReturningPromise() async throws {
        try validate()
    }

    private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                seal.fulfill()
            } else {
                guard let paymentCreationDecision = paymentCreationDecision else {
                    XCTAssert(false, "Set 'mockPaymentCreationDecision' on your MockPaymentMethodTokenizationViewModel")
                    return
                }

                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: nil,
                                                              diagnosticsId: UUID().uuidString)
                        seal.reject(error)
                    case .continue:
                        seal.fulfill()
                    }
                }
            }
        }
    }

    private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        guard PrimerInternal.shared.intent != .vault else {
            return
        }

        guard let paymentCreationDecision = paymentCreationDecision else {
            XCTAssert(false, "Set 'mockPaymentCreationDecision' on your MockPaymentMethodTokenizationViewModel")
            throw PrimerError.invalidValue(key: "paymentCreationDecision",
                                           value: nil,
                                           userInfo: .errorUserInfoDictionary(),
                                           diagnosticsId: UUID().uuidString)
        }

        return try await withCheckedThrowingContinuation { continuation in
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                switch paymentCreationDecision.type {
                case .abort(let errorMessage):
                    let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: nil,
                                                          diagnosticsId: UUID().uuidString)
                    continuation.resume(throwing: error)
                case .continue:
                    continuation.resume()
                }
            }
        }
    }

    private func nullifyEventCallbacks() {
        self.didStartPayment = nil
        self.didFinishPayment = nil
    }
}
