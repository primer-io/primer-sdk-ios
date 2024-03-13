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
