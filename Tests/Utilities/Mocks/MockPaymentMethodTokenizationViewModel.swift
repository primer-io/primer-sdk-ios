//
//  MockPaymentMethodTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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
        Task {
            do {
                let paymentMethodTokenData = try await startTokenizationFlow()
                self.paymentMethodTokenData = paymentMethodTokenData
                if PrimerInternal.shared.intent == .vault {
                    DispatchQueue.main.async {
                        self.handleSuccessfulFlow()
                    }
                } else {
                    self.didStartPayment?()
                    self.didStartPayment = nil

                    do {
                        try await self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
                        self.didFinishPayment?(nil)
                        self.nullifyEventCallbacks()
                        DispatchQueue.main.async {
                            self.handleSuccessfulFlow()
                        }
                    } catch {
                        self.didFinishPayment?(error)
                        self.nullifyEventCallbacks()
                        XCTAssert(false, error.localizedDescription)
                    }
                }
            } catch {
                XCTAssert(false, error.localizedDescription)
            }
        }
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        try await performPreTokenizationSteps()
        try await performTokenizationStep()
        try await performPostTokenizationSteps()
        return paymentMethodTokenData!
    }

    func performPreTokenizationSteps() async throws {
        try validate()
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        let paymentMethodTokenData = try await tokenize()
        self.paymentMethodTokenData = paymentMethodTokenData
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    func performPostTokenizationSteps() async throws {}

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let tokenizationResult = tokenizationResult,
              tokenizationResult.0 != nil || tokenizationResult.1 != nil else {
            XCTAssert(false, "Set 'tokenizationResult' on your MockPaymentMethodTokenizationViewModel")
            throw PrimerError.invalidValue(key: "tokenizationResult")
        }

        if let err = tokenizationResult.1 {
            throw err
        } else if let res = tokenizationResult.0 {
            return res
        } else {
            throw PrimerError.invalidValue(key: "tokenizationResult")
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        try await handleResumeStepsBasedOnSDKSettings(resumeToken: "mock_resume_token")
    }

    func presentPaymentMethodUserInterface() async throws {
        try await Timer.delay(2)
    }

    func awaitUserInput() async throws {
        try await Timer.delay(2)
    }

    func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        "mock_resume_token"
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        guard let paymentResult = paymentResult,
              paymentResult.0 != nil || paymentResult.1 != nil else {
            XCTAssert(false, "Set 'paymentResult' on your MockPaymentMethodTokenizationViewModel")
            throw PrimerError.invalidValue(key: "paymentResult")
        }

        if let err = paymentResult.1 {
            throw err
        } else if let res = paymentResult.0 {
            return res
        } else {
            throw PrimerError.invalidValue(key: "paymentResult")
        }
    }

    @MainActor
    func handleSuccessfulFlow() {}

    @MainActor
    func handleFailureFlow(errorMessage: String?) {}

    func submitButtonTapped() {}

    func cancel() {}

    private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        guard PrimerInternal.shared.intent != .vault else {
            return
        }

        guard let paymentCreationDecision = paymentCreationDecision else {
            XCTAssert(false, "Set 'mockPaymentCreationDecision' on your MockPaymentMethodTokenizationViewModel")
            throw PrimerError.invalidValue(key: "paymentCreationDecision")
        }

        return try await withCheckedThrowingContinuation { continuation in
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                switch paymentCreationDecision.type {
                case let .abort(errorMessage):
                    let error = PrimerError.merchantError(message: errorMessage ?? "")
                    continuation.resume(throwing: error)
                case let .continue(idempotencyKey):
                    PrimerInternal.shared.currentIdempotencyKey = idempotencyKey
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
