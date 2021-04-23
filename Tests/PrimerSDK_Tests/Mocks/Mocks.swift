//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

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
    merchantIdentifier: "mid",
    customerId: "cid",
    amount: 200,
    currency: .EUR,
    countryCode: .fr,
    applePayEnabled: false,
    urlScheme: "urlScheme",
    urlSchemeIdentifier: "urlSchemeIdentifier",
    orderItems: [OrderItem(name: "foo", unitAmount: 200, quantity: 1)]
)

class MockPrimerDelegate: PrimerDelegate {

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
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }

    var authorizePaymentCalled = false

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.clientTokenNull) }
    }

    var onCheckoutDismissedCalled = false

    func onCheckoutDismissed() {
        onCheckoutDismissedCalled = true
    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {
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
        clientTokenRequestCallback: @escaping ClientTokenCallBack = { _ in },
        onTokenizeSuccess: @escaping PaymentMethodTokenCallBack = { _, _  in },
        onCheckoutDismiss: @escaping CheckoutDismissalCallback = { }
    ) {
        self.clientTokenRequestCallback = clientTokenRequestCallback
        self.onTokenizeSuccess = onTokenizeSuccess
        self.onCheckoutDismiss = onCheckoutDismiss
    }
}

class MockAppState: AppStateProtocol {
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
                ConfigPaymentMethod(id: "1", type: .klarna),
                ConfigPaymentMethod(id: "2", type: .payPal)
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
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(MockAppState() as AppStateProtocol)
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        DependencyContainer.register(MockVaultService() as VaultServiceProtocol)
        DependencyContainer.register(MockClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(MockPaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(MockPayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(MockTokenizationService() as TokenizationServiceProtocol)
        DependencyContainer.register(MockDirectDebitService() as DirectDebitServiceProtocol)
        DependencyContainer.register(MockKlarnaService() as KlarnaServiceProtocol)
        DependencyContainer.register(MockApplePayViewModel() as ApplePayViewModelProtocol)
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
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        
    }
    
    var popOnComplete: Bool = false

    func getSubmitButtonTitle(formType: FormType) -> String {
        return "title"
    }

    func onSubmit(formType: FormType) {

    }

//    func onBottomLinkTapped(delegate: CardScannerViewControllerDelegate) {
//        
//    }

    func submit(completion: @escaping (PrimerError?) -> Void) {

    }

    func onReturnButtonTapped() {

    }

    var mandate: DirectDebitMandate = DirectDebitMandate(firstName: "", lastName: "", email: "", iban: "", accountNumber: "", sortCode: "", address: nil)

    func setState(_ value: String?, type: FormTextFieldType) {

    }
}

#endif
