//
//  PrimerAPI.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

enum PrimerAPI: Endpoint {
    case fetchConfiguration(clientToken: DecodedClientToken)
    case vaultFetchPaymentMethods(clientToken: DecodedClientToken)
    case vaultDeletePaymentMethod(clientToken: DecodedClientToken, id: String)

    case directDebitCreateMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest)
    case payPalStartOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest)
    case payPalStartBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest)
    case payPalConfirmBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest)
    case klarnaCreatePaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest)
    case klarnaCreateCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest)
    case klarnaFinalizePaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest)

    case tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: PaymentMethodTokenizationRequest)
    
    // 3DS
    case threeDSBeginRemoteAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest)
    case threeDSContinueRemoteAuth(clientToken: DecodedClientToken, threeDSTokenId: String)
}

internal extension PrimerAPI {

    // MARK: Base URL
    var baseURL: String? {
        switch self {
        case .directDebitCreateMandate(let clientToken, _),
             .payPalStartOrderSession(let clientToken, _),
             .payPalStartBillingAgreementSession(let clientToken, _),
             .payPalConfirmBillingAgreement(let clientToken, _),
             .klarnaCreatePaymentSession(let clientToken, _),
             .klarnaCreateCustomerToken(let clientToken, _),
             .klarnaFinalizePaymentSession(let clientToken, _):
            guard let urlStr = clientToken.coreUrl else { return nil }
            return urlStr
        case .vaultDeletePaymentMethod(let clientToken, _),
             .vaultFetchPaymentMethods(let clientToken),
             .tokenizePaymentMethod(let clientToken, _),
             .threeDSBeginRemoteAuth(let clientToken, _, _),
             .threeDSContinueRemoteAuth(let clientToken, _):
            guard let urlStr = clientToken.pciUrl else { return nil }
            return urlStr
        case .fetchConfiguration(let clientToken):
            guard let urlStr = clientToken.configurationUrl else { return nil }
            return urlStr
        }
    }

    // MARK: Path
    
    var path: String {
        switch self {
        case .vaultDeletePaymentMethod(_, let id):
            return "/payment-instruments/\(id)/vault"
        case .fetchConfiguration:
            return ""
        case .vaultFetchPaymentMethods:
            return "/payment-instruments"
        case .payPalStartOrderSession:
            return "/paypal/orders/create"
        case .payPalStartBillingAgreementSession:
            return "/paypal/billing-agreements/create-agreement"
        case .payPalConfirmBillingAgreement:
            return "/paypal/billing-agreements/confirm-agreement"
        case .klarnaCreatePaymentSession:
            return "/klarna/payment-sessions"
        case .klarnaCreateCustomerToken:
            return "/klarna/customer-tokens"
        case .klarnaFinalizePaymentSession:
            return "/klarna/payment-sessions/finalize"
        case .directDebitCreateMandate:
            return "/gocardless/mandates"
        case .tokenizePaymentMethod:
            return "/payment-instruments"
        case .threeDSBeginRemoteAuth(_, let paymentMethodToken, _):
            return "/3ds/\(paymentMethodToken.token!)/auth"
        case .threeDSContinueRemoteAuth(_, let threeDSTokenId):
            return "/3ds/\(threeDSTokenId)/continue"
        }
    }

    // MARK: Port
    // (not needed atm since port is included in the base URL provided by the access token)
    
    var port: Int? {
        return nil
    }

    // MARK: HTTP Method
    
    var method: HTTPMethod {
        switch self {
        case .vaultDeletePaymentMethod:
            return .delete
        case .fetchConfiguration,
             .vaultFetchPaymentMethods:
            return .get
        case .directDebitCreateMandate,
             .payPalStartOrderSession,
             .payPalStartBillingAgreementSession,
             .payPalConfirmBillingAgreement,
             .klarnaCreatePaymentSession,
             .klarnaCreateCustomerToken,
             .klarnaFinalizePaymentSession,
             .tokenizePaymentMethod,
             .threeDSBeginRemoteAuth,
             .threeDSContinueRemoteAuth:
            return .post
        }
    }

    // MARK: Headers
    
    var headers: [String: String]? {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "Primer-SDK-Version": "1.0.0-beta.0",
            "Primer-SDK-Client": "IOS_NATIVE"
        ]
        switch self {
        case .directDebitCreateMandate(let clientToken, _),
             .vaultDeletePaymentMethod(let clientToken, _),
             .fetchConfiguration(let clientToken),
             .vaultFetchPaymentMethods(let clientToken),
             .payPalStartOrderSession(let clientToken, _),
             .payPalStartBillingAgreementSession(let clientToken, _),
             .payPalConfirmBillingAgreement(let clientToken, _),
             .klarnaCreatePaymentSession(let clientToken, _),
             .klarnaCreateCustomerToken(let clientToken, _),
             .klarnaFinalizePaymentSession(let clientToken, _),
             .tokenizePaymentMethod(let clientToken, _),
             .threeDSBeginRemoteAuth(let clientToken, _, _),
             .threeDSContinueRemoteAuth(let clientToken, _):
            if let token = clientToken.accessToken {
                headers["Primer-Client-Token"] = token
            }
        }

        return headers
    }

    // MARK: Query Parameters
    
    var queryParameters: [String: String]? {
        switch self {
        default:
            return nil
        }
    }

    // MARK: HTTP Body
    
    var body: Data? {
        switch self {
        case .directDebitCreateMandate(_, let mandateRequest):
            return try? JSONEncoder().encode(mandateRequest)
        case .payPalStartOrderSession(_, let payPalCreateOrderRequest):
            return try? JSONEncoder().encode(payPalCreateOrderRequest)
        case .payPalStartBillingAgreementSession(_, let payPalCreateBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalCreateBillingAgreementRequest)
        case .payPalConfirmBillingAgreement(_, let payPalConfirmBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalConfirmBillingAgreementRequest)
        case .klarnaCreatePaymentSession(_, let klarnaCreatePaymentSessionAPIRequest):
            return try? JSONEncoder().encode(klarnaCreatePaymentSessionAPIRequest)
        case .klarnaCreateCustomerToken(_, let klarnaCreateCustomerTokenAPIRequest):
            return try? JSONEncoder().encode(klarnaCreateCustomerTokenAPIRequest)
        case .klarnaFinalizePaymentSession(_, let klarnaFinalizePaymentSessionRequest):
            return try? JSONEncoder().encode(klarnaFinalizePaymentSessionRequest)
        case .tokenizePaymentMethod(_, let paymentMethodTokenizationRequest):
            return try? JSONEncoder().encode(paymentMethodTokenizationRequest)
        case .threeDSBeginRemoteAuth(_, _, let threeDSecureBeginAuthRequest):
            return try? JSONEncoder().encode(threeDSecureBeginAuthRequest)
        case .vaultDeletePaymentMethod,
             .fetchConfiguration,
             .vaultFetchPaymentMethods,
             .threeDSContinueRemoteAuth:
            return nil
        }
    }

}

#endif
