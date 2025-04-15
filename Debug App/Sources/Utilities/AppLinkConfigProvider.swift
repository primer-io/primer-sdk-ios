//
//  AppetizeConfigProvider.swift
//  Debug App
//
//  Created by Niall Quinn on 08/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

protocol PaymentConfigProviding {}

protocol AppLinkPayloadProviding {
    var clientToken: String? { get }
    var settingsJwt: String? { get }
}

class AppLinkConfigProvider {

    private let payloadProvider: AppLinkPayloadProviding

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

struct AppetizeUrlHandler {
    // Handle incoming livedemostore url
    static func handleUrl(_ url: URL) -> Bool {
        if url.absoluteString.contains("https://sdk-demo.primer.io"),
        let clientToken = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "clientToken"}),
        let settings = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "settings"}) {
            let DeeplinkConfigProvider = DeeplinkConfigProvider(clientToken: clientToken.value, settingsJwt: settings.value)
            NotificationCenter.default.post(name: .appetizeURLHandled, object: DeeplinkConfigProvider)
            return true
        } else {
            return false
        }
    }
}

extension NSNotification.Name {
    static let appetizeURLHandled = NSNotification.Name("appetizeURLHandled")
}

struct DeeplinkConfigProvider: AppLinkPayloadProviding {
    let clientToken: String?
    let settingsJwt: String?
}
