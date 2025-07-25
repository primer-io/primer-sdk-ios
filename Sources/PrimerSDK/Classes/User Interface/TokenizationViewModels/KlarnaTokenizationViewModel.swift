//
//  KlarnaTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import UIKit

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

// MARK: MISSING_TESTS
final class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel {

    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?

    private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    private let tokenizationComponent: KlarnaTokenizationComponentProtocol
    private var klarnaPaymentSession: Response.Body.Klarna.PaymentSession?
    private var klarnaCustomerTokenAPIResponse: Response.Body.Klarna.CustomerToken?
    private var klarnaPaymentSessionCompletion: ((Result<String, Error>) -> Void)?
    private var authorizationToken: String?

    override init(config: PrimerPaymentMethod,
                  uiManager: PrimerUIManaging,
                  tokenizationService: TokenizationServiceProtocol,
                  createResumePaymentService: CreateResumePaymentServiceProtocol) {
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: config)
        super.init(config: config,
                   uiManager: uiManager,
                   tokenizationService: tokenizationService,
                   createResumePaymentService: createResumePaymentService)
    }

    override func validate() throws {
        try tokenizationComponent.validate()
    }

    override func start() {
        checkoutEventsNotifierModule.didStartTokenization = {
            self.enableUserInteraction(false)
        }

        checkoutEventsNotifierModule.didFinishTokenization = {
            self.enableUserInteraction(true)
        }

        didStartPayment = {
            self.enableUserInteraction(false)
        }

        didFinishPayment = { _ in
            self.enableUserInteraction(true)
        }

        super.start()
    }

    override func start_async() {
        checkoutEventsNotifierModule.didStartTokenization = {
            self.enableUserInteraction(false)
        }

        checkoutEventsNotifierModule.didFinishTokenization = {
            self.enableUserInteraction(true)
        }

        didStartPayment = {
            self.enableUserInteraction(false)
        }

        didFinishPayment = { _ in
            self.enableUserInteraction(true)
        }

        super.start_async()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .paymentMethodPopup
        )
        Analytics.Service.record(event: event)

        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

        return Promise { seal in
            #if canImport(PrimerKlarnaSDK)
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Response.Body.Klarna.PaymentSession> in
                return self.tokenizationComponent.createPaymentSession()
            }
            .then { session -> Promise<Void> in
                self.klarnaPaymentSession = session
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Response.Body.Klarna.CustomerToken> in
                return self.tokenizationComponent.authorizePaymentSession(authorizationToken: self.authorizationToken!)
            }
            .done { klarnaCustomerTokenAPIResponse in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                DispatchQueue.main.async {
                    self.willDismissExternalView?()
                }

                seal.fulfill()
            }
            .ensure {
                self.willDismissExternalView?()
            }
            .catch { err in
                seal.reject(err)
            }
            #else
            seal.reject(handled(error: KlarnaHelpers.getMissingSDKError()))
            #endif
        }
    }

    override func performPreTokenizationSteps() async throws {
        Analytics.Service.fire(event: Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: config.type,
                url: nil
            ),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .paymentMethodPopup
        ))

        await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

        #if canImport(PrimerKlarnaSDK)

        defer {
            Task { @MainActor in
                self.willDismissExternalView?()
            }
        }

        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)
        klarnaPaymentSession = try await tokenizationComponent.createPaymentSession()
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()

        guard let authorizationToken else {
            throw handled(primerError: .invalidValue(key: "authorizationToken"))
        }

        klarnaCustomerTokenAPIResponse = try await tokenizationComponent.authorizePaymentSession(authorizationToken: authorizationToken)
        #else
        throw handled(primerError: KlarnaHelpers.getMissingSDKError())
        #endif
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                let customerToken = self.klarnaCustomerTokenAPIResponse
                return self.tokenizationComponent.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: self.authorizationToken!)
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

    override func performTokenizationStep() async throws {
        guard let authorizationToken else {
            throw handled(primerError: .invalidValue(key: "authorizationToken"))
        }

        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenizationComponent.tokenizeDropIn(
            customerToken: klarnaCustomerTokenAPIResponse,
            offSessionAuthorizationId: authorizationToken
        )
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                #if canImport(PrimerKlarnaSDK)
                do {
                    _ = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
                } catch let error {
                    seal.reject(error)
                    return
                }

                let categoriesViewController = PrimerKlarnaCategoriesViewController(tokenizationComponent: self.tokenizationComponent, delegate: self)

                self.willPresentExternalView?()
                PrimerUIManager.primerRootViewController?.show(viewController: categoriesViewController)
                self.didPresentExternalView?()
                seal.fulfill()
                #else
                seal.fulfill()
                #endif
            }
        }
    }

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        #if canImport(PrimerKlarnaSDK)
        _ = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        let categoriesViewController = PrimerKlarnaCategoriesViewController(tokenizationComponent: tokenizationComponent, delegate: self)
        willPresentExternalView?()
        PrimerUIManager.primerRootViewController?.show(viewController: categoriesViewController)
        didPresentExternalView?()
        #endif
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.klarnaPaymentSessionCompletion = { result in
                switch result {
                case .success(let authorizationToken):
                    self.authorizationToken = authorizationToken
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    override func awaitUserInput() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.klarnaPaymentSessionCompletion = { result in
                switch result {
                case .success(let authorizationToken):
                    self.authorizationToken = authorizationToken
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: Private helper methods
    
    private func enableUserInteraction(_ enable: Bool) {
        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(enable)
        }
    }
}

#if canImport(PrimerKlarnaSDK)
extension KlarnaTokenizationViewModel: PrimerKlarnaCategoriesDelegate {
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String) {
        klarnaPaymentSessionCompletion?(.success(authorizationToken))
    }

    func primerKlarnaPaymentSessionFailed(error: Error) {
        klarnaPaymentSessionCompletion?(.failure(error))
    }
}
#endif
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
