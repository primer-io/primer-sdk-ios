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
    let isReactNativeIntegration: Bool
    
    public init(
        paymentHandling: PrimerPaymentHandling = .auto,
        localeData: PrimerLocaleData? = nil,
        paymentMethodOptions: PrimerPaymentMethodOptions? = nil,
        uiOptions: PrimerUIOptions? = nil,
        debugOptions: PrimerDebugOptions? = nil,
        isReactNativeIntegration: Bool = false
    ) {
        self.paymentHandling = paymentHandling
        self.localeData = localeData ?? PrimerLocaleData()
        self.paymentMethodOptions = paymentMethodOptions ?? PrimerPaymentMethodOptions()
        self.uiOptions = uiOptions ?? PrimerUIOptions()
        self.debugOptions = debugOptions ?? PrimerDebugOptions()
        self.isReactNativeIntegration = isReactNativeIntegration
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
}

public class PrimerPaymentMethodOptions: PrimerPaymentMethodOptionsProtocol {
    
    let urlScheme: String?
    let applePayOptions: PrimerApplePayOptions?
    var klarnaOptions: PrimerKlarnaOptions?
    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    let cardPaymentOptions: PrimerCardPaymentOptions = PrimerCardPaymentOptions(is3DSOnVaultingEnabled: false)
    
    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil
    ) {
        self.urlScheme = urlScheme
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
    }
    
    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        cardPaymentOptions: PrimerCardPaymentOptions? = nil
    ) {
        self.urlScheme = urlScheme
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
    }
}

// MARK: Apple Pay

internal protocol PrimerApplePayOptionsProtocol {
    var merchantIdentifier: String { get }
}

public class PrimerApplePayOptions: PrimerApplePayOptionsProtocol {
    
    let merchantIdentifier: String
    let merchantName: String
    let isCaptureBillingAddressEnabled: Bool
    
    public init(merchantIdentifier: String, merchantName: String, isCaptureBillingAddressEnabled: Bool = false) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.isCaptureBillingAddressEnabled = isCaptureBillingAddressEnabled
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

@available(*, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
public class PrimerCardPaymentOptions: PrimerCardPaymentOptionsProtocol {
    
    @available(*, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
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

#endif
