//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

@testable import PrimerSDK

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
    delegate: MockPrimerCheckoutDelegate(),
    amount: 200,
    currency: .EUR,
    theme: PrimerTheme(),
    applePayEnabled: false,
    customerId: "cid",
    merchantIdentifier: "mid",
    countryCode: .fr,
    urlScheme: "urlScheme",
    urlSchemeIdentifier: "urlSchemeIdentifier"
)

class MockPrimerCheckoutDelegate: PrimerCheckoutDelegate {
    
    var tokenData: CreateClientTokenResponse?
    var authorizePaymentFails: Bool
    
    init(tokenData: CreateClientTokenResponse? = nil, authorizePaymentFails: Bool = false) {
        self.tokenData = tokenData
        self.authorizePaymentFails = authorizePaymentFails
    }
    
    var clientTokenCallbackCalled = false
    
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) {
        clientTokenCallbackCalled = true
        guard let data = tokenData else { return }
        completion(.success(data))
    }
    
    var authorizePaymentCalled = false
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if (authorizePaymentFails) { completion(PrimerError.ClientTokenNull) }
    }
    
    var onCheckoutDismissedCalled = false
    
    func onCheckoutDismissed() {
        onCheckoutDismissedCalled = true
    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {
    var urlScheme: String = ""
    
    var urlSchemeIdentifier: String = ""
    
    var amount: Int { return 200 }
    
    var currency: Currency { return .EUR }
    
    var merchantIdentifier: String? { return "mid"}
    
    var countryCode: CountryCode? { return .fr }
    
    var applePayEnabled: Bool { return false }
    
    var customerId: String? { return "cid" }
    
    var theme: PrimerTheme { return PrimerTheme() }
    
    var clientTokenRequestCallback: ClientTokenCallBack
    
    var onTokenizeSuccess: PaymentMethodTokenCallBack
    
    var onCheckoutDismiss: CheckoutDismissalCallback
    
    init(
        clientTokenRequestCallback: @escaping ClientTokenCallBack = { result in },
        onTokenizeSuccess: @escaping PaymentMethodTokenCallBack = { token, error  in },
        onCheckoutDismiss: @escaping CheckoutDismissalCallback = { }
    ) {
        self.clientTokenRequestCallback = clientTokenRequestCallback
        self.onTokenizeSuccess = onTokenizeSuccess
        self.onCheckoutDismiss = onCheckoutDismiss
    }
}

class MockAppState: AppStateProtocol {
    
    var settings: PrimerSettingsProtocol
    
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
        settings: PrimerSettingsProtocol = mockSettings,
        decodedClientToken: DecodedClientToken? = mockClientToken,
        paymentMethodConfig: PaymentMethodConfig? = PaymentMethodConfig(coreUrl: "url", pciUrl: "url", paymentMethods: [
            ConfigPaymentMethod(id: "id", type: .PAYPAL)
        ])
    ) {
        self.settings = settings
        self.decodedClientToken = decodedClientToken
        self.paymentMethodConfig = paymentMethodConfig
    }
}

class MockServiceLocator: ServiceLocatorProtocol {
    var clientTokenService: ClientTokenServiceProtocol
    var paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    var paypalService: PayPalServiceProtocol
    var tokenizationService: TokenizationServiceProtocol
    var vaultService: VaultServiceProtocol
    
    init (
        clientTokenService: ClientTokenServiceProtocol = MockClientTokenService(),
        paymentMethodConfigService: PaymentMethodConfigServiceProtocol = MockPaymentMethodConfigService(),
        paypalService: PayPalServiceProtocol = MockPayPalService(),
        tokenizationService: TokenizationServiceProtocol = MockTokenizationService(),
        vaultService: VaultServiceProtocol = MockVaultService()
    ) {
        self.clientTokenService = clientTokenService
        self.paymentMethodConfigService = paymentMethodConfigService
        self.paypalService = paypalService
        self.tokenizationService = tokenizationService
        self.vaultService = vaultService
    }
}

class MockViewModelLocator: ViewModelLocatorProtocol {
    var applePayViewModel: ApplePayViewModelProtocol { return MockApplePayViewModel() }
    
    var cardFormViewModel: CardFormViewModelProtocol { return MockCardFormViewModel() }
    
    var cardScannerViewModel: CardScannerViewModelProtocol { return MockCardScannerViewModel() }
    
    var directCheckoutViewModel: DirectCheckoutViewModelProtocol { return MockDirectCheckoutViewModel() }
    
    var oAuthViewModel: OAuthViewModelProtocol { return MockOAuthViewModel() }
    
    var vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol { return MockVaultPaymentMethodViewModel() }
    
    var vaultCheckoutViewModel: VaultCheckoutViewModelProtocol { return MockVaultCheckoutViewModel() }
    
    var ibanFormViewModel: IBANFormViewModelProtocol { return MockIBANFormViewModel() }
    
    var confirmMandateViewModel: ConfirmMandateViewModelProtocol { return MockConfirmMandateViewModel() }
    
    var externalViewModel: ExternalViewModelProtocol { return MockExternalViewModel() }
}

class MockCheckoutContext: CheckoutContextProtocol {
    var state: AppStateProtocol
    var settings: PrimerSettingsProtocol
    var serviceLocator: ServiceLocatorProtocol
    var viewModelLocator: ViewModelLocatorProtocol
    
    init(
        state: AppStateProtocol = MockAppState(),
        settings: PrimerSettingsProtocol = mockSettings,
        serviceLocator: ServiceLocatorProtocol = MockServiceLocator(),
        viewModelLocator: ViewModelLocatorProtocol = MockViewModelLocator()
    ) {
        self.state = state
        self.settings = settings
        self.serviceLocator = serviceLocator
        self.viewModelLocator = viewModelLocator
    }
}


let mockPayPalBillingAgreement = PayPalConfirmBillingAgreementResponse(billingAgreementId: "agreementId", externalPayerInfo: PayPalExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))
