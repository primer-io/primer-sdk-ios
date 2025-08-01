//
//  Mocks.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedJWTToken(accessToken: "bla", expDate: Date(timeIntervalSince1970: 2000000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", supportedThreeDsProtocolVersions: nil, coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: nil, backendCallbackUrl: nil, primerTransactionId: nil, iPay88PaymentMethodId: nil, iPay88ActionType: nil, supportedCurrencyCode: nil, supportedCountry: nil, nolPayTransactionNo: nil, stripeClientSecret: nil, sdkCompleteUrl: "https://primer.io")

// (
//    accessToken: "bla",
//    configurationUrl: "bla",
//    paymentFlow: "bla",
//    threeDSecureInitUrl: "bla",
//    threeDSecureToken: "bla",
//    coreUrl: "https://primer.io",
//    pciUrl: "https://primer.io",
//    env: "bla"
// )

var mockSettings = PrimerSettings(
    paymentMethodOptions: PrimerPaymentMethodOptions(
        urlScheme: "urlScheme",
        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "mid", merchantName: "name")
    )
)

class Mocks {

    static var settings = PrimerSettings(
        paymentMethodOptions: PrimerPaymentMethodOptions(
            urlScheme: "urlScheme",
            applePayOptions: PrimerApplePayOptions(merchantIdentifier: "mid", merchantName: "name")
        )
    )

    static var decodedJWTToken = DecodedJWTToken(accessToken: "bla", expDate: Date(timeIntervalSince1970: 2000000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", supportedThreeDsProtocolVersions: nil, coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: nil, backendCallbackUrl: nil, primerTransactionId: nil, iPay88PaymentMethodId: nil, iPay88ActionType: nil, supportedCurrencyCode: nil, supportedCountry: nil, nolPayTransactionNo: nil, stripeClientSecret: nil, sdkCompleteUrl: "https://primer.io")

    static var primerPaymentMethodTokenData = PrimerPaymentMethodTokenData(
        analyticsId: "mock_analytics_id",
        id: "mock_payment_method_token_data_id",
        isVaulted: false,
        isAlreadyVaulted: false,
        paymentInstrumentType: .unknown,
        paymentMethodType: "MOCK_WEB_REDIRECT_PAYMENT_METHOD",
        paymentInstrumentData: nil,
        threeDSecureAuthentication: nil,
        token: "mock_payment_method_token",
        tokenType: .singleUse,
        vaultData: nil)

    static var primerPaymentMethodInstrumentationData = Response.Body.Tokenization.PaymentInstrumentData(
        paypalBillingAgreementId: nil,
        first6Digits: "378282",
        last4Digits: "0005",
        expirationMonth: "03",
        expirationYear: "2030",
        cardholderName: "John Smith",
        network: "Amex",
        isNetworkTokenized: nil,
        klarnaCustomerToken: nil,
        sessionData: nil,
        externalPayerInfo: nil,
        shippingAddress: nil,
        binData: BinData(network: "AMEX"),
        threeDSecureAuthentication: nil,
        gocardlessMandateId: nil,
        authorizationToken: nil,
        mx: nil,
        currencyCode: nil,
        productId: nil,
        paymentMethodConfigId: nil,
        paymentMethodType: nil,
        sessionInfo: nil,
        bankName: nil,
        accountNumberLast4Digits: nil,
        applePayMerchantTokenIdentifier: nil
    )

    static var payment = Response.Body.Payment(
        id: "mock_id",
        paymentId: "mock_payment_id",
        amount: 1000,
        currencyCode: "EUR",
        customerId: "mock_customer_id",
        status: .success)
    
    static let tokenizationRequestBody = Request.Body.Tokenization(paymentInstrument: MockTokenizationRequestBodyPaymentInstrument())

    static func createMockAPIConfiguration(
        clientSession: ClientSession.APIResponse?,
        paymentMethods: [PrimerPaymentMethod]?
    ) -> PrimerAPIConfiguration {
        return PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: clientSession,
            paymentMethods: paymentMethods,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
    }

    static var apiConfiguration = PrimerAPIConfiguration(
        coreUrl: "https://core.primer.io",
        pciUrl: "https://pci.primer.io",
        binDataUrl: "https://primer.io/bindata",
        assetsUrl: "https://assets.staging.core.primer.io",
        clientSession: nil,
        paymentMethods: [],
        primerAccountId: nil,
        keys: nil,
        checkoutModules: nil)

    static var listCardNetworksData = Response.Body.Bin.Networks(networks: [])

    class Static {

        class Strings {

            static var webRedirectPaymentMethodId = "mock_web_redirect_payment_method_id"
            static var adyenGiroPayRedirectPaymentMethodId = "mock_adyen_giropay_payment_method_id"
            static var adyenBlikPaymentMethodId = "mock_adyen_blik_payment_method_id"
            static var adyenIDealPaymentMethodId = "mock_adyen_ideal_payment_method_id"
            static var klarnaPaymentMethodId = "mock_klarna_payment_method_id"
            static var paymentCardPaymentMethodId = "mock_payment_card_payment_method_id"
            static var nolPaymentMethodId = "mock_nol_payment_method_id"
            static var paypalPaymentMethodId = "mock_paypal_method_id"
            static var xenditPaymentMethodId = "mock_xendit_method_id"
            static var adyenVippsPaymentMethodId = "adyen_vipps_method_id"

            static var webRedirectPaymentMethodType = "MOCK_WEB_REDIRECT_PAYMENT_METHOD_TYPE"
            static var adyenGiroPayRedirectPaymentMethodType = "MOCK_ADYEN_GIROPAY_PAYMENT_METHOD_TYPE"
            static var klarnaPaymentMethodType = "MOCK_KLARNA_PAYMENT_METHOD_TYPE"
            static var paymentCardPaymentMethodType = "MOCK_PAYMENT_CARD_PAYMENT_METHOD_TYPE"

            static var webRedirectPaymentMethodName = "Mock Web Redirect Payment Method"
            static var adyenGiroPayRedirectPaymentMethodName = "Mock Adyen GiroPay Payment Method"
            static var adyenBlikPaymentMethodName = "Mock Adyen Blik Payment Method"
            static var adyenVippsPaymentMethodName = "Mock Adyen Vipps Payment Method"
            static var adyenIDealPaymentMethodName = "Mock iDeal Blik Payment Method"
            static var klarnaPaymentMethodName = "Mock Klarna Payment Method"
            static var paymentCardPaymentMethodName = "Mock Payment Card Payment Method"
            static var nolPaymentMethodName = "Mock NOL Payment Method"
            static var xenditPaymentMethodName = "Mock Xendit Payment Method"

            static var processorConfigId = "mock_processor_config_id"
            static var idealPaymentMethodId = "ADYEN_IDEAL"
            static var idealPaymentMethodName = "Mock Ideal Payment Method"
        }
    }

    class PaymentMethods {

        static var webRedirectPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.webRedirectPaymentMethodId,
            implementationType: .webRedirect,
            type: Mocks.Static.Strings.webRedirectPaymentMethodType,
            name: Mocks.Static.Strings.webRedirectPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 99,
            options: nil,
            displayMetadata: nil)

        static var paymentCardPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.paymentCardPaymentMethodId,
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD", // Mocks.Static.Strings.paymentCardPaymentMethodType,
            name: Mocks.Static.Strings.paymentCardPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 0,
            options: nil,
            displayMetadata: nil)

        static var nolPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.nolPaymentMethodId,
            implementationType: .nativeSdk,
            type: "NOL_PAY", // Mocks.Static.Strings.paymentCardPaymentMethodType,
            name: Mocks.Static.Strings.nolPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 0,
            options: MerchantOptions(merchantId: "user8", merchantAccountId: "123", appId: "test"),
            displayMetadata: nil)

        static var adyenGiroPayRedirectPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.adyenGiroPayRedirectPaymentMethodId,
            implementationType: .webRedirect,
            type: "ADYEN_GIROPAY", // Mocks.Static.Strings.adyenGiroPayRedirectPaymentMethodType,
            name: Mocks.Static.Strings.adyenGiroPayRedirectPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 199,
            options: nil,
            displayMetadata: nil)

        static var adyenBlikPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.adyenBlikPaymentMethodId,
            implementationType: .webRedirect,
            type: "ADYEN_BLIK", // Mocks.Static.Strings.adyenGiroPayRedirectPaymentMethodType,
            name: Mocks.Static.Strings.adyenBlikPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: nil,
            options: nil,
            displayMetadata: nil)

        static var adyenVippsPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.adyenVippsPaymentMethodId,
            implementationType: .webRedirect,
            type: "ADYEN_VIPPS", // Mocks.Static.Strings.adyenGiroPayRedirectPaymentMethodType,
            name: Mocks.Static.Strings.adyenVippsPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: nil,
            options: nil,
            displayMetadata: nil)

        static var adyenIDealPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.adyenBlikPaymentMethodId,
            implementationType: .webRedirect,
            type: "ADYEN_IDEAL", // Mocks.Static.Strings.adyenGiroPayRedirectPaymentMethodType,
            name: Mocks.Static.Strings.adyenIDealPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: nil,
            options: nil,
            displayMetadata: nil)

        static var klarnaRedirectPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.klarnaPaymentMethodId,
            implementationType: .nativeSdk,
            type: Mocks.Static.Strings.klarnaPaymentMethodType,
            name: Mocks.Static.Strings.klarnaPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 299,
            options: nil,
            displayMetadata: nil)

        static var idealFormWithRedirectPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.idealPaymentMethodId,
            implementationType: .nativeSdk,
            type: Mocks.Static.Strings.idealPaymentMethodId,
            name: Mocks.Static.Strings.idealPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 0,
            options: nil,
            displayMetadata: nil)

        static var klarnaPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.klarnaPaymentMethodId,
            implementationType: .nativeSdk,
            type: "KLARNA",
            name: "KLARNA",
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 299,
            options: nil,
            displayMetadata: nil)

        static var paypalPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.paypalPaymentMethodId,
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PAYPAL",
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 0,
            options: nil,
            displayMetadata: nil)

        static var xenditPaymentMethod = PrimerPaymentMethod(
            id: Mocks.Static.Strings.xenditPaymentMethodId,
            implementationType: .nativeSdk,
            type: "XENDIT_RETAIL_OUTLETS",
            name: Mocks.Static.Strings.xenditPaymentMethodName,
            processorConfigId: Mocks.Static.Strings.processorConfigId,
            surcharge: 0,
            options: nil,
            displayMetadata: nil)
    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {

    var paymentHandling = PrimerPaymentHandling.auto
    var localeData = PrimerLocaleData()
    var paymentMethodOptions = PrimerPaymentMethodOptions()
    var uiOptions = PrimerUIOptions()
    var threeDsOptions = PrimerThreeDsOptions()
    var debugOptions = PrimerDebugOptions()
    var apiVersion: PrimerApiVersion = .V2_4
}

let mockPaymentMethodConfig = PrimerAPIConfiguration(
    coreUrl: "url",
    pciUrl: "url",
    binDataUrl: "url",
    assetsUrl: "https://assets.staging.core.primer.io",
    clientSession: nil,
    paymentMethods: [
        PrimerPaymentMethod(id: "klarna-test", implementationType: .nativeSdk, type: "KLARNA", name: "Klarna", processorConfigId: "klarna-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
        PrimerPaymentMethod(id: "paypal-test", implementationType: .nativeSdk, type: "PAYPAL", name: "PayPal", processorConfigId: "paypal-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil)
    ],
    primerAccountId: nil,
    keys: nil,
    checkoutModules: nil
)

class MockAppState: AppStateProtocol {

    static var current: AppStateProtocol {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState
    }

    lazy var amount: Int? = {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.merchantAmount ?? AppState.current.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }()

    lazy var currency: Currency? = {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.currencyCode
    }()

    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PrimerPaymentMethodTokenData] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PrimerPaymentMethodTokenData?

    static func resetAPIConfiguration() {
        AppState.current.apiConfiguration = nil
    }

    init(
        clientToken: String? = MockAppState.mockClientToken,
        apiConfiguration: PrimerAPIConfiguration? = PrimerAPIConfiguration(
            coreUrl: "url",
            pciUrl: "url",
            binDataUrl: "url",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: [
                PrimerPaymentMethod(id: "klarna-test", implementationType: .nativeSdk, type: "KLARNA", name: "Klarna", processorConfigId: "klarna-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
                PrimerPaymentMethod(id: "paypal-test", implementationType: .nativeSdk, type: "PAYPAL", name: "PayPal", processorConfigId: "paypal-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil)
            ],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )
    ) {
        self.clientToken = clientToken
        self.apiConfiguration = apiConfiguration
    }
}

extension MockAppState {
    static var mockClientToken: String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjIwMDAwMDAwMDAsImFjY2Vzc1Rva2VuIjoiYzJlOTM3YmMtYmUzOS00ZjVmLTkxYmYtNTIyNWExNDg0OTc1IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnNhbmRib3guZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwicGF5bWVudEZsb3ciOiJERUZBVUxUIn0.1Epm-502bLNhjhIQrmp4ZtrMQa0vQ2FjckPAlgJtuao"
    }

    static var mockClientTokenWithRedirect: String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjIwMDAwMDAwMDAsImFjY2Vzc1Rva2VuIjoiYzJlOTM3YmMtYmUzOS00ZjVmLTkxYmYtNTIyNWExNDg0OTc1IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnNhbmRib3guZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJURVNUX1JFRElSRUNUSU9OIiwiY29uZmlndXJhdGlvblVybCI6Imh0dHBzOi8vYXBpLnNhbmRib3gucHJpbWVyLmlvL2NsaWVudC1zZGsvY29uZmlndXJhdGlvbiIsImNvcmVVcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pbyIsInBjaVVybCI6Imh0dHBzOi8vc2RrLmFwaS5zYW5kYm94LnByaW1lci5pbyIsImVudiI6IlNBTkRCT1giLCJwYXltZW50RmxvdyI6IkRFRkFVTFQiLCJyZWRpcmVjdFVybCI6Imh0dHBzOjovL2xvY2FsaG9zdC9yZWRpcmVjdCIsInN0YXR1c1VybCI6Imh0dHBzOi8vbG9jYWxob3N0L3N0YXR1cyJ9.uHky6KvbU-G4rhEMFZk18YPYAsPxnvX0ssLUsJg_giE"
    }

    static var mockClientTokenWithVoucher = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjIwMDAwMDAwMDAsImFjY2Vzc1Rva2VuIjoiYzJlOTM3YmMtYmUzOS00ZjVmLTkxYmYtNTIyNWExNDg0OTc1IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnNhbmRib3guZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwicGF5bWVudEZsb3ciOiJERUZBVUxUIiwiZXhwaXJlc0F0IjoiMjA1MC0wMS0wMVQwMTowMTowMSIsImVudGl0eSI6ImVudGl0eV92YWx1ZSIsInJlZmVyZW5jZSI6InJlZmVyZW5jZV92YWx1ZSJ9.RuHgnLjY4zet7n-VdjwR7LdNvLS4uZVbGVG_dmwnISg"

    static var mockResumeToken: String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE2NjQ5NTM1OTkwLCJhY2Nlc3NUb2tlbiI6ImIwY2E0NTFhLTBmYmItNGZlYS1hY2UwLTgxMDYwNGQ4OTBkYSIsImFuYWx5dGljc1VybCI6Imh0dHBzOi8vYW5hbHl0aWNzLmFwaS5zYW5kYm94LmNvcmUucHJpbWVyLmlvL21peHBhbmVsIiwiYW5hbHl0aWNzVXJsVjIiOiJodHRwczovL2FuYWx5dGljcy5zYW5kYm94LmRhdGEucHJpbWVyLmlvL2NoZWNrb3V0L3RyYWNrIiwiaW50ZW50IjoiQURZRU5fR0lST1BBWV9SRURJUkVDVElPTiIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwic3RhdHVzVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vcmVzdW1lLXRva2Vucy9lOTM3ZDQyMS0zYzE2LTRjMmUtYTBjOC01OGQxY2RhNWM0NmUiLCJyZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdC5hZHllbi5jb20vaHBwL2NoZWNrb3V0LnNodG1sP3U9c2tpcERldGFpbHMmcD1lSnlOVTl0eW16QVEtUnJ6QmdQaVluamd3UVdTdUUwY2g5aE9waThlV2F4dDFTQXhrbkROMzJjaGwyblR6clF6ekk3WWN5U2RQYnVpYlZ0elJnMlhZaTcyMG9HTEFTVm92YXlwMlV2VnpJV0JnNkpHcW5TcGVBUEtvdi1Zc2FBTi1DOTNBMG9qbGhKcnA2aW9NbGxCZXVCS3RyUzNXS2NVQ05hUHlXSmRXbmdnTzFKaFpvekpUcGkzTzc3dVZxQk5rZDNmZlJEZU5lUEpqdWxiU0xPYkl2dDJ2MTV0cjR0RlVjNnp2ekxQYjFxaTZRZGN3aDRHRFpCeXFiZFNWYUMydk5xRzljLTc5bGJ0ZnVHWlRvbWNHcHBtRCpGeUdUd0gqVk5PbmhZeCplQTg4a042TFNET29KSDVobmpWNWZRZ3dwc3YtV0puaXRYc0txZzhsWWlZcTRmbkpTSHJpWjliNkVJRFdHOHpsdXZGcnFWZ2NJV0xReWFGVVpTWnRDeXlkVm5PRjllSXRVQ05MWVZ0MEJmWm1YUlBhdzJZMSp2eU5qMGEwKnFKUDV1UUstellFZGdKT2ZvbzJ4YVViZEJEaDFZOUNJZko1azhDWmpTb00yZWdjYmw4RlRZWHlFVXhKVlFjbFJsRXpoNkdXakpzOFN2bkRzeFJWaFAtNmxQM3NMN1AtWnVRU0kxR29seUVYd1dUY0pBY0RxSXgwSlk3R2dkbEp5OU9PMjUzdUJ3UnJMSnJ3RGJ5QkVLUEdVajhhUlVRei1hWkY5a0JJMkJUbDhWMkdGY2VxMmpJZ2doR0loYlIxbUNHSDMqNFlYdUNmbGpueVg0S1BtR0pIZTg4WmdmVXhWVTFCWnZSTVBKZFZzVlRCcFlHUFl6Tmh0YTg0cVpQaVV1STdibTJHNnpjR1AxMkl3eCo4dDE2YzNJWXVhRnp3NmdWZVBYZ0M3eUR2dzJjelRwdEpPSzJtblcxS2ZYUjBpY3V4dmZRZGp2blRKeVllSkVmVENNdkNYMHZJYjZUZTlxZkMqa2EqWGh3Tnp5QTQ5YmRlLVVxbi1QTE9lSWJNZTEtblBmSldwcmlCY3BiWlBRIn0.UJnuMt3yT7uuUbDbRMKsP9FnTW89yRPL-z4G2dikpr8"
    }

    static var stripeACHToken: String {
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE2NjQ5NTM1OTkwLCJhY2Nlc3NUb2tlbiI6ImIwY2E0NTFhLTBmYmItNGZlYS1hY2UwLTgxMDYwNGQ4OTBkYSIsImFuYWx5dGljc1VybCI6Imh0dHBzOi8vYW5hbHl0aWNzLmFwaS5zYW5kYm94LmNvcmUucHJpbWVyLmlvL21peHBhbmVsIiwiYW5hbHl0aWNzVXJsVjIiOiJodHRwczovL2FuYWx5dGljcy5zYW5kYm94LmRhdGEucHJpbWVyLmlvL2NoZWNrb3V0L3RyYWNrIiwiaW50ZW50IjoiU1RSSVBFX0FDSCIsInN0cmlwZUNsaWVudFNlY3JldCI6ImNsaWVudC1zZWNyZXQtdGVzdCIsInNka0NvbXBsZXRlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vY2xpZW50LXNkay9jb21wbGV0ZSIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwic3RhdHVzVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vcmVzdW1lLXRva2Vucy9lOTM3ZDQyMS0zYzE2LTRjMmUtYTBjOC01OGQxY2RhNWM0NmUiLCJyZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdC5hZHllbi5jb20vaHBwL2NoZWNrb3V0LnNodG1sP3U9c2tpcERldGFpbHMmcD1lSnlOVTl0eW16QVEtUnJ6QmdQaVluamd3UVdTdUUwY2g5aE9waThlV2F4dDFTQXhrbkROMzJjaGwyblR6clF6ekk3WWN5U2RQYnVpYlZ0elJnMlhZaTcyMG9HTEFTVm92YXlwMlV2VnpJV0JnNkpHcW5TcGVBUEtvdi1Zc2FBTi1DOTNBMG9qbGhKcnA2aW9NbGxCZXVCS3RyUzNXS2NVQ05hUHlXSmRXbmdnTzFKaFpvekpUcGkzTzc3dVZxQk5rZDNmZlJEZU5lUEpqdWxiU0xPYkl2dDJ2MTV0cjR0RlVjNnp2ekxQYjFxaTZRZGN3aDRHRFpCeXFiZFNWYUMydk5xRzljLTc5bGJ0ZnVHWlRvbWNHcHBtRCpGeUdUd0gqVk5PbmhZeCplQTg4a042TFNET29KSDVobmpWNWZRZ3dwc3YtV0puaXRYc0txZzhsWWlZcTRmbkpTSHJpWjliNkVJRFdHOHpsdXZGcnFWZ2NJV0xReWFGVVpTWnRDeXlkVm5PRjllSXRVQ05MWVZ0MEJmWm1YUlBhdzJZMSp2eU5qMGEwKnFKUDV1UUstellFZGdKT2ZvbzJ4YVViZEJEaDFZOUNJZko1azhDWmpTb00yZWdjYmw4RlRZWHlFVXhKVlFjbFJsRXpoNkdXakpzOFN2bkRzeFJWaFAtNmxQM3NMN1AtWnVRU0kxR29seUVYd1dUY0pBY0RxSXgwSlk3R2dkbEp5OU9PMjUzdUJ3UnJMSnJ3RGJ5QkVLUEdVajhhUlVRei1hWkY5a0JJMkJUbDhWMkdGY2VxMmpJZ2doR0loYlIxbUNHSDMqNFlYdUNmbGpueVg0S1BtR0pIZTg4WmdmVXhWVTFCWnZSTVBKZFZzVlRCcFlHUFl6Tmh0YTg0cVpQaVV1STdibTJHNnpjR1AxMkl3eCo4dDE2YzNJWXVhRnp3NmdWZVBYZ0M3eUR2dzJjelRwdEpPSzJtblcxS2ZYUjBpY3V4dmZRZGp2blRKeVllSkVmVENNdkNYMHZJYjZUZTlxZkMqa2EqWGh3Tnp5QTQ5YmRlLVVxbi1QTE9lSWJNZTEtblBmSldwcmlCY3BiWlBRIn0.p7BV8U5chJSGUvdY9nyrrWeXUjCMWRF_bPCgSwU0h9U"
    }
}

let mockPayPalBillingAgreement = Response.Body.PayPal.ConfirmBillingAgreement(billingAgreementId: "agreementId", externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))

class MockLocator {
    static func registerDependencies() {
        let state: AppStateProtocol = MockAppState()
        state.apiConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(PrimerTheme() as PrimerThemeProtocol)
    }
}

final class MockTokenizationRequestBodyPaymentInstrument: TokenizationRequestBodyPaymentInstrument {}
