// MARK: - PRIMER SETTINGS

internal protocol PrimerSettingsProtocol {
    var paymentHandling: PrimerPaymentHandling { get }
    var localeData: PrimerLocaleData { get }
    var paymentMethodOptions: PrimerPaymentMethodOptions { get }
    var uiOptions: PrimerUIOptions { get }
    var debugOptions: PrimerDebugOptions { get }
}

public class PrimerSettings: PrimerSettingsProtocol, Codable {

    static var current: PrimerSettings {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings as! PrimerSettings
    }
    public let paymentHandling: PrimerPaymentHandling
    let localeData: PrimerLocaleData
    let paymentMethodOptions: PrimerPaymentMethodOptions
    let uiOptions: PrimerUIOptions
    let debugOptions: PrimerDebugOptions

    public init(
        paymentHandling: PrimerPaymentHandling = .auto,
        localeData: PrimerLocaleData? = nil,
        paymentMethodOptions: PrimerPaymentMethodOptions? = nil,
        uiOptions: PrimerUIOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil,
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

public enum PrimerPaymentHandling: String, Codable {
    case auto   = "AUTO"
    case manual = "MANUAL"
}

// MARK: - PAYMENT METHOD OPTIONS

internal protocol PrimerPaymentMethodOptionsProtocol {
    var urlScheme: String? { get }
    var applePayOptions: PrimerApplePayOptions? { get }
    var klarnaOptions: PrimerKlarnaOptions? { get }
    var threeDsOptions: PrimerThreeDsOptions? { get }
}

public class PrimerPaymentMethodOptions: PrimerPaymentMethodOptionsProtocol, Codable {

    let urlScheme: String?
    let applePayOptions: PrimerApplePayOptions?
    var klarnaOptions: PrimerKlarnaOptions?

    // Was producing warning: Immutable property will not be decoded because it is declared with an initial value which cannot be overwritten
    // Was it intentional?
    var cardPaymentOptions: PrimerCardPaymentOptions = PrimerCardPaymentOptions()
    var threeDsOptions: PrimerThreeDsOptions?

    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil
    ) {
        self.urlScheme = urlScheme
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
        self.threeDsOptions = threeDsOptions
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

public class PrimerApplePayOptions: Codable {

    let merchantIdentifier: String
    let merchantName: String
    let isCaptureBillingAddressEnabled: Bool
    /// If in some cases you dont want to present ApplePay option if the device is not supporting it set this to `false`. Default value is `true`.
    let showApplePayForUnsupportedDevice: Bool
    /// Due to merchant report about ApplePay flow which was not presenting because canMakePayments(usingNetworks:) was returning false if there were no cards in the Wallet, we introduced this flag to continue supporting the old behaviour. Default value is `true`.
    let checkProvidedNetworks: Bool

    public init(merchantIdentifier: String,
                merchantName: String,
                isCaptureBillingAddressEnabled: Bool = false,
                showApplePayForUnsupportedDevice: Bool = true,
                checkProvidedNetworks: Bool = true) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.isCaptureBillingAddressEnabled = isCaptureBillingAddressEnabled
        self.showApplePayForUnsupportedDevice = showApplePayForUnsupportedDevice
        self.checkProvidedNetworks = checkProvidedNetworks
    }
}

// MARK: Klarna

public class PrimerKlarnaOptions: Codable {

    let recurringPaymentDescription: String

    public init(recurringPaymentDescription: String) {
        self.recurringPaymentDescription = recurringPaymentDescription
    }
}

// MARK: Card Payment

@available(*, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
public class PrimerCardPaymentOptions: Codable {

    @available(*, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    let is3DSOnVaultingEnabled: Bool

    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    public init(is3DSOnVaultingEnabled: Bool?) {
        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled != nil ? is3DSOnVaultingEnabled! : true
    }

    public init() {
        self.is3DSOnVaultingEnabled = true
    }
}

// MARK: - UI OPTIONS

internal protocol PrimerUIOptionsProtocol {
    var isInitScreenEnabled: Bool { get } // Default: true
    var isSuccessScreenEnabled: Bool { get } // Default: true
    var isErrorScreenEnabled: Bool { get } // Default: true
    var theme: PrimerTheme { get }
}

public class PrimerUIOptions: PrimerUIOptionsProtocol, Codable {

    public internal(set) var isInitScreenEnabled: Bool
    public internal(set) var isSuccessScreenEnabled: Bool
    public internal(set) var isErrorScreenEnabled: Bool
    public let theme: PrimerTheme

    private enum CodingKeys: String, CodingKey {
        case isInitScreenEnabled, isSuccessScreenEnabled, isErrorScreenEnabled, theme
    }

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

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isInitScreenEnabled = try container.decode(Bool.self, forKey: .isInitScreenEnabled)
        self.isSuccessScreenEnabled = try container.decode(Bool.self, forKey: .isSuccessScreenEnabled)
        self.isErrorScreenEnabled = try container.decode(Bool.self, forKey: .isErrorScreenEnabled)
        self.theme = PrimerTheme()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isInitScreenEnabled, forKey: .isInitScreenEnabled)
        try container.encode(isSuccessScreenEnabled, forKey: .isSuccessScreenEnabled)
        try container.encode(isErrorScreenEnabled, forKey: .isErrorScreenEnabled)
    }
}

// MARK: - DEBUG OPTIONS

internal protocol PrimerDebugOptionsProtocol {
    var is3DSSanityCheckEnabled: Bool { get }
}

public class PrimerDebugOptions: PrimerDebugOptionsProtocol, Codable {

    let is3DSSanityCheckEnabled: Bool

    public init(is3DSSanityCheckEnabled: Bool? = nil) {
        self.is3DSSanityCheckEnabled = is3DSSanityCheckEnabled != nil ? is3DSSanityCheckEnabled! : true
    }
}

// MARK: - 3DS OPTIONS

internal protocol PrimerThreeDsOptionsProtocol {
    var threeDsAppRequestorUrl: String? { get }
}

public class PrimerThreeDsOptions: PrimerThreeDsOptionsProtocol, Codable {

    let threeDsAppRequestorUrl: String?

    public init(threeDsAppRequestorUrl: String? = nil) {
        self.threeDsAppRequestorUrl = threeDsAppRequestorUrl
    }
}
