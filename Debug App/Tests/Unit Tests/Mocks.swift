//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedJWTToken(accessToken: "bla", expDate: Date(timeIntervalSince1970: 2000000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", supportedThreeDsProtocolVersions: nil, coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: nil, backendCallbackUrl: nil, primerTransactionId: nil, iPay88PaymentMethodId: nil, iPay88ActionType: nil, supportedCurrencyCode: nil, supportedCountry: nil, nolPayTransactionNo: nil)

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

    static var decodedJWTToken = DecodedJWTToken(accessToken: "bla", expDate: Date(timeIntervalSince1970: 2000000000), configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", supportedThreeDsProtocolVersions: nil, coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil, accountNumber: nil, backendCallbackUrl: nil, primerTransactionId: nil, iPay88PaymentMethodId: nil, iPay88ActionType: nil, supportedCurrencyCode: nil, supportedCountry: nil, nolPayTransactionNo: nil)

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

    static var payment = Response.Body.Payment(
        id: "mock_id",
        paymentId: "mock_payment_id",
        amount: 1000,
        currencyCode: "EUR",
        customer: nil,
        customerId: "mock_customer_id",
        dateStr: nil,
        order: nil,
        orderId: nil,
        requiredAction: nil,
        status: .success,
        paymentFailureReason: nil)

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
            static var klarnaPaymentMethodId = "mock_klarna_payment_method_id"
            static var paymentCardPaymentMethodId = "mock_payment_card_payment_method_id"
            static var nolPaymentMethodId = "mock_nol_payment_method_id"

            static var webRedirectPaymentMethodType = "MOCK_WEB_REDIRECT_PAYMENT_METHOD_TYPE"
            static var adyenGiroPayRedirectPaymentMethodType = "MOCK_ADYEN_GIROPAY_PAYMENT_METHOD_TYPE"
            static var klarnaPaymentMethodType = "MOCK_KLARNA_PAYMENT_METHOD_TYPE"
            static var paymentCardPaymentMethodType = "MOCK_PAYMENT_CARD_PAYMENT_METHOD_TYPE"

            static var webRedirectPaymentMethodName = "Mock Web Redirect Payment Method"
            static var adyenGiroPayRedirectPaymentMethodName = "Mock Adyen GiroPay Payment Method"
            static var klarnaPaymentMethodName = "Mock Klarna Payment Method"
            static var paymentCardPaymentMethodName = "Mock Payment Card Payment Method"
            static var nolPaymentMethodName = "Mock NOL Payment Method"

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
            options: MerchantOptions(merchantId: "user8", merchantAccountId: "123", appId: "test", extraMerchantData: nil),
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
    }
}

class MockPrimerDelegate: PrimerDelegate {

    var token: String?
    var authorizePaymentFails: Bool
    var clientTokenCallbackCalled = false
    var authorizePaymentCalled = false
    var primerDidDismissCalled = false

    init(token: String? = nil, authorizePaymentFails: Bool = false) {
        self.token = token
        self.authorizePaymentFails = authorizePaymentFails
    }

    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        clientTokenCallbackCalled = true
        guard let token = token else {
            completion(nil, PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                      "class": "\(Self.self)",
                                                                      "function": #function,
                                                                      "line": "\(#line)"], diagnosticsId: UUID().uuidString))
            return
        }
        completion(token, nil)
    }

    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {

    }

    func tokenAddedToVault(_ token: PrimerPaymentMethodTokenData) {

    }

    func authorizePayment(_ result: PrimerPaymentMethodTokenData, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                                        "class": "\(Self.self)",
                                                                                        "function": #function,
                                                                                        "line": "\(#line)"], diagnosticsId: UUID().uuidString)) }
    }

    func onTokenizeSuccess(_ paymentMethodToken: PrimerPaymentMethodTokenData, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                                        "class": "\(Self.self)",
                                                                                        "function": #function,
                                                                                        "line": "\(#line)"], diagnosticsId: UUID().uuidString)) }
    }

    func primerDidDismiss() {
        primerDidDismissCalled = true
    }

    func primerDidFailWithError(_ error: Error) {

    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {

    var paymentHandling = PrimerPaymentHandling.auto
    var localeData = PrimerLocaleData()
    var paymentMethodOptions = PrimerPaymentMethodOptions()
    var uiOptions = PrimerUIOptions()
    var threeDsOptions = PrimerThreeDsOptions()
    var debugOptions = PrimerDebugOptions()
}

let mockPaymentMethodConfig = PrimerAPIConfiguration(
    coreUrl: "url",
    pciUrl: "url",
    binDataUrl: "url",
    assetsUrl: "https://assets.staging.core.primer.io",
    clientSession: nil,
    paymentMethods: [
        PrimerPaymentMethod(id: "klarna-test", implementationType: .nativeSdk, type: "KLARNA", name: "Klarna", processorConfigId: "klarna-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
        PrimerPaymentMethod(id: "paypal-test", implementationType: .nativeSdk, type: "PAYPAL", name: "PayPal", processorConfigId: "paypal-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
        PrimerPaymentMethod(id: "apaya-test", implementationType: .nativeSdk, type: "APAYA", name: "Apaya", processorConfigId: "apaya-processor-config-id", surcharge: nil, options: MerchantOptions(merchantId: "merchant-id", merchantAccountId: "merchant-account-id", appId: "app-id", extraMerchantData: nil), displayMetadata: nil)
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

    var amount: Int? {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.merchantAmount ?? AppState.current.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }

    var currency: Currency? {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.currencyCode
    }

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
                PrimerPaymentMethod(id: "paypal-test", implementationType: .nativeSdk, type: "PAYPAL", name: "PayPal", processorConfigId: "paypal-processor-config-id", surcharge: nil, options: nil, displayMetadata: nil),
                PrimerPaymentMethod(id: "apaya-test", implementationType: .nativeSdk, type: "APAYA", name: "Apaya", processorConfigId: "apaya-processor-config-id", surcharge: nil, options: MerchantOptions(merchantId: "merchant-id", merchantAccountId: "merchant-account-id", appId: "app-id", extraMerchantData: nil), displayMetadata: nil)
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

class MockPrimerAPIConfigurationModule: PrimerAPIConfigurationModuleProtocol {

    static var apiClient: PrimerAPIClientProtocol?

    static var clientToken: JWTToken? {
        return PrimerAPIConfigurationModule.clientToken
    }

    static var decodedJWTToken: DecodedJWTToken? {
        return PrimerAPIConfigurationModule.decodedJWTToken
    }

    static var apiConfiguration: PrimerAPIConfiguration? {
        return PrimerAPIConfigurationModule.apiConfiguration
    }

    static func resetSession() {
        PrimerAPIConfigurationModule.resetSession()
    }

    // MARK: - MOCKED PROPERTIES

    var mockedNetworkDelay: TimeInterval = 2
    var mockedAPIConfiguration: PrimerAPIConfiguration?

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) -> Promise<Void> {
        return Promise { seal in
            guard let mockedAPIConfiguration = mockedAPIConfiguration else {
                XCTAssert(false, "Set 'mockedAPIConfiguration' on your MockPrimerAPIConfigurationModule")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
                PrimerAPIConfigurationModule.clientToken = clientToken
                PrimerAPIConfigurationModule.apiConfiguration = mockedAPIConfiguration
                seal.fulfill()
            }
        }
    }

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { _ in
            guard let mockedAPIConfiguration = mockedAPIConfiguration else {
                XCTAssert(false, "Set 'mockedAPIConfiguration' on your MockPrimerAPIConfigurationModule")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
                PrimerAPIConfigurationModule.apiConfiguration = mockedAPIConfiguration
            }
        }
    }

    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void> {
        return Promise { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
                PrimerAPIConfigurationModule.clientToken = newClientToken
            }
        }
    }
}
