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
    
    var amount: Int? { return 200 }
    
    var currency: Currency? { return .EUR }
    
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
    
    var cardData: CardData = CardData(name: "", number: "", expiryYear: "", expiryMonth: "", cvc: "")
    
    
    var routerState: RouterState = RouterState()
    
    var directDebitMandate: DirectDebitMandate = DirectDebitMandate(firstName: "", lastName: "", email: "", iban: "", accountNumber: "", sortCode: "", address: nil)
    
    var directDebitFormCompleted: Bool = false
    
    var mandateId: String?
    
    var settings: PrimerSettingsProtocol = MockPrimerSettings()
    
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

let mockPayPalBillingAgreement = PayPalConfirmBillingAgreementResponse(billingAgreementId: "agreementId", externalPayerInfo: PayPalExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))


class MockLocator {
    static func registerDependencies() {
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(MockAppState() as AppStateProtocol)
        DependencyContainer.register(MockAPIClient() as APIClientProtocol)
        DependencyContainer.register(MockVaultService() as VaultServiceProtocol)
        DependencyContainer.register(MockClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(MockPaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(MockPayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(MockTokenizationService() as TokenizationServiceProtocol)
        DependencyContainer.register(MockDirectDebitService() as DirectDebitServiceProtocol)
        DependencyContainer.register(MockApplePayViewModel() as ApplePayViewModelProtocol)
        DependencyContainer.register(MockCardFormViewModel() as CardFormViewModelProtocol)
        DependencyContainer.register(MockCardScannerViewModel() as CardScannerViewModelProtocol)
        DependencyContainer.register(MockDirectCheckoutViewModel() as DirectCheckoutViewModelProtocol)
        DependencyContainer.register(MockOAuthViewModel() as OAuthViewModelProtocol)
        DependencyContainer.register(MockVaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(MockVaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(MockConfirmMandateViewModel() as ConfirmMandateViewModelProtocol)
        DependencyContainer.register(MockFormViewModel() as FormViewModelProtocol)
        DependencyContainer.register(MockExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(MockRouter() as RouterDelegate)
    }
}

class MockDirectDebitService: DirectDebitServiceProtocol {
    func createMandate(_ completion: @escaping (Error?) -> Void) {
        
    }
}

class MockRouter: RouterDelegate {
    func setRoot(_ root: RootViewController) {
        
    }
    
    func show(_ route: Route) {
        
    }
    
    func pop() {
        
    }
    
    func popAllAndShow(_ route: Route) {
        
    }
    
    func popAndShow(_ route: Route) {
        
    }
}

class MockFormViewModel: FormViewModelProtocol {
    var popOnComplete: Bool = false
    
    func getSubmitButtonTitle(formType: FormType) -> String {
        return "title"
    }
    
    func onSubmit(formType: FormType) {
        
    }
    
    func onBottomLinkTapped(delegate: CardScannerViewControllerDelegate) {
        
    }
    
    func submit(completion: @escaping (PrimerError?) -> Void) {
        
    }
    
    func onReturnButtonTapped() {
        
    }
    
    var mandate: DirectDebitMandate = DirectDebitMandate(firstName: "", lastName: "", email: "", iban: "", accountNumber: "", sortCode: "", address: nil)
    
    func setState(_ value: String?, type: FormTextFieldType) {
        
    }
}
