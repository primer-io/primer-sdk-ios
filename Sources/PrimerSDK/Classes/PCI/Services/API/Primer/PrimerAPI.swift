//
//  PrimerAPI.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

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
             (.listRetailOutlets, .listRetailOutlets),
             (.begin3DSRemoteAuth, .begin3DSRemoteAuth),
             (.continue3DSRemoteAuth, .continue3DSRemoteAuth),
             (.poll, .poll),
             (.sendAnalyticsEvents, .sendAnalyticsEvents),
             (.createPayment, .createPayment),
             (.validateClientToken, .validateClientToken),
             (.getNolSdkSecret, .getNolSdkSecret),
             (.getPhoneMetadata, .getPhoneMetadata):
            return true
        default:
            return false
        }
    }

    case redirect(clientToken: DecodedJWTToken, url: URL)
    case exchangePaymentMethodToken(clientToken: DecodedJWTToken, vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?)
    case fetchConfiguration(clientToken: DecodedJWTToken, requestParameters: Request.URLParameters.Configuration?)
    case fetchVaultedPaymentMethods(clientToken: DecodedJWTToken)
    case deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String)
    case createPayPalOrderSession(clientToken: DecodedJWTToken, payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder)
    case createPayPalBillingAgreementSession(clientToken: DecodedJWTToken, payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement)
    case confirmPayPalBillingAgreement(clientToken: DecodedJWTToken, payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement)
    case createKlarnaPaymentSession(clientToken: DecodedJWTToken, klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession)
    case createKlarnaCustomerToken(clientToken: DecodedJWTToken, klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken)
    case finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken, klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession)
    case createApayaSession(clientToken: DecodedJWTToken, request: Request.Body.Apaya.CreateSession)
    case tokenizePaymentMethod(clientToken: DecodedJWTToken, tokenizationRequestBody: Request.Body.Tokenization)
    case listAdyenBanks(clientToken: DecodedJWTToken, request: Request.Body.Adyen.BanksList)
    case listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String)

    case requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken, request: ClientSessionUpdateRequest)

    // 3DS
    case begin3DSRemoteAuth(clientToken: DecodedJWTToken, paymentMethodTokenData: PrimerPaymentMethodTokenData, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest)
    case continue3DSRemoteAuth(clientToken: DecodedJWTToken, threeDSTokenId: String, continueInfo: ThreeDS.ContinueInfo)

    // Generic
    case poll(clientToken: DecodedJWTToken?, url: String)

    case sendAnalyticsEvents(clientToken: DecodedJWTToken?, url: URL, body: [Analytics.Event]?)

    case fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken, payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo)

    case validateClientToken(request: Request.Body.ClientTokenValidation)

    // Create - Resume Payment

    case createPayment(clientToken: DecodedJWTToken, paymentRequest: Request.Body.Payment.Create)
    case resumePayment(clientToken: DecodedJWTToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume)

    case testFinalizePolling(clientToken: DecodedJWTToken, testId: String)
    case getNolSdkSecret(clientToken: DecodedJWTToken, request: Request.Body.NolPay.NolPaySecretDataRequest)
    case getPhoneMetadata(clientToken: DecodedJWTToken, request: Request.Body.PhoneMetadata.PhoneMetadataDataRequest)

}

internal extension PrimerAPI {

    // MARK: Headers

    static let headers: [String: String] = [
        "Content-Type": "application/json",
        "Primer-SDK-Version": VersionUtils.releaseVersionNumber ?? "n/a",
        "Primer-SDK-Client": PrimerSource.sdkSourceType.sourceType
    ]

    var headers: [String: String]? {
        var tmpHeaders = PrimerAPI.headers

        if let checkoutSessionId = PrimerInternal.shared.checkoutSessionId {
            tmpHeaders["Primer-SDK-Checkout-Session-ID"] = checkoutSessionId
        }

        switch self {
        case .redirect(let clientToken, _),
             .deleteVaultedPaymentMethod(let clientToken, _),
             .exchangePaymentMethodToken(let clientToken, _, _),
             .fetchVaultedPaymentMethods(let clientToken),
             .createPayPalOrderSession(let clientToken, _),
             .createPayPalBillingAgreementSession(let clientToken, _),
             .confirmPayPalBillingAgreement(let clientToken, _),
             .createKlarnaPaymentSession(let clientToken, _),
             .createKlarnaCustomerToken(let clientToken, _),
             .finalizeKlarnaPaymentSession(let clientToken, _),
             .tokenizePaymentMethod(let clientToken, _),
             .begin3DSRemoteAuth(let clientToken, _, _),
             .continue3DSRemoteAuth(let clientToken, _, _),
             .createApayaSession(let clientToken, _),
             .listAdyenBanks(let clientToken, _),
             .listRetailOutlets(let clientToken, _),
             .requestPrimerConfigurationWithActions(let clientToken, _),
             .fetchPayPalExternalPayerInfo(let clientToken, _),
             .createPayment(let clientToken, _),
             .resumePayment(let clientToken, _, _),
             .testFinalizePolling(let clientToken, _),
             .getPhoneMetadata(let clientToken, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }

        case .validateClientToken(let request):
            if let token = request.clientToken.decodedJWTToken?.accessToken {
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

        case .sendAnalyticsEvents(let clientToken, _, _):
            if let token = clientToken?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
        case .getNolSdkSecret(clientToken: let clientToken, _):
            tmpHeaders["Primer-Client-Token"] = clientToken.accessToken
        }

        switch self {
        case .exchangePaymentMethodToken:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .fetchConfiguration:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .fetchVaultedPaymentMethods:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .deleteVaultedPaymentMethod:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .createPayPalOrderSession:
            break
        case .createPayPalBillingAgreementSession:
            break
        case .confirmPayPalBillingAgreement:
            break
        case .createKlarnaPaymentSession:
            break
        case .createKlarnaCustomerToken:
            break
        case .finalizeKlarnaPaymentSession:
            break
        case .createApayaSession:
            break
        case .tokenizePaymentMethod:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .listAdyenBanks:
            break
        case .listRetailOutlets:
            break
        case .requestPrimerConfigurationWithActions:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .begin3DSRemoteAuth:
            tmpHeaders["X-Api-Version"] = "2.1"
        case .continue3DSRemoteAuth:
            tmpHeaders["X-Api-Version"] = "2.1"
        case .poll:
            break
        case .sendAnalyticsEvents:
            break
        case .fetchPayPalExternalPayerInfo:
            break
        case .validateClientToken:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .createPayment:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .resumePayment:
            tmpHeaders["X-Api-Version"] = "2.2"
        case .testFinalizePolling:
            break
        case .getNolSdkSecret:
            break
        case .redirect:
            break
        case .getPhoneMetadata:
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
             .listRetailOutlets(let clientToken, _),
             .fetchPayPalExternalPayerInfo(let clientToken, _),
             .testFinalizePolling(let clientToken, _),
             .getNolSdkSecret(let clientToken, _):
            guard let urlStr = clientToken.coreUrl else { return nil }
            return urlStr
        case .deleteVaultedPaymentMethod(let clientToken, _),
             .fetchVaultedPaymentMethods(let clientToken),
             .exchangePaymentMethodToken(let clientToken, _, _),
             .tokenizePaymentMethod(let clientToken, _),
             .begin3DSRemoteAuth(let clientToken, _, _),
             .continue3DSRemoteAuth(let clientToken, _, _),
             .createPayment(let clientToken, _),
             .resumePayment(let clientToken, _, _),
             .requestPrimerConfigurationWithActions(let clientToken, _),
             .getPhoneMetadata(let clientToken, _):
            guard let urlStr = clientToken.pciUrl else { return nil }
            return urlStr
        case .fetchConfiguration(let clientToken, _):
            guard let urlStr = clientToken.configurationUrl else { return nil }
            return urlStr
        case .poll(_, let url):
            return url
        case .sendAnalyticsEvents(_, let url, _):
            return url.absoluteString
        case .validateClientToken(let request):
            return request.clientToken.decodedJWTToken?.pciUrl
        case .redirect(_, let url):
            return url.absoluteString
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
        case .exchangePaymentMethodToken(_, let paymentMethodId, _):
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
        case .tokenizePaymentMethod:
            return "/payment-instruments"
        case .begin3DSRemoteAuth(_, let paymentMethodToken, _):
            return "/3ds/\(paymentMethodToken.token ?? "")/auth"
        case .continue3DSRemoteAuth(_, let threeDSTokenId, _):
            return "/3ds/\(threeDSTokenId)/continue"
        case .createApayaSession:
            return "/session-token"
        case .listAdyenBanks:
            return "/adyen/checkout"
        case .listRetailOutlets(_, let paymentMethodId):
            return "/payment-method-options/\(paymentMethodId)/retail-outlets"
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
        case .testFinalizePolling:
            return "/finalize-polling"
        case .getNolSdkSecret:
            return "/nol-pay/sdk-secrets"
        case .redirect:
            return ""
        case .getPhoneMetadata(_, let request):
            return "phone-number-lookups/\(request.phoneNumber)"
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
        case .redirect,
             .fetchConfiguration,
             .fetchVaultedPaymentMethods,
             .listRetailOutlets,
             .getPhoneMetadata:
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
             .resumePayment,
             .testFinalizePolling,
             .getNolSdkSecret:
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
            return try? JSONEncoder().encode(req)
        case .begin3DSRemoteAuth(_, _, let threeDSecureBeginAuthRequest):
            return try? JSONEncoder().encode(threeDSecureBeginAuthRequest)
        case .continue3DSRemoteAuth(_, _, let continueInfo):
            return try? JSONEncoder().encode(continueInfo)
        case .listAdyenBanks(_, let request):
            return try? JSONEncoder().encode(request)
        case .requestPrimerConfigurationWithActions(_, let request):
            return try? JSONEncoder().encode(request.actions)
        case .redirect,
             .deleteVaultedPaymentMethod,
             .fetchVaultedPaymentMethods,
             .poll,
             .listRetailOutlets:
            return nil
        case .exchangePaymentMethodToken(_, _, let vaultedPaymentMethodAdditionalData):
            if let vaultedCardAdditionalData = vaultedPaymentMethodAdditionalData as? PrimerVaultedCardAdditionalData {
                return try? JSONEncoder().encode(vaultedCardAdditionalData)
            } else {
                return nil
            }
        case .sendAnalyticsEvents(_, _, let body):
            return try? JSONEncoder().encode(body)
        case .fetchPayPalExternalPayerInfo(_, let payPalExternalPayerInfoRequestBody):
            return try? JSONEncoder().encode(payPalExternalPayerInfoRequestBody)
        case .validateClientToken(let clientTokenToValidate):
            return try? JSONEncoder().encode(clientTokenToValidate)
        case .createPayment(_, let paymentCreateRequestBody):
            return try? JSONEncoder().encode(paymentCreateRequestBody)
        case .resumePayment(_, _, let paymentResumeRequestBody):
            return try? JSONEncoder().encode(paymentResumeRequestBody)
        case .testFinalizePolling:
            return nil
        case .getNolSdkSecret(_, let requestBody):
            return try? JSONEncoder().encode(requestBody)
        case .getPhoneMetadata:
            return nil
        }
    }

    // MARK: Should Return Response Body

    var shouldParseResponseBody: Bool {
        switch self {
        case .redirect,
             .deleteVaultedPaymentMethod:
            return false
        default:
            return true
        }
    }

}
