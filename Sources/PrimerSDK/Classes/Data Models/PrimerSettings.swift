//
//  PrimerSettings.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit
import PrimerCore
import PrimerFoundation

// MARK: - PRIMER SETTINGS

protocol PrimerSettingsProtocol {
    var paymentHandling: PrimerPaymentHandling { get }
    var localeData: PrimerLocaleData { get }
    var paymentMethodOptions: PrimerPaymentMethodOptions { get }
    var uiOptions: PrimerUIOptions { get }
    var debugOptions: PrimerDebugOptions { get }
    var apiVersion: PrimerApiVersion { get }
}

public final class PrimerSettings: PrimerSettingsProtocol, Codable {

    static var current: PrimerSettings {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let primerSettings = settings as? PrimerSettings else { fatalError() }
        return primerSettings
    }
    public let paymentHandling: PrimerPaymentHandling
    public let localeData: PrimerLocaleData
    public let paymentMethodOptions: PrimerPaymentMethodOptions
    public let uiOptions: PrimerUIOptions
    public let debugOptions: PrimerDebugOptions
    public let clientSessionCachingEnabled: Bool
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
        guard let urlScheme = urlScheme, let url = URL(string: urlScheme), url.scheme != nil else {
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

    public internal(set) var isInitScreenEnabled: Bool
    public internal(set) var isSuccessScreenEnabled: Bool
    public internal(set) var isErrorScreenEnabled: Bool
    public internal(set) var dismissalMechanism: [DismissalMechanism]
    public internal(set) var cardFormUIOptions: PrimerCardFormUIOptions?
    public internal(set) var appearanceMode: PrimerAppearanceMode
    public let theme: PrimerTheme

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
        self.isInitScreenEnabled = isInitScreenEnabled != nil ? isInitScreenEnabled! : true
        self.isSuccessScreenEnabled = isSuccessScreenEnabled != nil ? isSuccessScreenEnabled! : true
        self.isErrorScreenEnabled = isErrorScreenEnabled != nil ? isErrorScreenEnabled! : true
        self.dismissalMechanism = dismissalMechanism ?? [.gestures]
        self.cardFormUIOptions = cardFormUIOptions
        self.appearanceMode = appearanceMode ?? .system
        self.theme = theme ?? PrimerTheme()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isInitScreenEnabled = try container.decode(Bool.self, forKey: .isInitScreenEnabled)
        self.isSuccessScreenEnabled = try container.decode(Bool.self, forKey: .isSuccessScreenEnabled)
        self.isErrorScreenEnabled = try container.decode(Bool.self, forKey: .isErrorScreenEnabled)
        self.dismissalMechanism = try container.decode([DismissalMechanism].self, forKey: .dismissalMechanism)
        self.cardFormUIOptions = try container.decodeIfPresent(PrimerCardFormUIOptions.self, forKey: .cardFormUIOptions)
        self.appearanceMode = try container.decodeIfPresent(PrimerAppearanceMode.self, forKey: .appearanceMode) ?? .system
        self.theme = PrimerTheme()
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
