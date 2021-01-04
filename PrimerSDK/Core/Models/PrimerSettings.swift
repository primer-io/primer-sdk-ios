public typealias ClientTokenCallBack = (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
public typealias PaymentMethodTokenCallBack = (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void

public struct PrimerSettings {
    public let uxMode: UXMode
    public let amount: Int
    public let currency: Currency
    public let merchantIdentifier: String?
    public let countryCode: CountryCode?
    public let applePayEnabled: Bool
    public let customerId: String?
    public let theme: PrimerTheme
    public let clientTokenRequestCallback: ClientTokenCallBack
    public let onTokenizeSuccess: PaymentMethodTokenCallBack
    
    public init(
        amount: Int,
        currency: Currency,
        clientTokenRequestCallback: @escaping ClientTokenCallBack,
        onTokenizeSuccess: @escaping PaymentMethodTokenCallBack,
        theme: PrimerTheme = PrimerTheme.init(),
        uxMode: UXMode = .CHECKOUT,
        applePayEnabled: Bool = false,
        customerId: String? = nil,
        merchantIdentifier: String? = nil,
        countryCode: CountryCode? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.clientTokenRequestCallback = clientTokenRequestCallback
        self.onTokenizeSuccess = onTokenizeSuccess
        self.theme = theme
        self.uxMode = uxMode
        self.applePayEnabled = applePayEnabled
        self.customerId = customerId
        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
    }
}
