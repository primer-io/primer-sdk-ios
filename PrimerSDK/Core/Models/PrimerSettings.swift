public typealias ClientTokenCallBack = (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
public typealias PaymentMethodTokenCallBack = (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
public typealias CheckoutDismissalCallback = () -> Void

public struct PrimerSettings {
    public let amount: Int
    public let currency: Currency
    public let merchantIdentifier: String?
    public let countryCode: CountryCode?
    public let applePayEnabled: Bool
    public let customerId: String?
    public let theme: PrimerTheme
    public let clientTokenRequestCallback: ClientTokenCallBack
    public let onTokenizeSuccess: PaymentMethodTokenCallBack
    public let onCheckoutDismiss: CheckoutDismissalCallback
    
    public init(
        delegate: PrimerCheckoutDelegate,
        amount: Int,
        currency: Currency,
        theme: PrimerTheme = PrimerTheme.init(),
        applePayEnabled: Bool = false,
        customerId: String? = nil,
        merchantIdentifier: String? = nil,
        countryCode: CountryCode? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.clientTokenRequestCallback = delegate.clientTokenCallback
        self.onTokenizeSuccess = delegate.authorizePayment
        self.theme = theme
        self.applePayEnabled = applePayEnabled
        self.customerId = customerId
        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
        self.onCheckoutDismiss = delegate.onCheckoutDismissed
    }
}
