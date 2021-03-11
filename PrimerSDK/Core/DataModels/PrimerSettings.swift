public typealias ClientTokenCallBack = (_ completionHandler: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) -> Void
public typealias PaymentMethodTokenCallBack = (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
public typealias CheckoutDismissalCallback = () -> Void

protocol PrimerSettingsProtocol {
    var amount: Int? { get }
    var currency: Currency? { get }
    var merchantIdentifier: String? { get }
    var countryCode: CountryCode? { get }
    var applePayEnabled: Bool { get }
    var customerId: String? { get }
    var theme: PrimerTheme { get }
    var clientTokenRequestCallback: ClientTokenCallBack { get }
    var onTokenizeSuccess: PaymentMethodTokenCallBack { get }
    var onCheckoutDismiss: CheckoutDismissalCallback { get }
    var urlScheme: String? { get }
    var urlSchemeIdentifier: String? { get }
    var isFullScreenOnly: Bool { get }
    var hasDisabledSuccessScreen: Bool { get }
    var businessDetails: BusinessDetails? { get }
    var directDebitHasNoAmount: Bool { get }
}

public class PrimerSettings: PrimerSettingsProtocol {
    public let amount: Int?
    public let currency: Currency?
    public let merchantIdentifier: String?
    public let countryCode: CountryCode?
    public let applePayEnabled: Bool
    public let customerId: String?
    public let theme: PrimerTheme
    public let urlScheme: String?
    public let urlSchemeIdentifier: String?
    public let isFullScreenOnly: Bool
    public let hasDisabledSuccessScreen: Bool
    public let businessDetails: BusinessDetails?
    public let directDebitHasNoAmount: Bool
    
    public var clientTokenRequestCallback: ClientTokenCallBack {
        return delegate?.clientTokenCallback ?? { completion in }
    }
    
    public var onTokenizeSuccess: PaymentMethodTokenCallBack {
        return delegate?.authorizePayment ?? { result, completion in }
    }
    
    public var onCheckoutDismiss: CheckoutDismissalCallback {
        return delegate?.onCheckoutDismissed ?? {}
    }
    
    weak var delegate: PrimerDelegate?
    
    public init(
        delegate: PrimerDelegate,
        amount: Int? = nil,
        currency: Currency? = nil,
        theme: PrimerTheme = PrimerTheme(),
        applePayEnabled: Bool = false,
        customerId: String? = nil,
        merchantIdentifier: String? = nil,
        countryCode: CountryCode? = nil,
        urlScheme: String? = nil,
        urlSchemeIdentifier: String? = nil,
        isFullScreenOnly: Bool = false,
        hasDisabledSuccessScreen: Bool = false,
        businessDetails: BusinessDetails? = nil,
        directDebitHasNoAmount: Bool = false
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
        self.isFullScreenOnly = isFullScreenOnly
        self.hasDisabledSuccessScreen = hasDisabledSuccessScreen
        self.businessDetails = businessDetails
        self.directDebitHasNoAmount = directDebitHasNoAmount
    }
}

public struct BusinessDetails: Codable {
    public var name: String
    public var address: Address
    
    public init(name: String, address: Address) {
        self.name = name
        self.address = address
    }
}

class MockDelegate: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) {
        
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }
    
    func onCheckoutDismissed() {
        
    }
}
