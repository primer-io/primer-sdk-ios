//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

var mockClientToken = """
    eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MzQ2Mjc3MDcsImFjY2Vzc1Rva2VuIjoiYmxhIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9wcmltZXIuaW8iLCJpbnRlbnQiOiJibGEiLCJjb25maWd1cmF0aW9uVXJsIjoiYmxhIiwiY29yZVVybCI6Imh0dHBzOi8vcHJpbWVyLmlvIiwicGNpVXJsIjoiaHR0cHM6Ly9wcmltZXIuaW8iLCJlbnYiOiJibGEiLCJwYXltZW50RmxvdyI6ImJsYSJ9._GH4xNFOhlfY3CmyH8JcUEdqDIxZF8qYILcGY4YF7Vc
    """

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
            completion(nil, PrimerError.clientTokenNull)
            return
        }
        completion(token, nil)
    }
    
    func tokenAddedToVault(_ token: PaymentMethod) {
        
    }

    

    func authorizePayment(_ result: PaymentMethod, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.clientTokenNull) }
    }
    
    func onTokenizeSuccess(_ paymentMethod: PaymentMethod, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.clientTokenNull) }
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
    
    var orderItems: [OrderItem] = []

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

    var authorizePayment: PaymentMethodCallBack
    
    var onTokenizeSuccess: TokenizationSuccessCallBack
    
    var onCheckoutDismiss: CheckoutDismissalCallback

    init(
        clientTokenRequestCallback: @escaping ClientTokenCallBack = { _ in },
        authorizePayment: @escaping PaymentMethodCallBack = { _, _  in },
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
    var clientToken: String? = "access_token"
    
    var customerToken: String? = "customerToken"

    var authorizationToken: String? = "authToken"

    var sessionId: String? = "klarnaSessionId123"

    var directDebitMandate: DirectDebitMandate = DirectDebitMandate(firstName: "", lastName: "", email: "", iban: "", accountNumber: "", sortCode: "", address: nil)

    var directDebitFormCompleted: Bool = false

    var mandateId: String?

    var paymentMethods: [PaymentMethod] = []

    var selectedPaymentMethod: String = ""

    var paymentMethodConfig: PrimerConfiguration?

    var billingAgreementToken: String? = "token"

    var orderId: String? = "oid"

    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?

    var approveURL: String? = "approveUrl"

    init(
        clientToken: String? = mockClientToken,
        paymentMethodConfig: PrimerConfiguration? = PrimerConfiguration(
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
        self.clientToken = clientToken
        self.paymentMethodConfig = paymentMethodConfig
    }
}

let mockPayPalBillingAgreement = PayPalConfirmBillingAgreementResponse(billingAgreementId: "agreementId", externalPayerInfo: PayPalExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))

class MockLocator {
    static func registerDependencies() {
        let state: AppStateProtocol = MockAppState()
        state.paymentMethodConfig = mockPaymentMethodConfig
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
    func createMandate(_ completion: @escaping (String?, Error?) -> Void) {
        
    }
}

#endif
