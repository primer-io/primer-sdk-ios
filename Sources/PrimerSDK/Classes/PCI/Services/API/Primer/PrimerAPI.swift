//
//  PrimerAPI.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length

import Foundation

enum PrimerAPI: Endpoint, Equatable {
    // MARK: - Pull ApiVersion from PrimerSettings

    private static var apiVersion: String {
        PrimerSettings.current.apiVersion.rawValue
    }

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
    case exchangePaymentMethodToken(clientToken: DecodedJWTToken,
                                    vaultedPaymentMethodId: String,
                                    vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?)
    case fetchConfiguration(clientToken: DecodedJWTToken, requestParameters: Request.URLParameters.Configuration?)
    case fetchVaultedPaymentMethods(clientToken: DecodedJWTToken)
    case deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String)
    case createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder)
    case createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement)
    case confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement)
    case createKlarnaPaymentSession(clientToken: DecodedJWTToken, klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession)
    case createKlarnaCustomerToken(clientToken: DecodedJWTToken, klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken)
    case finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken, klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession)
    case tokenizePaymentMethod(clientToken: DecodedJWTToken, tokenizationRequestBody: Request.Body.Tokenization)
    case listAdyenBanks(clientToken: DecodedJWTToken, request: Request.Body.Adyen.BanksList)
    case listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String)

    case requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken, request: ClientSessionUpdateRequest)

    // 3DS
    case begin3DSRemoteAuth(clientToken: DecodedJWTToken,
                            paymentMethodTokenData: PrimerPaymentMethodTokenData,
                            threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest)
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

    // BIN Data
    case listCardNetworks(clientToken: DecodedJWTToken, bin: String)
    case getNolSdkSecret(clientToken: DecodedJWTToken, request: Request.Body.NolPay.NolPaySecretDataRequest)
    case getPhoneMetadata(clientToken: DecodedJWTToken, request: Request.Body.PhoneMetadata.PhoneMetadataDataRequest)

    // ACH - Complete Payment
    case completePayment(clientToken: DecodedJWTToken, url: URL, paymentRequest: Request.Body.Payment.Complete)
}

extension PrimerAPI {

    // MARK: - Headers

    static let headers: [String: String] = [
        "Content-Type": "application/json",
        "Primer-SDK-Version": VersionUtils.releaseVersionNumber ?? "n/a",
        "Primer-SDK-Client": PrimerSource.sdkSourceType.sourceType
    ]

    var headers: [String: String]? {
        var tmpHeaders = PrimerAPI.headers

        if method == .get {
            tmpHeaders.removeValue(forKey: "Content-Type")
        }

        if let checkoutSessionId = PrimerInternal.shared.checkoutSessionId {
            tmpHeaders["Primer-SDK-Checkout-Session-ID"] = checkoutSessionId
        }

        switch self {
        case let .redirect(clientToken, _),
             let .deleteVaultedPaymentMethod(clientToken, _),
             let .exchangePaymentMethodToken(clientToken, _, _),
             let .fetchVaultedPaymentMethods(clientToken),
             let .createPayPalOrderSession(clientToken, _),
             let .createPayPalBillingAgreementSession(clientToken, _),
             let .confirmPayPalBillingAgreement(clientToken, _),
             let .createKlarnaPaymentSession(clientToken, _),
             let .createKlarnaCustomerToken(clientToken, _),
             let .finalizeKlarnaPaymentSession(clientToken, _),
             let .tokenizePaymentMethod(clientToken, _),
             let .begin3DSRemoteAuth(clientToken, _, _),
             let .continue3DSRemoteAuth(clientToken, _, _),
             let .listAdyenBanks(clientToken, _),
             let .listRetailOutlets(clientToken, _),
             let .requestPrimerConfigurationWithActions(clientToken, _),
             let .fetchPayPalExternalPayerInfo(clientToken, _),
             let .resumePayment(clientToken, _, _),
             let .testFinalizePolling(clientToken, _),
             let .listCardNetworks(clientToken, _),
             let .getPhoneMetadata(clientToken, _),
             let .completePayment(clientToken, _, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }

        case let .createPayment(clientToken, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
            if let idempotencyKey = PrimerInternal.shared.currentIdempotencyKey {
                tmpHeaders["X-Idempotency-Key"] = idempotencyKey
            }

        case let .validateClientToken(request):
            if let token = request.clientToken.decodedJWTToken?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }

        case let .fetchConfiguration(clientToken, _):
            if let token = clientToken.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }

        case let .poll(clientToken, _):
            if let token = clientToken?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }

        case let .sendAnalyticsEvents(clientToken, _, _):
            if let token = clientToken?.accessToken {
                tmpHeaders["Primer-Client-Token"] = token
            }
        case let .getNolSdkSecret(clientToken: clientToken, _):
            tmpHeaders["Primer-Client-Token"] = clientToken.accessToken
        }

        // Switch statement for setting the X-Api-Version from our single variable
        switch self {
        case .exchangePaymentMethodToken:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .fetchConfiguration:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .fetchVaultedPaymentMethods:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .deleteVaultedPaymentMethod:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .tokenizePaymentMethod:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .requestPrimerConfigurationWithActions:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .validateClientToken:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .createPayment:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .resumePayment:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .listCardNetworks:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .begin3DSRemoteAuth:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .continue3DSRemoteAuth:
            tmpHeaders["X-Api-Version"] = Self.apiVersion
        case .createPayPalOrderSession,
             .createPayPalBillingAgreementSession,
             .confirmPayPalBillingAgreement,
             .createKlarnaPaymentSession,
             .createKlarnaCustomerToken,
             .finalizeKlarnaPaymentSession,
             .listAdyenBanks,
             .listRetailOutlets,
             .poll,
             .sendAnalyticsEvents,
             .fetchPayPalExternalPayerInfo,
             .testFinalizePolling,
             .getNolSdkSecret,
             .redirect,
             .getPhoneMetadata,
             .completePayment:
            break
        }

        return tmpHeaders
    }

    // MARK: - Base URL

    var baseURL: String? {
        switch self {
        case let .createPayPalOrderSession(clientToken, _),
             let .createPayPalBillingAgreementSession(clientToken, _),
             let .confirmPayPalBillingAgreement(clientToken, _),
             let .createKlarnaPaymentSession(clientToken, _),
             let .createKlarnaCustomerToken(clientToken, _),
             let .finalizeKlarnaPaymentSession(clientToken, _),
             let .listAdyenBanks(clientToken, _),
             let .listRetailOutlets(clientToken, _),
             let .fetchPayPalExternalPayerInfo(clientToken, _),
             let .testFinalizePolling(clientToken, _),
             let .getNolSdkSecret(clientToken, _):
            guard let baseURL = configuration?.coreUrl ?? clientToken.coreUrl else { return nil }
            return baseURL
        case .listCardNetworks:
            guard let baseURL = configuration?.binDataUrl else { return nil }
            return baseURL
        case let .deleteVaultedPaymentMethod(clientToken, _),
             let .fetchVaultedPaymentMethods(clientToken),
             let .exchangePaymentMethodToken(clientToken, _, _),
             let .tokenizePaymentMethod(clientToken, _),
             let .begin3DSRemoteAuth(clientToken, _, _),
             let .continue3DSRemoteAuth(clientToken, _, _),
             let .createPayment(clientToken, _),
             let .resumePayment(clientToken, _, _),
             let .requestPrimerConfigurationWithActions(clientToken, _),
             let .getPhoneMetadata(clientToken, _):
            guard let baseURL = configuration?.pciUrl ?? clientToken.pciUrl else { return nil }
            return baseURL
        case let .fetchConfiguration(clientToken, _):
            guard let baseURL = clientToken.configurationUrl else { return nil }
            return baseURL
        case let .poll(_, url):
            return url
        case let .sendAnalyticsEvents(_, url, _):
            return url.absoluteString
        case let .validateClientToken(request):
            return request.clientToken.decodedJWTToken?.pciUrl
        case let .redirect(_, url):
            return url.absoluteString
        case let .completePayment(_, url, _):
            return url.absoluteString
        }
    }

    // MARK: - Path

    var path: String {
        switch self {
        case let .deleteVaultedPaymentMethod(_, id):
            return "/payment-instruments/\(id)/vault"
        case .fetchConfiguration:
            return ""
        case .fetchVaultedPaymentMethods:
            return "/payment-instruments"
        case let .exchangePaymentMethodToken(_, paymentMethodId, _):
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
        case let .begin3DSRemoteAuth(_, paymentMethodToken, _):
            return "/3ds/\(paymentMethodToken.token ?? "")/auth"
        case let .continue3DSRemoteAuth(_, threeDSTokenId, _):
            return "/3ds/\(threeDSTokenId)/continue"
        case .listAdyenBanks:
            return "/adyen/checkout"
        case let .listRetailOutlets(_, paymentMethodId):
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
        case let .resumePayment(_, paymentId, _):
            return "/payments/\(paymentId)/resume"
        case .testFinalizePolling:
            return "/finalize-polling"
        case let .listCardNetworks(_, bin):
            return "/v1/bin-data/\(bin)"
        case .getNolSdkSecret:
            return "/nol-pay/sdk-secrets"
        case .redirect, .completePayment:
            return ""
        case let .getPhoneMetadata(_, request):
            return "/phone-number-lookups/\(request.phoneNumber)"
        }
    }

    // MARK: - HTTP Method

    var method: HTTPMethod {
        switch self {
        case .deleteVaultedPaymentMethod:
            return .delete
        case .redirect,
             .fetchConfiguration,
             .fetchVaultedPaymentMethods,
             .listRetailOutlets,
             .listCardNetworks,
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
             .listAdyenBanks,
             .sendAnalyticsEvents,
             .fetchPayPalExternalPayerInfo,
             .validateClientToken,
             .createPayment,
             .resumePayment,
             .testFinalizePolling,
             .getNolSdkSecret,
             .completePayment:
            return .post
        case .poll:
            return .get
        }
    }

    // MARK: - Query Parameters

    var queryParameters: [String: String]? {
        switch self {
        case let .fetchConfiguration(_, requestParameters):
            return requestParameters?.toDictionary()
        default:
            return nil
        }
    }

    // MARK: - HTTP Body

    var body: Data? {
        switch self {
        case let .createPayPalOrderSession(_, payPalCreateOrderRequest):
            return try? JSONEncoder().encode(payPalCreateOrderRequest)
        case let .createPayPalBillingAgreementSession(_, payPalCreateBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalCreateBillingAgreementRequest)
        case let .confirmPayPalBillingAgreement(_, payPalConfirmBillingAgreementRequest):
            return try? JSONEncoder().encode(payPalConfirmBillingAgreementRequest)
        case let .createKlarnaPaymentSession(_, klarnaCreatePaymentSessionAPIRequest):
            return try? JSONEncoder().encode(klarnaCreatePaymentSessionAPIRequest)
        case let .createKlarnaCustomerToken(_, klarnaCreateCustomerTokenAPIRequest):
            return try? JSONEncoder().encode(klarnaCreateCustomerTokenAPIRequest)
        case .fetchConfiguration:
            return nil
        case let .finalizeKlarnaPaymentSession(_, klarnaFinalizePaymentSessionRequest):
            return try? JSONEncoder().encode(klarnaFinalizePaymentSessionRequest)
        case let .tokenizePaymentMethod(_, req):
            return try? JSONEncoder().encode(req)
        case let .begin3DSRemoteAuth(_, _, threeDSecureBeginAuthRequest):
            return try? JSONEncoder().encode(threeDSecureBeginAuthRequest)
        case let .continue3DSRemoteAuth(_, _, continueInfo):
            return try? JSONEncoder().encode(continueInfo)
        case let .listAdyenBanks(_, request):
            return try? JSONEncoder().encode(request)
        case let .requestPrimerConfigurationWithActions(_, request):
            return try? JSONEncoder().encode(request.actions)
        case .redirect,
             .deleteVaultedPaymentMethod,
             .fetchVaultedPaymentMethods,
             .poll,
             .listRetailOutlets:
            return nil
        case let .exchangePaymentMethodToken(_, _, vaultedPaymentMethodAdditionalData):
            if let vaultedCardAdditionalData = vaultedPaymentMethodAdditionalData as? PrimerVaultedCardAdditionalData {
                return try? JSONEncoder().encode(vaultedCardAdditionalData)
            } else {
                return nil
            }
        case let .sendAnalyticsEvents(_, _, body):
            return try? JSONEncoder().encode(body)
        case let .fetchPayPalExternalPayerInfo(_, payPalExternalPayerInfoRequestBody):
            return try? JSONEncoder().encode(payPalExternalPayerInfoRequestBody)
        case let .validateClientToken(clientTokenToValidate):
            return try? JSONEncoder().encode(clientTokenToValidate)
        case let .createPayment(_, paymentCreateRequestBody):
            return try? JSONEncoder().encode(paymentCreateRequestBody)
        case let .resumePayment(_, _, paymentResumeRequestBody):
            return try? JSONEncoder().encode(paymentResumeRequestBody)
        case .testFinalizePolling, .listCardNetworks:
            return nil
        case let .getNolSdkSecret(_, requestBody):
            return try? JSONEncoder().encode(requestBody)
        case .getPhoneMetadata:
            return nil
        case let .completePayment(_, _, paymentRequest):
            return try? JSONEncoder().encode(paymentRequest)
        }
    }

    // MARK: - Timeout

    var timeout: TimeInterval? {
        switch self {
        // 15-second endpoints
        case .exchangePaymentMethodToken,
             .fetchConfiguration,
             .fetchVaultedPaymentMethods,
             .deleteVaultedPaymentMethod,
             .tokenizePaymentMethod,
             .requestPrimerConfigurationWithActions,
             .begin3DSRemoteAuth,
             .continue3DSRemoteAuth,
             .validateClientToken,
             .listCardNetworks,
             .getPhoneMetadata:
            return 15

        // 60-second endpoints
        case .createPayPalOrderSession,
             .createPayPalBillingAgreementSession,
             .confirmPayPalBillingAgreement,
             .createKlarnaPaymentSession,
             .createKlarnaCustomerToken,
             .finalizeKlarnaPaymentSession,
             .listAdyenBanks,
             .listRetailOutlets,
             .fetchPayPalExternalPayerInfo,
             .testFinalizePolling,
             .getNolSdkSecret,
             .redirect,
             .createPayment,
             .resumePayment,
             .completePayment:
            return 60

        // No explicit timeout
        case .poll,
             .sendAnalyticsEvents:
            return nil
        }
    }

    // MARK: - Helpers

    var configuration: PrimerAPIConfiguration? {
        PrimerAPIConfiguration.current
    }
}
// swiftlint:enable file_length
