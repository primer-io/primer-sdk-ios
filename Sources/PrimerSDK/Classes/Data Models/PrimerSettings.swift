#if canImport(UIKit)

// MARK: - PRIMER SETTINGS

internal protocol PrimerSettingsProtocol {
    var paymentHandling: PrimerPaymentHandling { get }
    var localeData: PrimerLocaleData { get }
    var paymentMethodOptions: PrimerPaymentMethodOptions { get }
    var uiOptions: PrimerUIOptions { get }
    var debugOptions: PrimerDebugOptions { get }
}

public class PrimerSettings: PrimerSettingsProtocol {
    
    static var current: PrimerSettings {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings as! PrimerSettings
    }
    let paymentHandling: PrimerPaymentHandling
    let localeData: PrimerLocaleData
    let paymentMethodOptions: PrimerPaymentMethodOptions
    let uiOptions: PrimerUIOptions
    let debugOptions: PrimerDebugOptions
    
    public init(
        paymentHandling: PrimerPaymentHandling = .auto,
        localeData: PrimerLocaleData? = nil,
        paymentMethodOptions: PrimerPaymentMethodOptions? = nil,
        uiOptions: PrimerUIOptions? = nil,
        debugOptions: PrimerDebugOptions? = nil
    ) {
        self.paymentHandling = paymentHandling
        self.localeData = localeData ?? PrimerLocaleData()
        self.paymentMethodOptions = paymentMethodOptions ?? PrimerPaymentMethodOptions()
        self.uiOptions = uiOptions ?? PrimerUIOptions()
        self.debugOptions = debugOptions ?? PrimerDebugOptions()
    }
}

// MARK: - PAYMENT HANDLING

public enum PrimerPaymentHandling {
    case auto
    case manual
}

// MARK: - PAYMENT METHOD OPTIONS

internal protocol PrimerPaymentMethodOptionsProtocol {
    var urlScheme: String? { get }
    var applePayOptions: PrimerApplePayOptions? { get }
    var klarnaOptions: PrimerKlarnaOptions? { get }
    var cardPaymentOptions: PrimerCardPaymentOptions { get }
}

public class PrimerPaymentMethodOptions: PrimerPaymentMethodOptionsProtocol {
    let urlScheme: String?
    let applePayOptions: PrimerApplePayOptions?
    var klarnaOptions: PrimerKlarnaOptions?
    let cardPaymentOptions: PrimerCardPaymentOptions
    
    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        cardPaymentOptions: PrimerCardPaymentOptions? = nil
    ) {
        self.urlScheme = urlScheme
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
        self.cardPaymentOptions = cardPaymentOptions ?? PrimerCardPaymentOptions()
    }
}

// MARK: Apple Pay

internal protocol PrimerApplePayOptionsProtocol {
    var merchantIdentifier: String { get }
}

public class PrimerApplePayOptions: PrimerApplePayOptionsProtocol {
    
    let merchantIdentifier: String
    
    public init(merchantIdentifier: String) {
        self.merchantIdentifier = merchantIdentifier
    }
}

// MARK: Klarna

internal protocol PrimerKlarnaOptionsProtocol {
    var recurringPaymentDescription: String { get }
}

public class PrimerKlarnaOptions: PrimerKlarnaOptionsProtocol {
    
    let recurringPaymentDescription: String
    
    public init(recurringPaymentDescription: String) {
        self.recurringPaymentDescription = recurringPaymentDescription
    }
}

// MARK: Card Payment

internal protocol PrimerCardPaymentOptionsProtocol {
    var is3DSOnVaultingEnabled: Bool { get }
}

public class PrimerCardPaymentOptions: PrimerCardPaymentOptionsProtocol {
    
    let is3DSOnVaultingEnabled: Bool
    
    public init(is3DSOnVaultingEnabled: Bool? = nil) {
        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled != nil ? is3DSOnVaultingEnabled! : true
    }
}

// MARK: - UI OPTIONS

internal protocol PrimerUIOptionsProtocol {
    var isInitScreenEnabled: Bool { get } // Default: true
    var isSuccessScreenEnabled: Bool { get } // Default: true
    var isErrorScreenEnabled: Bool { get } // Default: true
    var theme: PrimerTheme { get }
}

public class PrimerUIOptions: PrimerUIOptionsProtocol {
    
    public internal(set) var isInitScreenEnabled: Bool
    public internal(set) var isSuccessScreenEnabled: Bool
    public internal(set) var isErrorScreenEnabled: Bool
    public let theme: PrimerTheme
    
    public init(
        isInitScreenEnabled: Bool? = nil,
        isSuccessScreenEnabled: Bool? = nil,
        isErrorScreenEnabled: Bool? = nil,
        theme: PrimerTheme? = nil
    ) {
        self.isInitScreenEnabled = isInitScreenEnabled != nil ? isInitScreenEnabled! : true
        self.isSuccessScreenEnabled = isSuccessScreenEnabled != nil ? isSuccessScreenEnabled! : true
        self.isErrorScreenEnabled = isErrorScreenEnabled != nil ? isErrorScreenEnabled! : true
        self.theme = theme ?? PrimerTheme()
    }
}

// MARK: - DEBUG OPTIONS

internal protocol PrimerDebugOptionsProtocol {
    var is3DSSanityCheckEnabled: Bool { get }
}

public class PrimerDebugOptions: PrimerDebugOptionsProtocol {
    
    let is3DSSanityCheckEnabled: Bool
    
    public init(is3DSSanityCheckEnabled: Bool? = nil) {
        self.is3DSSanityCheckEnabled = is3DSSanityCheckEnabled != nil ? is3DSSanityCheckEnabled! : true
    }
}
//
//internal protocol PrimerSettingsProtocol {
//    @available(*, deprecated, message: "Set the amount in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var amount: Int? { get }
//    @available(*, deprecated, message: "Set the currency in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var currency: Currency? { get }
//    var merchantIdentifier: String? { get }
//    @available(*, deprecated, message: "Set the countryCode in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var countryCode: CountryCode? { get }
//    var klarnaSessionType: KlarnaSessionType? { get }
//    var klarnaPaymentDescription: String? { get }
//    @available(*, deprecated, message: "Set the customerId in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var customerId: String? { get }
//    var urlScheme: String? { get }
//    var urlSchemeIdentifier: String? { get }
//    var isFullScreenOnly: Bool { get }
//    var hasDisabledSuccessScreen: Bool { get set }
//    var paymentHandling: PrimerPaymentHandling { get set }
//    var isManualPaymentHandlingEnabled: Bool { get }
//    var directDebitHasNoAmount: Bool { get }
//    @available(*, deprecated, message: "Set the orderItems in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var orderItems: [OrderItem]? { get }
//    var isInitialLoadingHidden: Bool { get set }
//    var localeData: LocaleData { get }
//    var is3DSOnVaultingEnabled: Bool { get }
//    @available(*, deprecated, message: "Set the billingAddress in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var billingAddress: Address? { get }
//    var orderId: String? { get }
//    var debugOptions: PrimerDebugOptions { get }
//    @available(*, deprecated, message: "Set the customer in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    var customer: Customer? { get set }
//
//    func modify(withClientSession clientSession: ClientSessionAPIResponse)
//}

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
    - paymentHandling: Defines the payment integration. If manual (not suggested), the entire payment logic needs to be implemented by the merchant.
    - businessDetails: **BusinessDetails** object containing the details of payer's business.
 
 - Author: Primer
 
 - Version: 1.2.2
 */
//
//public class PrimerSettings: PrimerSettingsProtocol {
//            
//    static var current: PrimerSettingsProtocol {
//        let primerSettings: PrimerSettingsProtocol = DependencyContainer.resolve()
//        return primerSettings
//    }
//        
//    internal(set) public var amount: Int?
//    internal(set) public var currency: Currency?
//    internal(set) public var merchantIdentifier: String?
//    internal(set) public var countryCode: CountryCode?
//    internal(set) public var klarnaSessionType: KlarnaSessionType?
//    internal(set) public var klarnaPaymentDescription: String?
//    internal(set) public var customerId: String?
//    private var _urlScheme: String?
//    internal(set) public var urlScheme: String? {
//        get {
//            if _urlScheme == "://redirect.primer.io" {
//                return nil
//            }
//            return _urlScheme
//        }
//        set {
//            guard newValue != nil else {
//                _urlScheme = nil
//                return
//            }
//            
//            var urlStr: String = newValue!
//            if newValue!.suffix(3) != "://" {
//                urlStr += "://"
//            }
//            
//            urlStr += "redirect.primer.io"
//            self._urlScheme = urlStr
//        }
//    }
//    internal(set) public var urlSchemeIdentifier: String?
//    internal(set) public var isFullScreenOnly: Bool
//    internal(set) public var hasDisabledSuccessScreen: Bool
//    internal(set) public var paymentHandling: PrimerPaymentHandling {
//        didSet {
//            
//        }
//    }
//    internal(set) public var directDebitHasNoAmount: Bool
//    internal(set) public var orderItems: [OrderItem]?
//    internal(set) public var isInitialLoadingHidden: Bool
//    internal(set) public var localeData: LocaleData
//    internal(set) public var is3DSOnVaultingEnabled: Bool
//    internal(set) public var billingAddress: Address?
//    internal(set) public var orderId: String?
//    internal(set) public var debugOptions: PrimerDebugOptions = PrimerDebugOptions()
//    internal(set) public var customer: Customer?
//    
//    private var isModifiedByClientSession: Bool = false
//    
//    var isManualPaymentHandlingEnabled: Bool {
//        paymentHandling == .manual
//    }
//    
//    deinit {
//        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
//    }
//
//    @available(*, deprecated, message: "Set the amount, currency, countryCode, customerId, customer, billingAddress & orderItems in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
//    public init(
//        merchantIdentifier: String? = nil,
//        customerId: String? = nil,
//        amount: Int? = nil,
//        currency: Currency? = nil,
//        countryCode: CountryCode? = nil,
//        klarnaSessionType: KlarnaSessionType? = nil,
//        klarnaPaymentDescription: String? = nil,
//        urlScheme: String? = nil,
//        urlSchemeIdentifier: String? = nil,
//        isFullScreenOnly: Bool = false,
//        hasDisabledSuccessScreen: Bool = false,
//        paymentHandling: PrimerPaymentHandling = .auto,
//        directDebitHasNoAmount: Bool = false,
//        orderItems: [OrderItem] = [],
//        isInitialLoadingHidden: Bool = false,
//        localeData: LocaleData? = nil,
//        is3DSOnVaultingEnabled: Bool = true,
//        billingAddress: Address? = nil,
//        orderId: String? = nil,
//        debugOptions: PrimerDebugOptions? = nil,
//        customer: Customer? = nil
//    ) {
//        self.amount = amount
//        self.currency = currency
//        self.klarnaSessionType = klarnaSessionType
//        self.klarnaPaymentDescription = klarnaPaymentDescription
//        self.customerId = customerId
//        self.merchantIdentifier = merchantIdentifier
//        self.countryCode = countryCode
//        self.urlSchemeIdentifier = urlSchemeIdentifier
//        self.isFullScreenOnly = isFullScreenOnly
//        self.hasDisabledSuccessScreen = hasDisabledSuccessScreen
//        self.paymentHandling = paymentHandling
//        self.directDebitHasNoAmount = directDebitHasNoAmount
//        self.orderItems = orderItems
//        self.isInitialLoadingHidden = isInitialLoadingHidden
//        self.localeData = localeData ?? LocaleData(languageCode: nil, regionCode: nil)
//        self.customer = customer
//        
//        if amount == nil && !orderItems.filter({ $0.unitAmount != nil }).isEmpty {
//            // In case order items have been provided: Replace amount with the sum of the unit amounts
//            self.amount = orderItems.filter({ $0.unitAmount != nil }).compactMap({ $0.unitAmount! * $0.quantity }).reduce(0, +)
//        }
//        
//        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled
//        self.billingAddress = billingAddress
//        self.orderId = orderId
//        self.debugOptions = debugOptions ?? PrimerDebugOptions()
//        self.urlScheme = urlScheme
//    }
//    
//    public init(
//        merchantIdentifier: String? = nil,
//        klarnaSessionType: KlarnaSessionType? = nil,
//        klarnaPaymentDescription: String? = nil,
//        urlScheme: String? = nil,
//        urlSchemeIdentifier: String? = nil,
//        isFullScreenOnly: Bool = false,
//        hasDisabledSuccessScreen: Bool = false,
//        paymentHandling: PrimerPaymentHandling = .auto,
//        directDebitHasNoAmount: Bool = false,
//        isInitialLoadingHidden: Bool = false,
//        localeData: LocaleData? = nil,
//        is3DSOnVaultingEnabled: Bool = true,
//        debugOptions: PrimerDebugOptions? = nil
//    ) {
//        self.merchantIdentifier = merchantIdentifier
//        self.klarnaSessionType = klarnaSessionType
//        self.klarnaPaymentDescription = klarnaPaymentDescription
//        self.urlSchemeIdentifier = urlSchemeIdentifier
//        self.isFullScreenOnly = isFullScreenOnly
//        self.hasDisabledSuccessScreen = hasDisabledSuccessScreen
//        self.paymentHandling = paymentHandling
//        self.directDebitHasNoAmount = directDebitHasNoAmount
//        self.isInitialLoadingHidden = isInitialLoadingHidden
//        self.localeData = localeData ?? LocaleData(languageCode: nil, regionCode: nil)
//        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled
//        self.debugOptions = debugOptions ?? PrimerDebugOptions()
//        self.urlScheme = urlScheme
//    }
//    
//    static func modify(withClientSession clientSession: ClientSessionAPIResponse) {
//        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//        settings.modify(withClientSession: clientSession)
//    }
//    
//    func logClientSessionWarning(for val: String) {
//        if isModifiedByClientSession { return }
//        print("Information relating to the \(val) has been provided in both client-session creation and checkout initialization. Provided client-session information will be favored.")
//    }
//    
//    func modify(withClientSession clientSession: ClientSessionAPIResponse) {
//        if let order = clientSession.order {
//            if self.orderId != nil ||
//                self.amount != nil ||
//                self.currency != nil ||
//                !(self.orderItems ?? []).isEmpty
//            {
//                logClientSessionWarning(for: "order")
//            }
//            self.orderId = order.id
//            self.amount = order.merchantAmount ?? order.totalOrderAmount
//            self.currency = order.currencyCode
//            self.countryCode = order.countryCode
//            
//            var orderItems: [OrderItem] = []
//            order.lineItems?.forEach({ lineItem in
//                if let orderItem = try? lineItem.toOrderItem() {
//                    orderItems.append(orderItem)
//                }
//            })
//            self.orderItems = orderItems
//        }
//        
//        if let customer = clientSession.customer {
//            if self.customerId != nil ||
//                self.billingAddress != nil
//            {
//                logClientSessionWarning(for: "customer")
//            }
//            
//            self.customerId = customer.id
//            
//            self.customer = Customer(
//                firstName: customer.firstName,
//                lastName: customer.lastName,
//                emailAddress: customer.emailAddress,
//                homePhoneNumber: nil,
//                mobilePhoneNumber: customer.mobileNumber,
//                workPhoneNumber: nil,
//                billingAddress: nil)
//            
//            if let billingAddress = customer.billingAddress {
//                let address = Address(
//                    addressLine1: billingAddress.addressLine1,
//                    addressLine2: billingAddress.addressLine2,
//                    city: billingAddress.city,
//                    state: billingAddress.state,
//                    countryCode: billingAddress.countryCode?.rawValue,
//                    postalCode: billingAddress.postalCode)
//                
//                self.billingAddress = address
//                self.customer?.billingAddress = address
//            }
//        }
//        
//        isModifiedByClientSession = true
//    }
//}

#endif
