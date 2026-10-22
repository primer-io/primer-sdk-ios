//
//  AppLinkConfigProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerSDK

protocol AppLinkPayloadProviding {
    var clientToken: String? { get }
    var settingsJwt: String? { get }
    var demo: String? { get }
}

extension AppLinkPayloadProviding {
    var demo: String? { nil }
}

class AppLinkConfigProvider {

    private let payloadProvider: AppLinkPayloadProviding

    /// Raw `demo` query value — resolved against `DemoKey` by the presenter so unknown keys can be reported.
    var demo: String? { payloadProvider.demo }

    /// Why `fetchConfig()` returns nil, worded for the settings screen's error label; nil when it decodes.
    var settingsFailure: String? {
        guard let settingsJwt = payloadProvider.settingsJwt else { return "settings missing" }
        return getSettings(from: settingsJwt) == nil ? "settings decode failed" : nil
    }

    init(payloadProvider: AppLinkPayloadProviding = UserDefaults.standard) {
        self.payloadProvider = payloadProvider
    }

    func fetchClientToken() -> String? {
        guard let clientToken = payloadProvider.clientToken else {
            return nil
        }
        return clientToken
    }

    func fetchConfig() -> PrimerSettings? {
        guard let settingsJwt = payloadProvider.settingsJwt,
              let settings = getSettings(from: settingsJwt) else {
            return nil
        }
        return settings
    }

    private func getSettings(from jwt: String) -> PrimerSettings? {
        guard let data = Data(base64Encoded: jwt, options: .ignoreUnknownCharacters),
              let rnSettings = try? JSONDecoder().decode(RNPrimerSettings.self, from: data)
        else { return nil }
        return RNPrimerSettingsMapper.map(from: rnSettings)
    }
}

extension UserDefaults: AppLinkPayloadProviding {
    private static let clientTokenKey = "clientToken"
    private static let settingsJwtKey = "settings"

    var clientToken: String? {
        string(forKey: Self.clientTokenKey)
    }

    var settingsJwt: String? {
        string(forKey: Self.settingsJwtKey)
    }
}

private extension [URLQueryItem] {
    func value(for name: String) -> String? {
        first { $0.name == name }?.value
    }
}

/// Parses `<scheme>://sdk-demo.primer.io/...?clientToken=&settings=&demo=` (custom scheme or universal link).
/// Any link on that host is forwarded, even with parameters missing, so the receiver can report what is wrong.
struct SDKDemoUrlHandler {
    static let host = "sdk-demo.primer.io"

    /// The last link, kept for the settings screen when the link launched the app: on a cold start the
    /// notification below fires before that screen observes it. Consumed once.
    static var pendingPayload: DeeplinkConfigProvider?

    @discardableResult
    static func handleUrl(_ url: URL) -> Bool {
        guard url.host == host else { return false }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        let payload = DeeplinkConfigProvider(
            clientToken: queryItems.value(for: "clientToken"),
            settingsJwt: queryItems.value(for: "settings"),
            demo: queryItems.value(for: "demo")
        )
        pendingPayload = payload
        NotificationCenter.default.post(name: .appetizeURLHandled, object: nil)
        return true
    }

    static func consumePendingPayload() -> DeeplinkConfigProvider? {
        defer { pendingPayload = nil }
        return pendingPayload
    }
}

extension NSNotification.Name {
    static let appetizeURLHandled = NSNotification.Name("appetizeURLHandled")
}

struct DeeplinkConfigProvider: AppLinkPayloadProviding {
    let clientToken: String?
    let settingsJwt: String?
    let demo: String?
}
