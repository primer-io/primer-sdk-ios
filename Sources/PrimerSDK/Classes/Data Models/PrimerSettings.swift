#if canImport(UIKit)

public typealias ClientTokenCallBack = (_ completionHandler: @escaping (_ token: String?, _ error: Error?) -> Void) -> Void
public typealias PaymentMethodTokenCallBack = (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
public typealias TokenizationSuccessCallBack = (_ paymentMethodToken: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
public typealias CheckoutDismissalCallback = () -> Void

internal protocol PrimerSettingsProtocol {
    var amount: Int? { get }
    var currency: Currency? { get }
    var merchantIdentifier: String? { get }
    var countryCode: CountryCode? { get }
    var klarnaSessionType: KlarnaSessionType? { get }
    var klarnaPaymentDescription: String? { get }
    var customerId: String? { get }
    var authorizePayment: PaymentMethodTokenCallBack { get }
    var onTokenizeSuccess: TokenizationSuccessCallBack { get }
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
    var is3DSOnVaultingEnabled: Bool { get }
    var billingAddress: Address? { get }
    var orderId: String? { get }
    var debugOptions: PrimerDebugOptions { get }
    var customer: Customer? { get set }
    
    func modify(withClientSession clientSession: ClientSession)
}

public struct PrimerDebugOptions {
    public var is3DSSanityCheckEnabled: Bool = true
    
    public init(is3DSSanityCheckEnabled: Bool = true) {
        self.is3DSSanityCheckEnabled = is3DSSanityCheckEnabled
    }
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
    internal(set) public var is3DSOnVaultingEnabled: Bool
    internal(set) public var billingAddress: Address?
    internal(set) public var orderId: String?
    internal(set) public var debugOptions: PrimerDebugOptions = PrimerDebugOptions()
    internal(set) public var customer: Customer?

    public var clientTokenRequestCallback: ClientTokenCallBack {
        return Primer.shared.delegate?.clientTokenCallback ?? { _ in }
    }

    internal var authorizePayment: PaymentMethodTokenCallBack {
        return Primer.shared.delegate?.authorizePayment ?? { _, _ in }
    }
    
    internal var onTokenizeSuccess: TokenizationSuccessCallBack {
        return Primer.shared.delegate?.onTokenizeSuccess ?? { _, _ in }
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
        localeData: LocaleData? = nil,
        is3DSOnVaultingEnabled: Bool = true,
        billingAddress: Address? = nil,
        orderId: String? = nil,
        debugOptions: PrimerDebugOptions? = nil,
        customer: Customer? = nil
    ) {
        self.amount = amount
        self.currency = currency
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
        self.customer = customer
        
        if amount == nil && !orderItems.filter({ $0.unitAmount != nil }).isEmpty {
            // In case order items have been provided: Replace amount with the sum of the unit amounts
            self.amount = orderItems.filter({ $0.unitAmount != nil }).compactMap({ $0.unitAmount! * $0.quantity }).reduce(0, +)
        }
        
        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled
        self.billingAddress = billingAddress
        self.orderId = orderId
        self.debugOptions = debugOptions ?? PrimerDebugOptions()
    }
    
    static func modify(withClientSession clientSession: ClientSession) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        settings.modify(withClientSession: clientSession)
    }
    
    func modify(withClientSession clientSession: ClientSession) {
        if let order = clientSession.order {
            self.orderId = order.id
            self.amount = order.totalAmount
            self.currency = order.currencyCode
            self.countryCode = order.countryCode
            
            var orderItems: [OrderItem] = []
            order.items?.forEach({ item in
                if let orderItem = try? OrderItem(
                    name: item.name,
                    unitAmount: item.unitAmount,
                    quantity: item.quantity,
                    isPending: false) {
                    orderItems.append(orderItem)
                }
            })
            self.orderItems = orderItems
            
            self.amount = order.totalAmount
        }
        
        if let customer = clientSession.customer {
            self.customerId = customer.id
            
            self.customer = Customer(
                id: customer.id,
                firstName: customer.firstName,
                lastName: customer.lastName,
                email: customer.email,
                mobileNumber: customer.mobileNumber,
                billingAddress: nil,
                shippingAddress: nil,
                taxId:  nil)
            
            if let billingAddress = customer.billingAddress {
                let address = Address(
                    firstName: billingAddress.firstName,
                    lastName: billingAddress.lastName,
                    addressLine1: billingAddress.addressLine1,
                    addressLine2: billingAddress.addressLine2,
                    city: billingAddress.city,
                    postalCode: billingAddress.postalCode,
                    state: billingAddress.state,
                    countryCode: billingAddress.countryCode)
                
                self.billingAddress = address
                self.customer?.billingAddress = address
            }            
        }
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

internal class MockDelegate: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
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
