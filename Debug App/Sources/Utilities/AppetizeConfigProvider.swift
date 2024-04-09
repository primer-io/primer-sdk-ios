//
//  AppetizeConfigProvider.swift
//  Debug App
//
//  Created by Niall Quinn on 08/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation

protocol PaymentConfigProviding {}

protocol AppetizePayloadProviding {
    var isAppetize: Bool? { get }
    var configJwt: String? { get }
}

class AppetizeConfigProvider {

    private let payloadProvider: AppetizePayloadProviding

    init(payloadProvider: AppetizePayloadProviding = UserDefaults.standard) {
        self.payloadProvider = payloadProvider
    }

    func fetchConfig() -> SessionConfiguration? {
        guard payloadProvider.isAppetize == true,
              let jwt = payloadProvider.configJwt,
              let config = getConfig(from: jwt) else {
            return nil
        }
        return config
    }

    private func getConfig(from jwt: String) -> SessionConfiguration? {
        guard let data = Data(base64Encoded: jwt, options: .ignoreUnknownCharacters) else { return nil }
        return (try? JSONDecoder().decode(SessionConfiguration.self, from: data))
    }
}

extension UserDefaults: AppetizePayloadProviding {
    private static let isAppetizeKey = "isAppetize"
    private static let configJwtKey = "p"

    var isAppetize: Bool? {
        bool(forKey: Self.isAppetizeKey)
    }

    var configJwt: String? {
        string(forKey: Self.configJwtKey)
    }
}

struct AppetizeUrlHandler {
    // Handle incoming livedemostore url
    static func handleUrl(_ url: URL) -> Bool {
        if url.absoluteString.contains("livedemostore.common.primer.io"),
           let p = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "p"})
        {
            let DeeplinkConfigProvider = DeeplinkConfigProvider(isAppetize: true, configJwt: p.value)
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

struct DeeplinkConfigProvider: AppetizePayloadProviding {
    let isAppetize: Bool?
    let configJwt: String?
}
