//
//  PayPalTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import UIKit
import AuthenticationServices
import SafariServices

final class PayPalTokenizationViewModel: PaymentMethodTokenizationViewModel {

    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?

    private var payPalUrl: URL!
    private var payPalInstrument: PayPalPaymentInstrument!
    private var session: Any!
    private var orderId: String?
    private var confirmBillingAgreementResponse: Response.Body.PayPal.ConfirmBillingAgreement?

    lazy var webAuthenticationService: WebAuthenticationService = {
        DefaultWebAuthenticationService()
    }()

    lazy var payPalService: PayPalServiceProtocol = {
        PayPalService()
    }()

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard decodedJWTToken.pciUrl != nil else {
            throw handled(primerError: .invalidValue(key: "decodedClientToken.pciUrl"))
        }

        guard config.id != nil else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        guard decodedJWTToken.coreUrl != nil else {
            throw handled(primerError: .invalidValue(key: "decodedClientToken.coreUrl"))
        }
    }

    override func start() {
        self.didPresentExternalView = { [weak self] in
            if let strongSelf = self {
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: strongSelf.config.type)
            }
        }

        super.start()
    }

    override func start_async() {
        didPresentExternalView = { [weak self] in
            guard let self else { return }
            Task { await PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type) }
        }

        super.start_async()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {

        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
        }

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

        let imageView = self.uiModule.makeIconImageView(withDimension: 24.0)
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView,
                                                                            message: nil)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<Void> in
                self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performPreTokenizationSteps() async throws {
        await PrimerUIManager.primerRootViewController?.enableUserInteraction(false)

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

        await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
            imageView: uiModule.makeIconImageView(withDimension: 24.0),
            message: nil
        )

        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
    }

    override func performTokenizationStep() -> Promise<Void> {
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

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
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
            firstly {
                self.fetchOAuthURL()
            }
            .then { url -> Promise<URL> in
                self.willPresentExternalView?()
                return self.createOAuthSession(url)
            }
            .done { _  in
                self.didPresentExternalView?()
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func presentPaymentMethodUserInterface() async throws {
        let url = try await fetchOAuthURL()
        willPresentExternalView?()
        _ = try await createOAuthSession(url)
        didPresentExternalView?()
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.createPaypalPaymentInstrument()
            }
            .done { instrument in
                self.payPalInstrument = instrument
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func awaitUserInput() async throws {
        payPalInstrument = try await createPaypalPaymentInstrument()
    }

    private func fetchOAuthURL() -> Promise<URL> {
        return Promise { seal in

            switch PrimerInternal.shared.intent {
            case .checkout:
                payPalService.startOrderSession { result in
                    switch result {
                    case .success(let res):
                        guard let url = URL(string: res.approvalUrl) else {
                            return seal.reject(
                                handled(
                                    primerError: .invalidValue(
                                        key: "res.approvalUrl",
                                        value: res.approvalUrl
                                    )
                                )
                            )
                        }

                        self.orderId = res.orderId
                        seal.fulfill(url)

                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .vault:
                payPalService.startBillingAgreementSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            let error = handled(primerError: .invalidValue(key: "billingAgreement.response.url", value: urlStr))
                            return seal.reject(error)
                        }

                        seal.fulfill(url)

                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .none:
                assert(true, "Intent should already be set")
            }
        }
    }

    private func fetchOAuthURL() async throws -> URL {
        switch PrimerInternal.shared.intent {
        case .checkout:
            let res = try await payPalService.startOrderSession()
            guard let url = URL(string: res.approvalUrl) else {
                throw handled(primerError: .invalidValue(key: "res.approvalUrl", value: res.approvalUrl))
            }
            self.orderId = res.orderId
            return url
        case .vault:
            let urlStr = try await payPalService.startBillingAgreementSession()

            guard let url = URL(string: urlStr) else {
                throw handled(primerError: .invalidValue(key: "billingAgreement.response.url", value: urlStr))
            }

            return url
        case .none:
            preconditionFailure("Intent should already be set")
        }
    }

    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            var scheme: String
            do {
                scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
            } catch let error {
                seal.reject(error)
                return
            }

            webAuthenticationService.connect(paymentMethodType: self.config.type, url: url, scheme: scheme) { [weak self] result in
                switch result {
                case .success(let url):
                    seal.fulfill(url)
                case .failure(let error):
                    seal.reject(error)
                }
                self?.webAuthenticationService.session?.cancel()
            }
        }
    }

    private func createOAuthSession(_ url: URL) async throws -> URL {
        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        let oauthUrl = try await webAuthenticationService.connect(paymentMethodType: config.type, url: url, scheme: scheme)
        webAuthenticationService.session?.cancel()
        return oauthUrl
    }

    func fetchPayPalExternalPayerInfo(orderId: String) -> Promise<Response.Body.PayPal.PayerInfo> {
        return Promise { seal in
            payPalService.fetchPayPalExternalPayerInfo(orderId: orderId) { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }

    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
        try await payPalService.fetchPayPalExternalPayerInfo(orderId: orderId)
    }

    private func createPaypalPaymentInstrument() -> Promise<PayPalPaymentInstrument> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                firstly {
                    self.generateBillingAgreementConfirmation()
                }
                .done { billingAgreement in
                    let paymentInstrument = PayPalPaymentInstrument(
                        paypalOrderId: nil,
                        paypalBillingAgreementId: billingAgreement.billingAgreementId,
                        shippingAddress: billingAgreement.shippingAddress,
                        externalPayerInfo: billingAgreement.externalPayerInfo)

                    seal.fulfill(paymentInstrument)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                guard let orderId else {
                    return seal.reject(handled(primerError: .invalidValue(key: "orderId")))
                }

                firstly {
                    self.fetchPayPalExternalPayerInfo(orderId: orderId)
                }
                .then { res -> Promise<PayPalPaymentInstrument> in
                    return self.generatePaypalPaymentInstrument(externalPayerInfo: res.externalPayerInfo)
                }
                .done { response in
                    self.generatePaypalPaymentInstrument(externalPayerInfo: response.externalPayerInfo) { result in
                        switch result {
                        case .success(let paymentInstrument):
                            seal.fulfill(paymentInstrument)
                        case .failure(let err):
                            seal.reject(err)
                        }
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }

        }
    }

    private func createPaypalPaymentInstrument() async throws -> PayPalPaymentInstrument {
        if PrimerInternal.shared.intent == .vault {
            let billingAgreement = try await generateBillingAgreementConfirmation()
            return PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: billingAgreement.billingAgreementId,
                shippingAddress: billingAgreement.shippingAddress,
                externalPayerInfo: billingAgreement.externalPayerInfo
            )
        } else {
            guard let orderId else {
                throw handled(primerError: .invalidValue(key: "orderId"))
            }

            let response = try await fetchPayPalExternalPayerInfo(orderId: orderId)

            // MARK: REVIEW_CHECK: Is this correct? because PromiseKit version is using 'generatePaypalPaymentInstrument' twice

            return try await generatePaypalPaymentInstrument(externalPayerInfo: response.externalPayerInfo)
        }
    }

    private func generatePaypalPaymentInstrument(externalPayerInfo: Response.Body.Tokenization.PayPal
        .ExternalPayerInfo?) -> Promise<PayPalPaymentInstrument> {
        return Promise { seal in
            self.generatePaypalPaymentInstrument(externalPayerInfo: externalPayerInfo) { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }

    private func generatePaypalPaymentInstrument(
        externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?
    ) async throws -> PayPalPaymentInstrument {
        switch PrimerInternal.shared.intent {
        case .checkout:
            guard let orderId else {
                throw handled(primerError: .invalidValue(key: "orderId"))
            }

            guard let externalPayerInfo else {
                throw handled(primerError: .invalidValue(key: "externalPayerInfo"))
            }

            return PayPalPaymentInstrument(
                paypalOrderId: orderId,
                paypalBillingAgreementId: nil,
                shippingAddress: nil,
                externalPayerInfo: externalPayerInfo
            )
        case .vault:
            guard let confirmBillingAgreementResponse else {
                throw handled(primerError: .invalidValue(key: "confirmedBillingAgreement"))
            }

            return PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: confirmBillingAgreementResponse.billingAgreementId,
                shippingAddress: confirmBillingAgreementResponse.shippingAddress,
                externalPayerInfo: confirmBillingAgreementResponse.externalPayerInfo
            )
        case .none:
            preconditionFailure("Intent should already be set")
        }
    }

    private func generatePaypalPaymentInstrument(externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?, completion: @escaping (Result<PayPalPaymentInstrument, Error>) -> Void) {
        switch PrimerInternal.shared.intent {
        case .checkout:
            guard let orderId else {
                return completion(.failure(handled(primerError: .invalidValue(key: "orderId"))))
            }

            guard let externalPayerInfo else {
                return completion(.failure(handled(primerError: .invalidValue(key: "externalPayerInfo"))))
            }

            let paymentInstrument = PayPalPaymentInstrument(
                paypalOrderId: orderId,
                paypalBillingAgreementId: nil,
                shippingAddress: nil,
                externalPayerInfo: externalPayerInfo
            )

            completion(.success(paymentInstrument))

        case .vault:
            guard let confirmBillingAgreementResponse else {
                return completion(.failure(handled(primerError: .invalidValue(key: "confirmedBillingAgreement"))))
            }

            let paymentInstrument = PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: confirmBillingAgreementResponse.billingAgreementId,
                shippingAddress: confirmBillingAgreementResponse.shippingAddress,
                externalPayerInfo: confirmBillingAgreementResponse.externalPayerInfo
            )

            completion(.success(paymentInstrument))

        case .none:
            assert(true, "Intent should have been set.")
        }
    }

    private func generateBillingAgreementConfirmation() -> Promise<Response.Body.PayPal.ConfirmBillingAgreement> {
        return Promise { seal in
            self.generateBillingAgreementConfirmation { [unowned self] (billingAgreementRes, err) in
                if let err = err {
                    seal.reject(err)
                } else if let billingAgreementRes = billingAgreementRes {
                    self.confirmBillingAgreementResponse = billingAgreementRes
                    seal.fulfill(billingAgreementRes)
                }
            }
        }
    }

    private func generateBillingAgreementConfirmation() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        do {
            confirmBillingAgreementResponse = try await payPalService.confirmBillingAgreement()
            return confirmBillingAgreementResponse!
        } catch {
            throw handled(primerError: .failedToCreateSession(error: error))
        }
    }

    private func generateBillingAgreementConfirmation(_ completion: @escaping (Response.Body.PayPal.ConfirmBillingAgreement?, Error?) -> Void) {

        payPalService.confirmBillingAgreement({ result in
            switch result {
            case .failure(let err):
                completion(nil, handled(primerError: .failedToCreateSession(error: err)))
            case .success(let res):
                self.confirmBillingAgreementResponse = res
                completion(res, nil)
            }
        })
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        let requestBody = Request.Body.Tokenization(paymentInstrument: self.payPalInstrument)
        return tokenizationService.tokenize(requestBody: requestBody)
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(paymentInstrument: payPalInstrument)
        )
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable function_body_length
// swiftlint:enable file_length
