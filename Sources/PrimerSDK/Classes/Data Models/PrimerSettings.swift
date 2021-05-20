#if canImport(UIKit)

public typealias ClientTokenCallBack = (_ completionHandler: @escaping (Result<String, Error>) -> Void) -> Void
public typealias PaymentMethodTokenCallBack = (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
public typealias CheckoutDismissalCallback = () -> Void

protocol PrimerSettingsProtocol {
    var amount: Int? { get }
    var currency: Currency? { get }
    var merchantIdentifier: String? { get }
    var countryCode: CountryCode? { get }
    var applePayEnabled: Bool { get }
    var klarnaSessionType: KlarnaSessionType? { get }
    var klarnaPaymentDescription: String? { get }
    var customerId: String? { get }
    var clientTokenRequestCallback: ClientTokenCallBack { get }
    var authorizePayment: PaymentMethodTokenCallBack { get }
    var onCheckoutDismiss: CheckoutDismissalCallback { get }
    var urlScheme: String? { get }
    var urlSchemeIdentifier: String? { get }
    var isFullScreenOnly: Bool { get }
    var hasDisabledSuccessScreen: Bool { get }
    var businessDetails: BusinessDetails? { get }
    var directDebitHasNoAmount: Bool { get }
    var orderItems: [OrderItem] { get }
//    var supportedNetworks: [PaymentNetwork]? { get }
//    var merchantCapabilities: [MerchantCapability]? { get }
    var isInitialLoadingHidden: Bool { get }
    var localeData: LocaleData { get }
}

/**
 Set the settings of your Primer integration. Various settings for the payment or the drop-in UI customization can be set
 
 - Parameters:
    - amount: The amount multiplied by 100
    - currency: Enum of available currencies
    - merchantIdentifier: The merchant's identifier.
    - countryCode: Enum of available countries.
    - applePayEnabled: Enable/Disable Apple Pay
    - customerId: Customer identifier
    - theme: **PrimerTheme** for the drop-in UI.
    - urlScheme: The URL scheme that has been set in the *Info.plist*
    - urlSchemeIdentifier: The URL scheme identifier that has been set in the *Info.plist*
    - isFullScreenOnly: Drop-in UI opearated in fullscreen only
    - hasDisabledSuccessScreen: Enable/Disable success screen on successful payment.
    - businessDetails: **BusinessDetails** object containing the details of payer's business.
 
 - Author: Primer
 
 - Version: 1.2.2
 */

public class PrimerSettings: PrimerSettingsProtocol {
    
    internal(set) public var amount: Int?
    internal(set) public var currency: Currency?
    internal(set) public var merchantIdentifier: String?
    internal(set) public var countryCode: CountryCode?
    internal(set) public var applePayEnabled: Bool
    internal(set) public var klarnaSessionType: KlarnaSessionType?
    internal(set) public var klarnaPaymentDescription: String?
    internal(set) public var customerId: String?
    internal(set) public var urlScheme: String?
    internal(set) public var urlSchemeIdentifier: String?
    internal(set) public var isFullScreenOnly: Bool
    internal(set) public var hasDisabledSuccessScreen: Bool
    internal(set) public var businessDetails: BusinessDetails?
    internal(set) public var directDebitHasNoAmount: Bool
    internal(set) public var orderItems: [OrderItem]
//    internal(set) public var supportedNetworks: [PaymentNetwork]?
//    internal(set) public var merchantCapabilities: [MerchantCapability]?
    internal(set) public var isInitialLoadingHidden: Bool
    internal(set) public var localeData: LocaleData

    public var clientTokenRequestCallback: ClientTokenCallBack {
        return Primer.shared.delegate?.clientTokenCallback ?? { _ in }
    }

    internal var authorizePayment: PaymentMethodTokenCallBack {
        return Primer.shared.delegate?.authorizePayment ?? { _, _ in }
    }

    public var onCheckoutDismiss: CheckoutDismissalCallback {
        return Primer.shared.delegate?.onCheckoutDismissed ?? {}
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    public init(
        merchantIdentifier: String? = nil,
        customerId: String? = nil,
        amount: Int? = nil,
        currency: Currency? = nil,
        countryCode: CountryCode? = nil,
        applePayEnabled: Bool = false,
        klarnaSessionType: KlarnaSessionType? = nil,
        klarnaPaymentDescription: String? = nil,
        urlScheme: String? = nil,
        urlSchemeIdentifier: String? = nil,
        isFullScreenOnly: Bool = false,
        hasDisabledSuccessScreen: Bool = false,
        businessDetails: BusinessDetails? = nil,
        directDebitHasNoAmount: Bool = false,
        orderItems: [OrderItem] = [],
//        supportedNetworks: [PaymentNetwork]? = nil,
//        merchantCapabilities: [MerchantCapability]? = nil,
        isInitialLoadingHidden: Bool = false,
        localeData: LocaleData? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.applePayEnabled = applePayEnabled
        self.klarnaSessionType = klarnaSessionType
        self.klarnaPaymentDescription = klarnaPaymentDescription
        self.customerId = customerId
        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
        self.urlScheme = urlScheme
        self.urlSchemeIdentifier = urlSchemeIdentifier
        self.isFullScreenOnly = isFullScreenOnly
        self.hasDisabledSuccessScreen = hasDisabledSuccessScreen
        self.businessDetails = businessDetails
        self.directDebitHasNoAmount = directDebitHasNoAmount
        self.orderItems = orderItems
//        self.supportedNetworks = supportedNetworks
//        self.merchantCapabilities = merchantCapabilities
        self.isInitialLoadingHidden = isInitialLoadingHidden
        self.localeData = localeData ?? LocaleData(languageCode: nil, regionCode: nil)
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
    
    func clientTokenCallback(_ completion: @escaping (Result<String, Error>) -> Void) {

    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
            
    }

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {

    }

    func onCheckoutDismissed() {

    }
    
    func checkoutFailed(with error: Error) {
        
    }
    
}

#endif
