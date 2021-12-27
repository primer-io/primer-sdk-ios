//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedClientToken(accessToken: "bla", exp: 2000000000, configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io")

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
    merchantIdentifier: "mid",
    customerId: "cid",
    amount: 200,
    currency: .GBP,
    countryCode: .gb,
    urlScheme: "urlScheme",
    urlSchemeIdentifier: "urlSchemeIdentifier",
    orderItems: [try! OrderItem(name: "foo", unitAmount: 200, quantity: 1)]
)

class MockPrimerDelegate: PrimerDelegate {

    var token: String?
    var authorizePaymentFails: Bool
    var clientTokenCallbackCalled = false
    var authorizePaymentCalled = false
    var onCheckoutDismissedCalled = false

    init(token: String? = nil, authorizePaymentFails: Bool = false) {
        self.token = token
        self.authorizePaymentFails = authorizePaymentFails
    }

    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        clientTokenCallbackCalled = true
        guard let token = token else {
            completion(nil, PrimerInternalError.invalidClientToken)
            return
        }
        completion(token, nil)
    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }

    

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerInternalError.invalidClientToken) }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerInternalError.invalidClientToken) }
    }

    func onCheckoutDismissed() {
        onCheckoutDismissedCalled = true
    }
    
    func checkoutFailed(with error: Error) {
        
    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {
    
    var debugOptions: PrimerDebugOptions
        
    var orderId: String?
    
    var billingAddress: Address?
    
    var is3DSOnVaultingEnabled: Bool
    var customer: Customer?
    
    var localeData: LocaleData { return LocaleData(languageCode: nil, regionCode: nil) }
    
    var merchantCapabilities: [MerchantCapability]?
    
    var supportedNetworks: [PaymentNetwork]?
    var isInitialLoadingHidden: Bool = false
    
    var klarnaPaymentDescription: String?
    
    var klarnaSessionType: KlarnaSessionType?
    
    var orderItems: [OrderItem]? = []

    var isFullScreenOnly: Bool {
        return false
    }

    var hasDisabledSuccessScreen: Bool {
        return false
    }

    var businessDetails: BusinessDetails?

    var directDebitHasNoAmount: Bool {
        return true
    }

    var urlScheme: String? = ""

    var urlSchemeIdentifier: String? = ""

    var amount: Int? = 100

    var currency: Currency? = .EUR

    var merchantIdentifier: String? = "mid"

    var countryCode: CountryCode? = .fr

    var applePayEnabled: Bool = false

    var customerId: String? = "cid"

    var theme: PrimerTheme { return PrimerTheme() }

    var clientTokenRequestCallback: ClientTokenCallBack

    var authorizePayment: PaymentMethodTokenCallBack
    
    var onTokenizeSuccess: TokenizationSuccessCallBack
    
    var onCheckoutDismiss: CheckoutDismissalCallback

    init(
        clientTokenRequestCallback: @escaping ClientTokenCallBack = { _ in },
        authorizePayment: @escaping PaymentMethodTokenCallBack = { _, _  in },
        onTokenizeSuccess: @escaping TokenizationSuccessCallBack = { _, _  in },
        onCheckoutDismiss: @escaping CheckoutDismissalCallback = { }
    ) {
        self.clientTokenRequestCallback = clientTokenRequestCallback
        self.authorizePayment = authorizePayment
        self.onCheckoutDismiss = onCheckoutDismiss
        self.onTokenizeSuccess = onTokenizeSuccess
        self.is3DSOnVaultingEnabled = true
        self.debugOptions = PrimerDebugOptions(is3DSSanityCheckEnabled: false)
    }
    
    func modify(withClientSession clientSession: ClientSession) {
        
    }
}

let mockPaymentMethodConfig = PrimerConfiguration(
    coreUrl: "url",
    pciUrl: "url",
    clientSession: nil,
    paymentMethods: [
        PaymentMethodConfig(id: "Klarna", options: nil, processorConfigId: nil, type: .klarna),
        PaymentMethodConfig(id: "PayPal", options: nil, processorConfigId: nil, type: .payPal),
        PaymentMethodConfig(id: "Apaya", options: ApayaOptions(merchantAccountId: "merchant_account_id"), processorConfigId: nil, type: .apaya)
    ],
    keys: nil
)

class MockAppState: AppStateProtocol {
    
    var clientToken: String?
    var primerConfiguration: PrimerConfiguration?
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethodToken: String?
    var selectedPaymentMethod: PaymentMethodToken?

    init(
        decodedClientToken: DecodedClientToken? = mockClientToken,
        primerConfiguration: PrimerConfiguration? = PrimerConfiguration(
            coreUrl: "url",
            pciUrl: "url",
            clientSession: nil,
            paymentMethods: [
                PaymentMethodConfig(id: "Klarna", options: nil, processorConfigId: nil, type: .klarna),
                PaymentMethodConfig(id: "PayPal", options: nil, processorConfigId: nil, type: .payPal),
                PaymentMethodConfig(id: "Apaya", options: ApayaOptions(merchantAccountId: "merchant_account_id"), processorConfigId: nil, type: .apaya)
            ],
            keys: nil
        )
    ) {
        self.clientToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MzQzMTcwODgsImFjY2Vzc1Rva2VuIjoiOTUxODRhNWYtMWMxNS00OGQ0LTk4MzYtYmM4ZWFkZmYzMzFiIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnN0YWdpbmcuY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zdGFnaW5nLnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJlbnYiOiJTVEFHSU5HIiwicGF5bWVudEZsb3ciOiJQUkVGRVJfVkFVTFQifQ.aybIRUso7r9LJcL3pg8_Rg2aVMHDUikcooA3KcCX43g"
        self.primerConfiguration = primerConfiguration
    }
}

let mockPayPalBillingAgreement = PayPalConfirmBillingAgreementResponse(billingAgreementId: "agreementId", externalPayerInfo: PayPalExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))

class MockLocator {
    static func registerDependencies() {
        let state: AppStateProtocol = MockAppState()
        state.primerConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        DependencyContainer.register(MockVaultService() as VaultServiceProtocol)
        DependencyContainer.register(MockClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(MockPaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(MockPayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(MockTokenizationService(paymentInstrumentType: PaymentMethodConfigType.paymentCard.rawValue, tokenType: TokenType.singleUse.rawValue) as TokenizationServiceProtocol)
        DependencyContainer.register(MockDirectDebitService() as DirectDebitServiceProtocol)
        DependencyContainer.register(MockVaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(MockVaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(MockExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(PrimerTheme() as PrimerThemeProtocol)
    }
}

class MockDirectDebitService: DirectDebitServiceProtocol {
    func createMandate(_ directDebitMandate: DirectDebitMandate, completion: @escaping (Error?) -> Void) {

    }
}

#endif
