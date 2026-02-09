//
//  PayPalTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import AuthenticationServices
import SafariServices
import UIKit

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
        didPresentExternalView = { [weak self] in
            guard let self else { return }
            Task { await PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type) }
        }

        super.start()
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

        let imageView = await uiModule.makeIconImageView(withDimension: 24.0)
        await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
            imageView: imageView,
            message: nil
        )

        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    override func presentPaymentMethodUserInterface() async throws {
        let url = try await fetchOAuthURL()
        willPresentExternalView?()
        _ = try await createOAuthSession(url)
        didPresentExternalView?()
    }

    override func awaitUserInput() async throws {
        payPalInstrument = try await createPaypalPaymentInstrument()
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

    private func createOAuthSession(_ url: URL) async throws -> URL {
        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        let oauthUrl = try await webAuthenticationService.connect(paymentMethodType: config.type, url: url, scheme: scheme)
        webAuthenticationService.session?.cancel()
        return oauthUrl
    }

    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
        try await payPalService.fetchPayPalExternalPayerInfo(orderId: orderId)
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

    private func generateBillingAgreementConfirmation() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        do {
            confirmBillingAgreementResponse = try await payPalService.confirmBillingAgreement()
            return confirmBillingAgreementResponse!
        } catch {
            throw handled(primerError: .failedToCreateSession(error: error))
        }
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
