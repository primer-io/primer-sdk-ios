//
//  PrimerSettings.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

// MARK: - PRIMER SETTINGS

protocol PrimerSettingsProtocol {
    var paymentHandling: PrimerPaymentHandling { get }
    var localeData: PrimerLocaleData { get }
    var paymentMethodOptions: PrimerPaymentMethodOptions { get }
    var uiOptions: PrimerUIOptions { get }
    var debugOptions: PrimerDebugOptions { get }
    var apiVersion: PrimerApiVersion { get }
}

/// Configuration object for customizing the Primer SDK behavior.
///
/// `PrimerSettings` allows you to configure various aspects of the checkout experience,
/// including payment handling mode, localization, payment method options, and UI customization.
///
/// Example usage:
/// ```swift
/// let settings = PrimerSettings(
///     paymentHandling: .auto,
///     localeData: PrimerLocaleData(languageCode: "en"),
///     uiOptions: PrimerUIOptions(isSuccessScreenEnabled: true)
/// )
/// Primer.shared.configure(settings: settings)
/// ```
public final class PrimerSettings: PrimerSettingsProtocol, Codable {

    static var current: PrimerSettings {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let primerSettings = settings as? PrimerSettings else { fatalError() }
        return primerSettings
    }

    /// Determines how payments are processed after tokenization.
    /// Use `.auto` for automatic processing or `.manual` for server-side control.
    public let paymentHandling: PrimerPaymentHandling

    /// Localization settings including language and region codes.
    public let localeData: PrimerLocaleData

    /// Configuration options specific to individual payment methods (e.g., Apple Pay, Klarna).
    public let paymentMethodOptions: PrimerPaymentMethodOptions

    /// UI customization options for the checkout screens.
    public let uiOptions: PrimerUIOptions

    /// Debug and development options for testing.
    public let debugOptions: PrimerDebugOptions

    /// Enables caching of client session data for improved performance.
    public let clientSessionCachingEnabled: Bool

    /// The Primer API version to use for requests.
    public let apiVersion: PrimerApiVersion

    public init(
        paymentHandling: PrimerPaymentHandling = .auto,
        localeData: PrimerLocaleData? = nil,
        paymentMethodOptions: PrimerPaymentMethodOptions? = nil,
        uiOptions: PrimerUIOptions? = nil,
        threeDsOptions: PrimerThreeDsOptions? = nil,
        debugOptions: PrimerDebugOptions? = nil,
        clientSessionCachingEnabled: Bool = false,
        apiVersion: PrimerApiVersion = .V2_4
    ) {
        self.paymentHandling = paymentHandling
        self.localeData = localeData ?? PrimerLocaleData()
        self.paymentMethodOptions = paymentMethodOptions ?? PrimerPaymentMethodOptions()
        self.uiOptions = uiOptions ?? PrimerUIOptions()
        self.debugOptions = debugOptions ?? PrimerDebugOptions()
        self.clientSessionCachingEnabled = clientSessionCachingEnabled
        self.apiVersion = apiVersion
    }
}

// MARK: - PAYMENT METHOD OPTIONS

protocol PrimerPaymentMethodOptionsProtocol {
    var applePayOptions: PrimerApplePayOptions? { get }
    var klarnaOptions: PrimerKlarnaOptions? { get }
    var threeDsOptions: PrimerThreeDsOptions? { get }
    var stripeOptions: PrimerStripeOptions? { get }

    func validUrlForUrlScheme() throws -> URL
    func validSchemeForUrlScheme() throws -> String
}

extension PrimerPaymentMethodOptions: PrimerPaymentMethodOptionsProtocol {
    func validUrlForUrlScheme() throws -> URL {
        guard let urlScheme, let url = URL(string: urlScheme), url.scheme != nil else {
            throw handled(primerError: .invalidValue(key: "urlScheme"))
        }
        return url
    }
    
    func validSchemeForUrlScheme() throws -> String {
        let url = try validUrlForUrlScheme()
        guard let scheme = url.scheme else { throw handled(primerError: .invalidValue(key: "urlScheme")) }
        return scheme
    }
}

// MARK: - UI OPTIONS

public final class PrimerUIOptions: Codable {

    /// Whether to show the initialization/loading screen when the SDK starts.
    /// Default is `true`.
    public internal(set) var isInitScreenEnabled: Bool

    /// Whether to show a success screen after payment completion.
    /// Default is `true`.
    public internal(set) var isSuccessScreenEnabled: Bool

    /// Whether to show an error screen when payment fails.
    /// Default is `true`.
    public internal(set) var isErrorScreenEnabled: Bool

    /// The mechanisms users can use to dismiss the checkout modal.
    /// Default is `[.gestures]`.
    public internal(set) var dismissalMechanism: [DismissalMechanism]

    /// Additional options specific to the card form UI.
    public internal(set) var cardFormUIOptions: PrimerCardFormUIOptions?

    /// The appearance mode for the UI (system, light, or dark).
    /// Default is `.system`, which follows the device setting.
    public internal(set) var appearanceMode: PrimerAppearanceMode

    /// The visual theme configuration for the checkout UI.
    public var theme: PrimerTheme

    private enum CodingKeys: String, CodingKey {
        case isInitScreenEnabled,
             isSuccessScreenEnabled,
             isErrorScreenEnabled,
             dismissalMechanism,
             cardFormUIOptions,
             appearanceMode,
             theme
    }

    public init(
        isInitScreenEnabled: Bool? = nil,
        isSuccessScreenEnabled: Bool? = nil,
        isErrorScreenEnabled: Bool? = nil,
        dismissalMechanism: [DismissalMechanism]? = [.gestures],
        cardFormUIOptions: PrimerCardFormUIOptions? = nil,
        appearanceMode: PrimerAppearanceMode? = nil,
        theme: PrimerTheme? = nil
    ) {
        self.isInitScreenEnabled = isInitScreenEnabled ?? true
        self.isSuccessScreenEnabled = isSuccessScreenEnabled ?? true
        self.isErrorScreenEnabled = isErrorScreenEnabled ?? true
        self.dismissalMechanism = dismissalMechanism ?? [.gestures]
        self.cardFormUIOptions = cardFormUIOptions
        self.appearanceMode = appearanceMode ?? .system
        self.theme = theme ?? PrimerTheme()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isInitScreenEnabled = try container.decode(Bool.self, forKey: .isInitScreenEnabled)
        isSuccessScreenEnabled = try container.decode(Bool.self, forKey: .isSuccessScreenEnabled)
        isErrorScreenEnabled = try container.decode(Bool.self, forKey: .isErrorScreenEnabled)
        dismissalMechanism = try container.decodeIfPresent([DismissalMechanism].self, forKey: .dismissalMechanism) ?? [.gestures]
        cardFormUIOptions = try container.decodeIfPresent(PrimerCardFormUIOptions.self, forKey: .cardFormUIOptions)
        appearanceMode = try container.decodeIfPresent(PrimerAppearanceMode.self, forKey: .appearanceMode) ?? .system
        theme = PrimerTheme()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isInitScreenEnabled, forKey: .isInitScreenEnabled)
        try container.encode(isSuccessScreenEnabled, forKey: .isSuccessScreenEnabled)
        try container.encode(isErrorScreenEnabled, forKey: .isErrorScreenEnabled)
        try container.encode(dismissalMechanism, forKey: .dismissalMechanism)
        try container.encodeIfPresent(cardFormUIOptions, forKey: .cardFormUIOptions)
        try container.encode(appearanceMode, forKey: .appearanceMode)
    }
}
