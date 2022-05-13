//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedClientToken(accessToken: "bla", exp: 2000000000, configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil)

//(
//    accessToken: "bla",
//    configurationUrl: "bla",
//    paymentFlow: "bla",
//    threeDSecureInitUrl: "bla",
//    threeDSecureToken: "bla",
//    coreUrl: "https://primer.io",
//    pciUrl: "https://primer.io",
//    env: "bla"
//)

var mockSettings = PrimerSettings(
    paymentMethodOptions: PrimerPaymentMethodOptions(
        urlScheme: "urlScheme",
        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "mid")
    )
)

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
            completion(nil, PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
            return
        }
        completion(token, nil)
    }
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {

    }

    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }

    

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
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
    var debugOptions = PrimerDebugOptions()
}

let mockPaymentMethodConfig = PrimerAPIConfiguration(
    coreUrl: "url",
    pciUrl: "url",
    clientSession: nil,
    paymentMethods: [
        PaymentMethodConfig(id: "Klarna", options: nil, processorConfigId: nil, type: .klarna),
        PaymentMethodConfig(id: "PayPal", options: nil, processorConfigId: nil, type: .payPal),
        PaymentMethodConfig(id: "Apaya", options: ApayaOptions(merchantAccountId: "merchant_account_id"), processorConfigId: nil, type: .apaya)
    ],
    keys: nil,
    checkoutModules: nil
)

class MockAppState: AppStateProtocol {
    
    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PaymentMethodToken?
    var implementedReactNativeCallbacks: ImplementedReactNativeCallbacks?

    init(
        decodedClientToken: DecodedClientToken? = mockClientToken,
        apiConfiguration: PrimerAPIConfiguration? = PrimerAPIConfiguration(
            coreUrl: "url",
            pciUrl: "url",
            clientSession: nil,
            paymentMethods: [
                PaymentMethodConfig(id: "Klarna", options: nil, processorConfigId: nil, type: .klarna),
                PaymentMethodConfig(id: "PayPal", options: nil, processorConfigId: nil, type: .payPal),
                PaymentMethodConfig(id: "Apaya", options: ApayaOptions(merchantAccountId: "merchant_account_id"), processorConfigId: nil, type: .apaya)
            ],
            keys: nil,
            checkoutModules: nil
        )
    ) {
        self.clientToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MzQzMTcwODgsImFjY2Vzc1Rva2VuIjoiOTUxODRhNWYtMWMxNS00OGQ0LTk4MzYtYmM4ZWFkZmYzMzFiIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnN0YWdpbmcuY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zdGFnaW5nLnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJlbnYiOiJTVEFHSU5HIiwicGF5bWVudEZsb3ciOiJQUkVGRVJfVkFVTFQifQ.aybIRUso7r9LJcL3pg8_Rg2aVMHDUikcooA3KcCX43g"
        self.apiConfiguration = apiConfiguration
    }
}

let mockPayPalBillingAgreement = PayPalConfirmBillingAgreementResponse(billingAgreementId: "agreementId", externalPayerInfo: ExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))

class MockLocator {
    static func registerDependencies() {
        let state: AppStateProtocol = MockAppState()
        state.apiConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        DependencyContainer.register(MockVaultService() as VaultServiceProtocol)
        DependencyContainer.register(MockClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(MockPaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(MockPayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(MockTokenizationService(paymentInstrumentType: PrimerPaymentMethodType.paymentCard.rawValue, tokenType: TokenType.singleUse.rawValue) as TokenizationServiceProtocol)
        DependencyContainer.register(MockVaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(MockVaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(MockExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(PrimerTheme() as PrimerThemeProtocol)
        DependencyContainer.register(MockCreateResumePaymentService() as CreateResumePaymentServiceProtocol)
    }
}

#endif
