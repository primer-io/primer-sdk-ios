//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedClientToken(
    accessToken: "bla",
    configurationUrl: "bla",
    paymentFlow: "bla",
    threeDSecureInitUrl: "bla",
    threeDSecureToken: "bla",
    coreUrl: "https://primer.io",
    pciUrl: "https://primer.io",
    env: "bla"
)

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
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }

    

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.clientTokenNull) }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
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
    }
}

let mockPaymentMethodConfig = PaymentMethodConfig(
    coreUrl: "url",
    pciUrl: "url",
    paymentMethods: [
        ConfigPaymentMethod(id: "1", type: .klarna, processorConfigId: nil, options: nil),
        ConfigPaymentMethod(id: "2", type: .payPal, processorConfigId: nil, options: nil),
        ConfigPaymentMethod(id: "3", type: .apaya, processorConfigId: nil, options: PaymentMethodConfigOptions(merchantAccountId: "merchantAccountId"))
    ]
)

class MockAppState: AppStateProtocol {
    var apayaResult: Result<Apaya.WebViewResult, Error>?
    
    var setApayaResultCalled = false
    func setApayaResult(_ result: Result<Apaya.WebViewResult, Error>) {
        setApayaResultCalled = true
        apayaResult = result
    }
    
    var getApayaResultCalled = false
    func getApayaResult() -> Result<Apaya.WebViewResult, Error>? {
        getApayaResultCalled = true
        let url = URL(string: "https://primer.io") // needs query params
        return apayaResult ?? Apaya.WebViewResult.create(from: url)
    }
    
    var customerToken: String? = "customerToken"

    var authorizationToken: String? = "authToken"

    var sessionId: String? = "klarnaSessionId123"

    var cardData: CardData = CardData(name: "", number: "", expiryYear: "", expiryMonth: "", cvc: "")

    var routerState: RouterState = RouterState()

    var directDebitMandate: DirectDebitMandate = DirectDebitMandate(firstName: "", lastName: "", email: "", iban: "", accountNumber: "", sortCode: "", address: nil)

    var directDebitFormCompleted: Bool = false

    var mandateId: String?

    var viewModels: [PaymentMethodViewModel] = []

    var paymentMethods: [PaymentMethodToken] = []

    var selectedPaymentMethod: String = ""

    var decodedClientToken: DecodedClientToken? = mockClientToken

    var paymentMethodConfig: PaymentMethodConfig?

    var accessToken: String? = "accessToken"

    var billingAgreementToken: String? = "token"

    var orderId: String? = "oid"

    var confirmedBillingAgreement: PayPalConfirmBillingAgreementResponse?

    var approveURL: String? = "approveUrl"

    init(
        decodedClientToken: DecodedClientToken? = mockClientToken,
        paymentMethodConfig: PaymentMethodConfig? = PaymentMethodConfig(
            coreUrl: "url",
            pciUrl: "url",
            paymentMethods: [
                ConfigPaymentMethod(id: "1", type: .klarna, processorConfigId: nil, options: nil),
                ConfigPaymentMethod(id: "2", type: .payPal, processorConfigId: nil, options: nil)
            ]
        )
    ) {
        self.decodedClientToken = decodedClientToken
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
        DependencyContainer.register(MockTokenizationService() as TokenizationServiceProtocol)
        DependencyContainer.register(MockDirectDebitService() as DirectDebitServiceProtocol)
        DependencyContainer.register(MockKlarnaService() as KlarnaServiceProtocol)
//        DependencyContainer.register(MockApplePayViewModel() as ApplePayViewModelProtocol)
        DependencyContainer.register(MockCardScannerViewModel() as CardScannerViewModelProtocol)
        DependencyContainer.register(MockDirectCheckoutViewModel() as DirectCheckoutViewModelProtocol)
        DependencyContainer.register(MockOAuthViewModel() as OAuthViewModelProtocol)
        DependencyContainer.register(MockVaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(MockVaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(MockConfirmMandateViewModel() as ConfirmMandateViewModelProtocol)
        DependencyContainer.register(MockExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(PrimerTheme() as PrimerThemeProtocol)
    }
}

class MockDirectDebitService: DirectDebitServiceProtocol {
    func createMandate(_ completion: @escaping (Error?) -> Void) {

    }
}

#endif
