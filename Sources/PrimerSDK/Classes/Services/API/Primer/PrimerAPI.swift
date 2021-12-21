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
    case fetchVaultedPaymentMethods(clientToken: DecodedClientToken)
    case deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String)

    case createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest)
    case createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest)
    case createPayPalSBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest)
    case confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest)
    case createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest)
    case createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest)
    case finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest)
    case createApayaSession(clientToken: DecodedClientToken, request: Apaya.CreateSessionAPIRequest)
    case tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest)
    case listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest)
    
    // 3DS
    case begin3DSRemoteAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest)
    case continue3DSRemoteAuth(clientToken: DecodedClientToken, threeDSTokenId: String)
    
    // Generic
    case poll(clientToken: DecodedClientToken?, url: String)
}

internal extension PrimerAPI {
    
    static var headers: [String: String] = [
        "Content-Type": "application/json",
        "Primer-SDK-Version": Bundle.primerFramework.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "n/a",
        "Primer-SDK-Client": "IOS_NATIVE"
    ]

    // MARK: Base URL
    var baseURL: String? {
        switch self {
        case .createDirectDebitMandate(let clientToken, _),
             .createPayPalOrderSession(let clientToken, _),
             .createPayPalSBillingAgreementSession(let clientToken, _),
             .confirmPayPalBillingAgreement(let clientToken, _),
             .createKlarnaPaymentSession(let clientToken, _),
             .createKlarnaCustomerToken(let clientToken, _),
             .finalizeKlarnaPaymentSession(let clientToken, _),
             .createApayaSession(let clientToken, _),
             .listAdyenBanks(let clientToken, _):
            guard let urlStr = clientToken.coreUrl else { return nil }
            return urlStr
        case .deleteVaultedPaymentMethod(let clientToken, _),
             .fetchVaultedPaymentMethods(let clientToken),
             .tokenizePaymentMethod(let clientToken, _),
             .begin3DSRemoteAuth(let clientToken, _, _),
             .continue3DSRemoteAuth(let clientToken, _):
            guard let urlStr = clientToken.pciUrl else { return nil }
            return urlStr
        case .fetchConfiguration(let clientToken):
            guard let urlStr = clientToken.configurationUrl else { return nil }
            return urlStr
        case .poll(_, let url):
            return url
        }
    }
    // MARK: Path
    
    var path: String {
        switch self {
        case .deleteVaultedPaymentMethod(_, let id):
            return "/payment-instruments/\(id)/vault"
        case .fetchConfiguration:
            return ""
        case .fetchVaultedPaymentMethods:
            return "/payment-instruments"
        case .createPayPalOrderSession:
            return "/paypal/orders/create"
        case .createPayPalSBillingAgreementSession:
            return "/paypal/billing-agreements/create-agreement"
        case .confirmPayPalBillingAgreement:
            return "/paypal/billing-agreements/confirm-agreement"
        case .createKlarnaPaymentSession:
            return "/klarna/payment-sessions"
        case .createKlarnaCustomerToken:
            return "/klarna/customer-tokens"
        case .finalizeKlarnaPaymentSession:
            return "/klarna/payment-sessions/finalize"
        case .createDirectDebitMandate:
            return "/gocardless/mandates"
        case .tokenizePaymentMethod:
            return "/payment-instruments"
        case .begin3DSRemoteAuth(_, let paymentMethodToken, _):
            return "/3ds/\(paymentMethodToken.token)/auth"
        case .continue3DSRemoteAuth(_, let threeDSTokenId):
            return "/3ds/\(threeDSTokenId)/continue"
        case .createApayaSession:
            return "/session-token"
        case .listAdyenBanks:
            return "/adyen/checkout"
        case .poll:
            return ""
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
        case .deleteVaultedPaymentMethod:
            return .delete
        case .fetchConfiguration,
             .fetchVaultedPaymentMethods:
            return .get
        case .createDirectDebitMandate,
             .createPayPalOrderSession,
             .createPayPalSBillingAgreementSession,
             .confirmPayPalBillingAgreement,
             .createKlarnaPaymentSession,
             .createKlarnaCustomerToken,
             .finalizeKlarnaPaymentSession,
             .tokenizePaymentMethod,
             .begin3DSRemoteAuth,
             .continue3DSRemoteAuth,
             .createApayaSession,
             .listAdyenBanks:
            return .post
        case .poll(_, let url):
            return .get
        }
    }

    // MARK: Headers
    
    var headers: [String: String]? {
        var tmpHeaders = PrimerAPI.headers
        
        switch self {
        case .createDirectDebitMandate(let clientToken, _),
             .deleteVaultedPaymentMethod(let clientToken, _),
             .fetchVaultedPaymentMethods(let clientToken),
             .createPayPalOrderSession(let clientToken, _),
             .createPayPalSBillingAgreementSession(let clientToken, _),
             .confirmPayPalBillingAgreement(let clientToken, _),
             .createKlarnaPaymentSession(let clientToken, _),
             .createKlarnaCustomerToken(let clientToken, _),
             .finalizeKlarnaPaymentSession(let clientToken, _),
             .tokenizePaymentMethod(let clientToken, _),
             .begin3DSRemoteAuth(let clientToken, _, _),
             .continue3DSRemoteAuth(let clientToken, _),
             .createApayaSession(let clientToken, _),
             .listAdyenBanks(let clientToken, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
        case .fetchConfiguration(let clientToken):
            tmpHeaders["X-Api-Version"] = "2021-10-19"
            
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
            
        case .poll(let clientToken, _):
            if let token = clientToken?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
        }
        
        switch self {
        case .fetchConfiguration:
            tmpHeaders["X-Api-Version"] = "2021-10-19"
        default:
            break
        }

        return tmpHeaders
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
        case .createDirectDebitMandate(_, let mandateRequest):
            return try? JSONEncoder().encode(mandateRequest)
        case .createPayPalOrderSession(_, let payPalCreateOrderRequest):
            return try? JSONEncoder().encode(payPalCreateOrderRequest)
        case .createPayPalSBillingAgreementSession(_, let payPalCreateBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalCreateBillingAgreementRequest)
        case .confirmPayPalBillingAgreement(_, let payPalConfirmBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalConfirmBillingAgreementRequest)
        case .createKlarnaPaymentSession(_, let klarnaCreatePaymentSessionAPIRequest):
            return try? JSONEncoder().encode(klarnaCreatePaymentSessionAPIRequest)
        case .createKlarnaCustomerToken(_, let klarnaCreateCustomerTokenAPIRequest):
            return try? JSONEncoder().encode(klarnaCreateCustomerTokenAPIRequest)
        case .finalizeKlarnaPaymentSession(_, let klarnaFinalizePaymentSessionRequest):
            return try? JSONEncoder().encode(klarnaFinalizePaymentSessionRequest)
        case .createApayaSession(_, let request):
            return try? JSONEncoder().encode(request)
        case .tokenizePaymentMethod(_, let paymentMethodTokenizationRequest):
            if let request = paymentMethodTokenizationRequest as? PaymentMethodTokenizationRequest {
                return try? JSONEncoder().encode(request)
            } else if let request = paymentMethodTokenizationRequest as? AsyncPaymentMethodTokenizationRequest {
                return try? JSONEncoder().encode(request)
            } else if let request = paymentMethodTokenizationRequest as? BankSelectorTokenizationRequest {
                return try? JSONEncoder().encode(request)
            } else {
                return nil
            }
        case .begin3DSRemoteAuth(_, _, let threeDSecureBeginAuthRequest):
            return try? JSONEncoder().encode(threeDSecureBeginAuthRequest)
        case .listAdyenBanks(_, let request):
            return try? JSONEncoder().encode(request)
        case .deleteVaultedPaymentMethod,
             .fetchConfiguration,
             .fetchVaultedPaymentMethods,
             .continue3DSRemoteAuth,
             .poll:
            return nil
        }
    }

}

#endif
