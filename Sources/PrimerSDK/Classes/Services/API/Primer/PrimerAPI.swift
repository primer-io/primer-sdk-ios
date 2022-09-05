//
//  PrimerAPI.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

enum PrimerAPI: Endpoint, Equatable {
    
    static func == (lhs: PrimerAPI, rhs: PrimerAPI) -> Bool {
        switch (lhs, rhs) {
        case (.exchangePaymentMethodToken, .exchangePaymentMethodToken),
            (.fetchConfiguration, .fetchConfiguration),
            (.fetchVaultedPaymentMethods, .fetchVaultedPaymentMethods),
            (.deleteVaultedPaymentMethod, .deleteVaultedPaymentMethod),
            (.createPayPalOrderSession, .createPayPalOrderSession),
            (.createPayPalBillingAgreementSession, .createPayPalBillingAgreementSession),
            (.confirmPayPalBillingAgreement, .confirmPayPalBillingAgreement),
            (.createKlarnaPaymentSession, .createKlarnaPaymentSession),
            (.createKlarnaCustomerToken, .createKlarnaCustomerToken),
            (.finalizeKlarnaPaymentSession, .finalizeKlarnaPaymentSession),
            (.createApayaSession, .createApayaSession),
            (.tokenizePaymentMethod, .tokenizePaymentMethod),
            (.listAdyenBanks, .listAdyenBanks),
            (.begin3DSRemoteAuth, .begin3DSRemoteAuth),
            (.continue3DSRemoteAuth, .continue3DSRemoteAuth),
            (.poll, .poll),
            (.sendAnalyticsEvents, .sendAnalyticsEvents),
            (.createPayment, .createPayment),
            (.validateClientToken, .validateClientToken):
            return true
        default:
            return false
        }
    }
    

    case exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String)
    case fetchConfiguration(clientToken: DecodedClientToken, requestParameters: Request.URLParameters.Configuration?)
    case fetchVaultedPaymentMethods(clientToken: DecodedClientToken)
    case deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String)
    
//    case createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest)
    case createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder)
    case createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement)
    case confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement)
    case createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession)
    case createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken)
    case finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession)
    case createApayaSession(clientToken: DecodedClientToken, request: Request.Body.Apaya.CreateSession)
    case tokenizePaymentMethod(clientToken: DecodedClientToken, tokenizationRequestBody: Request.Body.Tokenization)
    case listAdyenBanks(clientToken: DecodedClientToken, request: Request.Body.Adyen.BanksList)

    case requestPrimerConfigurationWithActions(clientToken: DecodedClientToken, request: ClientSessionUpdateRequest)
    
    // 3DS
    case begin3DSRemoteAuth(clientToken: DecodedClientToken, paymentMethodToken: PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest)
    case continue3DSRemoteAuth(clientToken: DecodedClientToken, threeDSTokenId: String)
    
    // Generic
    case poll(clientToken: DecodedClientToken?, url: String)
    
    case sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?)
    
    case fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo)

    case validateClientToken(request: Request.Body.ClientTokenValidation)
    
    // Create - Resume Payment
    
    case createPayment(clientToken: DecodedClientToken, paymentRequest: Request.Body.Payment.Create)
    case resumePayment(clientToken: DecodedClientToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume)

}

internal extension PrimerAPI {
    
    // MARK: Headers
    
    static let headers: [String: String] = [
        "Content-Type": "application/json",
        "Primer-SDK-Version": Bundle.primerFramework.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "n/a",
        "Primer-SDK-Client": PrimerSource.iOSNative.sourceType
    ]
    
    var headers: [String: String]? {
        var tmpHeaders = PrimerAPI.headers
        
        switch self {
        case .deleteVaultedPaymentMethod(let clientToken, _),
                .exchangePaymentMethodToken(let clientToken, _),
                .fetchVaultedPaymentMethods(let clientToken),
                .createPayPalOrderSession(let clientToken, _),
                .createPayPalBillingAgreementSession(let clientToken, _),
                .confirmPayPalBillingAgreement(let clientToken, _),
                .createKlarnaPaymentSession(let clientToken, _),
                .createKlarnaCustomerToken(let clientToken, _),
                .finalizeKlarnaPaymentSession(let clientToken, _),
                .tokenizePaymentMethod(let clientToken, _),
                .begin3DSRemoteAuth(let clientToken, _, _),
                .continue3DSRemoteAuth(let clientToken, _),
                .createApayaSession(let clientToken, _),
                .listAdyenBanks(let clientToken, _),
                .requestPrimerConfigurationWithActions(let clientToken, _),
                .fetchPayPalExternalPayerInfo(let clientToken, _),
                .createPayment(let clientToken, _),
                .resumePayment(let clientToken, _, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
        
        case .validateClientToken(let request):
            if let token = request.clientToken.jwtTokenPayload?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }

        case .fetchConfiguration(let clientToken, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
            
        case .poll(let clientToken, _):
            if let token = clientToken?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
        case .sendAnalyticsEvents:
            break
        }
        
        switch self {
        case .fetchConfiguration,
                .fetchVaultedPaymentMethods:
            tmpHeaders["X-Api-Version"] = "2.1"
        case .tokenizePaymentMethod,
                .deleteVaultedPaymentMethod,
                .exchangePaymentMethodToken:
            tmpHeaders["X-Api-Version"] = "2021-12-10"
        case .createPayment:
            tmpHeaders["X-Api-Version"] = "2021-09-27"
        default:
            break
        }
        
        return tmpHeaders
    }
    
    // MARK: Base URL
    var baseURL: String? {
        switch self {
        case .createPayPalOrderSession(let clientToken, _),
                .createPayPalBillingAgreementSession(let clientToken, _),
                .confirmPayPalBillingAgreement(let clientToken, _),
                .createKlarnaPaymentSession(let clientToken, _),
                .createKlarnaCustomerToken(let clientToken, _),
                .finalizeKlarnaPaymentSession(let clientToken, _),
                .createApayaSession(let clientToken, _),
                .listAdyenBanks(let clientToken, _),
                .fetchPayPalExternalPayerInfo(let clientToken, _):
            guard let urlStr = clientToken.coreUrl else { return nil }
            return urlStr
        case .deleteVaultedPaymentMethod(let clientToken, _),
                .fetchVaultedPaymentMethods(let clientToken),
                .exchangePaymentMethodToken(let clientToken, _),
                .tokenizePaymentMethod(let clientToken, _),
                .begin3DSRemoteAuth(let clientToken, _, _),
                .continue3DSRemoteAuth(let clientToken, _),
                .createPayment(let clientToken, _),
                .resumePayment(let clientToken, _, _),
                .requestPrimerConfigurationWithActions(let clientToken, _):
            guard let urlStr = clientToken.pciUrl else { return nil }
            return urlStr
        case .fetchConfiguration(let clientToken, _):
            guard let urlStr = clientToken.configurationUrl else { return nil }
            return urlStr
        case .poll(_, let url):
            return url
        case .sendAnalyticsEvents(let url, _):
            return url.absoluteString
        case .validateClientToken(let request):
            return request.clientToken.jwtTokenPayload?.pciUrl
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
        case .exchangePaymentMethodToken(_, let paymentMethodId):
            return "/payment-instruments/\(paymentMethodId)/exchange"
        case .createPayPalOrderSession:
            return "/paypal/orders/create"
        case .createPayPalBillingAgreementSession:
            return "/paypal/billing-agreements/create-agreement"
        case .confirmPayPalBillingAgreement:
            return "/paypal/billing-agreements/confirm-agreement"
        case .createKlarnaPaymentSession:
            return "/klarna/payment-sessions"
        case .createKlarnaCustomerToken:
            return "/klarna/customer-tokens"
        case .finalizeKlarnaPaymentSession:
            return "/klarna/payment-sessions/finalize"
//        case .createDirectDebitMandate:
//            return "/gocardless/mandates"
        case .tokenizePaymentMethod:
            return "/payment-instruments"
        case .begin3DSRemoteAuth(_, let paymentMethodToken, _):
            return "/3ds/\(paymentMethodToken.token ?? "")/auth"
        case .continue3DSRemoteAuth(_, let threeDSTokenId):
            return "/3ds/\(threeDSTokenId)/continue"
        case .createApayaSession:
            return "/session-token"
        case .listAdyenBanks:
            return "/adyen/checkout"
        case .requestPrimerConfigurationWithActions:
            return "/client-session/actions"
        case .poll:
            return ""
        case .sendAnalyticsEvents:
            return ""
        case .fetchPayPalExternalPayerInfo:
            return "/paypal/orders"
        case .validateClientToken:
            return "/client-token/validate"
        case .createPayment:
            return "/payments"
        case .resumePayment(_, let paymentId, _):
            return "/payments/\(paymentId)/resume"
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
        case .createPayPalOrderSession,
                .createPayPalBillingAgreementSession,
                .confirmPayPalBillingAgreement,
                .createKlarnaPaymentSession,
                .createKlarnaCustomerToken,
                .exchangePaymentMethodToken,
                .finalizeKlarnaPaymentSession,
                .tokenizePaymentMethod,
                .requestPrimerConfigurationWithActions,
                .begin3DSRemoteAuth,
                .continue3DSRemoteAuth,
                .createApayaSession,
                .listAdyenBanks,
                .sendAnalyticsEvents,
                .fetchPayPalExternalPayerInfo,
                .validateClientToken,
                .createPayment,
                .resumePayment:
            return .post
        case .poll:
            return .get
        }
    }
    
    // MARK: Query Parameters
    
    var queryParameters: [String: String]? {
        switch self {
        case .fetchConfiguration(_, let requestParameters):
            return requestParameters?.toDictionary()
        default:
            return nil
        }
    }
    
    // MARK: HTTP Body
    
    var body: Data? {
        switch self {
        case .createPayPalOrderSession(_, let payPalCreateOrderRequest):
            return try? JSONEncoder().encode(payPalCreateOrderRequest)
        case .createPayPalBillingAgreementSession(_, let payPalCreateBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalCreateBillingAgreementRequest)
        case .confirmPayPalBillingAgreement(_, let payPalConfirmBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalConfirmBillingAgreementRequest)
        case .createKlarnaPaymentSession(_, let klarnaCreatePaymentSessionAPIRequest):
            return try? JSONEncoder().encode(klarnaCreatePaymentSessionAPIRequest)
        case .createKlarnaCustomerToken(_, let klarnaCreateCustomerTokenAPIRequest):
            return try? JSONEncoder().encode(klarnaCreateCustomerTokenAPIRequest)
        case .fetchConfiguration:
            return nil
        case .finalizeKlarnaPaymentSession(_, let klarnaFinalizePaymentSessionRequest):
            return try? JSONEncoder().encode(klarnaFinalizePaymentSessionRequest)
        case .createApayaSession(_, let request):
            return try? JSONEncoder().encode(request)
        case .tokenizePaymentMethod(_, let req):
            if let req = req as? Request.Body.Tokenization {
                return try? JSONEncoder().encode(req)
            } else {
                return nil
            }
        case .begin3DSRemoteAuth(_, _, let threeDSecureBeginAuthRequest):
            return try? JSONEncoder().encode(threeDSecureBeginAuthRequest)
        case .listAdyenBanks(_, let request):
            return try? JSONEncoder().encode(request)
        case .requestPrimerConfigurationWithActions(_, let request):
            return try? JSONEncoder().encode(request.actions)
        case .deleteVaultedPaymentMethod,
                .exchangePaymentMethodToken,
                .fetchVaultedPaymentMethods,
                .continue3DSRemoteAuth,
                .poll:
            return nil
        case .sendAnalyticsEvents(_, let body):
            return try? JSONEncoder().encode(body)
        case .fetchPayPalExternalPayerInfo(_, let payPalExternalPayerInfoRequestBody):
            return try? JSONEncoder().encode(payPalExternalPayerInfoRequestBody)
        case .validateClientToken(let clientTokenToValidate):
            return try? JSONEncoder().encode(clientTokenToValidate)
        case .createPayment(_, let paymentCreateRequestBody):
            return try? JSONEncoder().encode(paymentCreateRequestBody)
        case .resumePayment(_, _, let paymentResumeRequestBody):
            return try? JSONEncoder().encode(paymentResumeRequestBody)
        }
    }
    
    // MARK: Should Return Response Body
    
    var shouldParseResponseBody: Bool {
        switch self {
        case .deleteVaultedPaymentMethod(_, _):
            return false
        default:
            return true
        }
    }

}

#endif
