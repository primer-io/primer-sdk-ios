import Foundation
import PassKit

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
        guard let primerSettings = settings as? PrimerSettings else { fatalError() }
        return primerSettings
    }
    public let paymentHandling: PrimerPaymentHandling
    let localeData: PrimerLocaleData
    let paymentMethodOptions: PrimerPaymentMethodOptions
    let uiOptions: PrimerUIOptions
    let debugOptions: PrimerDebugOptions
    let clientSessionCachingEnabled: Bool

    public init(
        paymentHandling: PrimerPaymentHandling = .auto,
        localeData: PrimerLocaleData? = nil,
        paymentMethodOptions: PrimerPaymentMethodOptions? = nil,
        uiOptions: PrimerUIOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil,
        debugOptions: PrimerDebugOptions? = nil,
        clientSessionCachingEnabled: Bool = false
    ) {
        self.paymentHandling = paymentHandling
        self.localeData = localeData ?? PrimerLocaleData()
        self.paymentMethodOptions = paymentMethodOptions ?? PrimerPaymentMethodOptions()
        self.uiOptions = uiOptions ?? PrimerUIOptions()
        self.debugOptions = debugOptions ?? PrimerDebugOptions()
        self.clientSessionCachingEnabled = clientSessionCachingEnabled
    }
}

// MARK: - PAYMENT HANDLING

public enum PrimerPaymentHandling: String, Codable {
    case auto   = "AUTO"
    case manual = "MANUAL"
}

// MARK: - PAYMENT METHOD OPTIONS

internal protocol PrimerPaymentMethodOptionsProtocol {
    var applePayOptions: PrimerApplePayOptions? { get }
    var klarnaOptions: PrimerKlarnaOptions? { get }
    var threeDsOptions: PrimerThreeDsOptions? { get }
    var stripeOptions: PrimerStripeOptions? { get }

    func validUrlForUrlScheme() throws -> URL
    func validSchemeForUrlScheme() throws -> String
}

public class PrimerPaymentMethodOptions: PrimerPaymentMethodOptionsProtocol, Codable {

    private let urlScheme: String?
    let applePayOptions: PrimerApplePayOptions?
    var klarnaOptions: PrimerKlarnaOptions?

    // Was producing warning: Immutable property will not be decoded because it is declared with an initial value which cannot be overwritten
    // Was it intentional?
    var cardPaymentOptions: PrimerCardPaymentOptions = PrimerCardPaymentOptions()
    var threeDsOptions: PrimerThreeDsOptions?
    var stripeOptions: PrimerStripeOptions?

    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil,
        stripeOptions: PrimerStripeOptions? = nil
    ) {
        self.urlScheme = urlScheme
        if let urlScheme = urlScheme, URL(string: urlScheme) == nil {
            PrimerLogging.shared.logger.warn(message: """
The provided url scheme '\(urlScheme)' is not a valid URL. Please ensure that a valid url scheme is provided of the form 'myurlscheme://myapp'
""")
        }
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
        self.threeDsOptions = threeDsOptions
        self.stripeOptions = stripeOptions
    }

    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    public init(
        urlScheme: String? = nil,
        applePayOptions: PrimerApplePayOptions? = nil,
        klarnaOptions: PrimerKlarnaOptions? = nil,
        cardPaymentOptions: PrimerCardPaymentOptions? = nil,
        stripeOptions: PrimerStripeOptions? = nil
    ) {
        self.urlScheme = urlScheme
        self.applePayOptions = applePayOptions
        self.klarnaOptions = klarnaOptions
        self.stripeOptions = stripeOptions
    }

    func validUrlForUrlScheme() throws -> URL {
        guard let urlScheme = urlScheme, let url = URL(string: urlScheme), url.scheme != nil else {
            let err = PrimerError.invalidValue(
                key: "urlScheme",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        return url
    }

    func validSchemeForUrlScheme() throws -> String {
        let url = try validUrlForUrlScheme()
        guard let scheme = url.scheme else {
            let err = PrimerError.invalidValue(
                key: "urlScheme",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        return scheme
    }
}

// MARK: Apple Pay

public class PrimerApplePayOptions: Codable {

    let merchantIdentifier: String
    @available(*, deprecated, message: "Use Client Session API to provide merchant name value: https://primer.io/docs/payment-methods/apple-pay/direct-integration#prepare-the-client-session")
    let merchantName: String?
    @available(*, deprecated, message: "Use BillingOptions to configure required billing fields.")
    let isCaptureBillingAddressEnabled: Bool
    /// If in some cases you dont want to present ApplePay option if the device is not supporting it set this to `false`.
    /// Default value is `true`.
    let showApplePayForUnsupportedDevice: Bool
    /// Due to merchant report about ApplePay flow which was not presenting because
    /// canMakePayments(usingNetworks:) was returning false if there were no cards in the Wallet,
    /// we introduced this flag to continue supporting the old behaviour. Default value is `true`.
    let checkProvidedNetworks: Bool
    let shippingOptions: ShippingOptions?
    let billingOptions: BillingOptions?

    public init(merchantIdentifier: String,
                merchantName: String?,
                isCaptureBillingAddressEnabled: Bool = false,
                showApplePayForUnsupportedDevice: Bool = true,
                checkProvidedNetworks: Bool = true) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.isCaptureBillingAddressEnabled = isCaptureBillingAddressEnabled
        self.showApplePayForUnsupportedDevice = showApplePayForUnsupportedDevice
        self.checkProvidedNetworks = checkProvidedNetworks
        self.shippingOptions = nil
        self.billingOptions = nil
    }

    public init(merchantIdentifier: String,
                merchantName: String?,
                isCaptureBillingAddressEnabled: Bool = false,
                showApplePayForUnsupportedDevice: Bool = true,
                checkProvidedNetworks: Bool = true,
                shippingOptions: ShippingOptions? = nil,
                billingOptions: BillingOptions? = nil) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.isCaptureBillingAddressEnabled = isCaptureBillingAddressEnabled
        self.showApplePayForUnsupportedDevice = showApplePayForUnsupportedDevice
        self.checkProvidedNetworks = checkProvidedNetworks
        self.shippingOptions = shippingOptions
        self.billingOptions = billingOptions
    }

    public struct ShippingOptions: Codable {
        public let shippingContactFields: [RequiredContactField]?
        public let requireShippingMethod: Bool

        public init(shippingContactFields: [RequiredContactField]? = nil,
                    requireShippingMethod: Bool) {
            self.shippingContactFields = shippingContactFields
            self.requireShippingMethod = requireShippingMethod
        }
    }

    public struct BillingOptions: Codable {
        public let requiredBillingContactFields: [RequiredContactField]?

        public init(requiredBillingContactFields: [RequiredContactField]? = nil) {
            self.requiredBillingContactFields = requiredBillingContactFields
        }
    }

    public enum RequiredContactField: Codable {
        case name, emailAddress, phoneNumber, postalAddress
    }
}

// MARK: Klarna

public class PrimerKlarnaOptions: Codable {

    let recurringPaymentDescription: String

    public init(recurringPaymentDescription: String) {
        self.recurringPaymentDescription = recurringPaymentDescription
    }
}

// MARK: Stripe ACH
public class PrimerStripeOptions: Codable {

    public enum MandateData: Codable {
        case fullMandate(text: String)
        case templateMandate(merchantName: String)
    }

    var publishableKey: String
    var mandateData: MandateData?

    public init(publishableKey: String, mandateData: MandateData? = nil) {
        self.publishableKey = publishableKey
        self.mandateData = mandateData
    }
}

// MARK: Card Payment

public class PrimerCardPaymentOptions: Codable {

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

public enum DismissalMechanism: Codable {
    case gestures, closeButton
}

internal protocol PrimerUIOptionsProtocol {
    var isInitScreenEnabled: Bool { get } // Default: true
    var isSuccessScreenEnabled: Bool { get } // Default: true
    var isErrorScreenEnabled: Bool { get } // Default: true
    var dismissalMechanism: [DismissalMechanism] { get } // Default: .gestures
    var theme: PrimerTheme { get }
}

public class PrimerUIOptions: PrimerUIOptionsProtocol, Codable {

    public internal(set) var isInitScreenEnabled: Bool
    public internal(set) var isSuccessScreenEnabled: Bool
    public internal(set) var isErrorScreenEnabled: Bool
    public internal(set) var dismissalMechanism: [DismissalMechanism]
    public let theme: PrimerTheme

    private enum CodingKeys: String, CodingKey {
        case isInitScreenEnabled, isSuccessScreenEnabled, isErrorScreenEnabled, dismissalMechanism, theme
    }

    public init(
        isInitScreenEnabled: Bool? = nil,
        isSuccessScreenEnabled: Bool? = nil,
        isErrorScreenEnabled: Bool? = nil,
        dismissalMechanism: [DismissalMechanism]? = [.gestures],
        theme: PrimerTheme? = nil
    ) {
        self.isInitScreenEnabled = isInitScreenEnabled != nil ? isInitScreenEnabled! : true
        self.isSuccessScreenEnabled = isSuccessScreenEnabled != nil ? isSuccessScreenEnabled! : true
        self.isErrorScreenEnabled = isErrorScreenEnabled != nil ? isErrorScreenEnabled! : true
        self.dismissalMechanism = dismissalMechanism ?? [.gestures]
        self.theme = theme ?? PrimerTheme()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isInitScreenEnabled = try container.decode(Bool.self, forKey: .isInitScreenEnabled)
        self.isSuccessScreenEnabled = try container.decode(Bool.self, forKey: .isSuccessScreenEnabled)
        self.isErrorScreenEnabled = try container.decode(Bool.self, forKey: .isErrorScreenEnabled)
        self.dismissalMechanism = try container.decode([DismissalMechanism].self, forKey: .dismissalMechanism)
        self.theme = PrimerTheme()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isInitScreenEnabled, forKey: .isInitScreenEnabled)
        try container.encode(isSuccessScreenEnabled, forKey: .isSuccessScreenEnabled)
        try container.encode(isErrorScreenEnabled, forKey: .isErrorScreenEnabled)
        try container.encode(dismissalMechanism, forKey: .dismissalMechanism)
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
