//
//  PayPalRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Implementation of PayPalRepository that wraps the existing PayPalService and WebAuthenticationService.
@available(iOS 15.0, *)
final class PayPalRepositoryImpl: PayPalRepository, LogReporter {

    private let payPalService: PayPalServiceProtocol
    private let webAuthService: WebAuthenticationService
    private let tokenizationService: TokenizationServiceProtocol

    init(
        payPalService: PayPalServiceProtocol = PayPalService(),
        webAuthService: WebAuthenticationService = DefaultWebAuthenticationService(),
        tokenizationService: TokenizationServiceProtocol = TokenizationService()
    ) {
        self.payPalService = payPalService
        self.webAuthService = webAuthService
        self.tokenizationService = tokenizationService
    }

    func startOrderSession() async throws -> (orderId: String, approvalUrl: String) {
        let response = try await payPalService.startOrderSession()
        return (orderId: response.orderId, approvalUrl: response.approvalUrl)
    }

    func startBillingAgreementSession() async throws -> String {
        try await payPalService.startBillingAgreementSession()
    }

    func openWebAuthentication(url: URL) async throws -> URL {
        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        return try await webAuthService.connect(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            url: url,
            scheme: scheme
        )
    }

    func confirmBillingAgreement() async throws -> PayPalBillingAgreementResult {
        let response = try await payPalService.confirmBillingAgreement()
        return PayPalBillingAgreementResult(
            billingAgreementId: response.billingAgreementId,
            externalPayerInfo: mapPayerInfo(response.externalPayerInfo),
            shippingAddress: mapShippingAddress(response.shippingAddress)
        )
    }

    func fetchPayerInfo(orderId: String) async throws -> PayPalPayerInfo {
        let response = try await payPalService.fetchPayPalExternalPayerInfo(orderId: orderId)
        return mapPayerInfo(response.externalPayerInfo) ?? PayPalPayerInfo(
            externalPayerId: nil,
            email: nil,
            firstName: nil,
            lastName: nil
        )
    }

    func tokenize(paymentInstrument: PayPalPaymentInstrumentData) async throws -> PaymentResult {
        let instrument = createPaymentInstrument(from: paymentInstrument)
        let requestBody = Request.Body.Tokenization(paymentInstrument: instrument)
        let tokenData = try await tokenizationService.tokenize(requestBody: requestBody)

        return PaymentResult(
            paymentId: tokenData.id ?? UUID().uuidString,
            status: .success,
            token: tokenData.token,
            amount: nil,
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue
        )
    }

    // MARK: - Private Helpers

    private func createPaymentInstrument(from data: PayPalPaymentInstrumentData) -> PayPalPaymentInstrument {
        switch data {
        case let .order(orderId, payerInfo):
            return PayPalPaymentInstrument(
                paypalOrderId: orderId,
                paypalBillingAgreementId: nil,
                shippingAddress: nil,
                externalPayerInfo: mapToExternalPayerInfo(payerInfo)
            )
        case let .billingAgreement(result):
            return PayPalPaymentInstrument(
                paypalOrderId: nil,
                paypalBillingAgreementId: result.billingAgreementId,
                shippingAddress: mapToShippingAddress(result.shippingAddress),
                externalPayerInfo: mapToExternalPayerInfo(result.externalPayerInfo)
            )
        }
    }

    private func mapPayerInfo(_ info: Response.Body.Tokenization.PayPal.ExternalPayerInfo?) -> PayPalPayerInfo? {
        guard let info else { return nil }
        return PayPalPayerInfo(
            externalPayerId: info.externalPayerId,
            email: info.email,
            firstName: info.firstName,
            lastName: info.lastName
        )
    }

    private func mapShippingAddress(_ address: Response.Body.Tokenization.PayPal.ShippingAddress?) -> PayPalShippingAddress? {
        guard let address else { return nil }
        return PayPalShippingAddress(
            firstName: address.firstName,
            lastName: address.lastName,
            addressLine1: address.addressLine1,
            addressLine2: address.addressLine2,
            city: address.city,
            state: address.state,
            countryCode: address.countryCode,
            postalCode: address.postalCode
        )
    }

    private func mapToExternalPayerInfo(_ info: PayPalPayerInfo?) -> Response.Body.Tokenization.PayPal.ExternalPayerInfo? {
        guard let info else { return nil }
        return Response.Body.Tokenization.PayPal.ExternalPayerInfo(
            externalPayerId: info.externalPayerId ?? "",
            email: info.email ?? "",
            firstName: info.firstName,
            lastName: info.lastName ?? ""
        )
    }

    private func mapToShippingAddress(_ address: PayPalShippingAddress?) -> Response.Body.Tokenization.PayPal.ShippingAddress? {
        guard let address else { return nil }
        return Response.Body.Tokenization.PayPal.ShippingAddress(
            firstName: address.firstName,
            lastName: address.lastName,
            addressLine1: address.addressLine1,
            addressLine2: address.addressLine2,
            city: address.city,
            state: address.state,
            countryCode: address.countryCode,
            postalCode: address.postalCode
        )
    }
}
