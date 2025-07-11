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
    private var klarnaPaymentSessionCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
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
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(false)
            }
        }

        checkoutEventsNotifierModule.didFinishTokenization = {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

        didStartPayment = {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(false)
            }
        }

        didFinishPayment = { _ in
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

        super.start()
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
        guard let authorizationToken else {
            let err = PrimerError.invalidValue(
                key: "authorizationToken",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }

        try await Analytics.Service.record(event: Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
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
        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
        self.klarnaPaymentSession = try await tokenizationComponent.createPaymentSession()
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
        self.klarnaCustomerTokenAPIResponse = try await tokenizationComponent.authorizePaymentSession(authorizationToken: authorizationToken)

        await MainActor.run {
            self.willDismissExternalView?()
        }

        self.willDismissExternalView?()
        #else
        let error = KlarnaHelpers.getMissingSDKError()
        ErrorHandler.handle(error: error)
        throw error
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
            let err = PrimerError.invalidValue(
                key: "authorizationToken",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }

        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        self.paymentMethodTokenData = try await tokenizationComponent.tokenizeDropIn(
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
            self.klarnaPaymentSessionCompletion = { authorizationToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let authorizationToken = authorizationToken {
                    self.authorizationToken = authorizationToken
                    seal.fulfill()
                } else {
                    precondition(false, "Should never end up in here")
                }
            }
        }
    }

    override func awaitUserInput() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.klarnaPaymentSessionCompletion = { authorizationToken, err in
                if let err {
                    continuation.resume(throwing: err)
                } else if let authorizationToken {
                    self.authorizationToken = authorizationToken
                    continuation.resume()
                } else {
                    preconditionFailure("Should never end up in here")
                }
            }
        }
    }

}

#if canImport(PrimerKlarnaSDK)
extension KlarnaTokenizationViewModel: PrimerKlarnaCategoriesDelegate {
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String) {
        klarnaPaymentSessionCompletion?(authorizationToken, nil)
    }

    func primerKlarnaPaymentSessionFailed(error: Error) {
        klarnaPaymentSessionCompletion?(nil, error)
    }
}
#endif
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
