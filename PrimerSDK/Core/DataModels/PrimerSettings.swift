public typealias ClientTokenCallBack = (_ completionHandler: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) -> Void
public typealias PaymentMethodTokenCallBack = (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
public typealias CheckoutDismissalCallback = () -> Void

protocol PrimerSettingsProtocol {
    var amount: Int { get }
    var currency: Currency { get }
    var merchantIdentifier: String? { get }
    var countryCode: CountryCode? { get }
    var applePayEnabled: Bool { get }
    var customerId: String? { get }
    var theme: PrimerTheme { get }
    var clientTokenRequestCallback: ClientTokenCallBack { get }
    var onTokenizeSuccess: PaymentMethodTokenCallBack { get }
    var onCheckoutDismiss: CheckoutDismissalCallback { get }
    var urlScheme: String { get }
    var urlSchemeIdentifier: String { get }
}

public class PrimerSettings: PrimerSettingsProtocol {
    public let amount: Int
    public let currency: Currency
    public let merchantIdentifier: String?
    public let countryCode: CountryCode?
    public let applePayEnabled: Bool
    public let customerId: String?
    public let theme: PrimerTheme
    public let urlScheme: String
    public let urlSchemeIdentifier: String
    
    public var clientTokenRequestCallback: ClientTokenCallBack {
        return delegate?.clientTokenCallback ?? { completion in }
    }
    
    public var onTokenizeSuccess: PaymentMethodTokenCallBack {
        return delegate?.authorizePayment ?? { result, completion in }
    }
    
    public var onCheckoutDismiss: CheckoutDismissalCallback {
        return delegate?.onCheckoutDismissed ?? {}
    }
    
    weak var delegate: PrimerCheckoutDelegate?
    
    public init(
        delegate: PrimerCheckoutDelegate,
        amount: Int,
        currency: Currency,
        theme: PrimerTheme = PrimerTheme.init(),
        applePayEnabled: Bool = false,
        customerId: String? = nil,
        merchantIdentifier: String? = nil,
        countryCode: CountryCode? = nil,
        urlScheme: String,
        urlSchemeIdentifier: String
    ) {
        self.amount = amount
        self.currency = currency
        self.theme = theme
        self.applePayEnabled = applePayEnabled
        self.customerId = customerId
        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
        self.urlScheme = urlScheme
        self.urlSchemeIdentifier = urlSchemeIdentifier
        self.delegate = delegate
    }
}
