//
//  SecretsManager.swift
//  Primer.io Debug App
//
//  Created by Jack Newcombe on 16/10/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

class SecretsManager {

    enum Keys: String {
        case stripePublishableKey = "STRIPE_PUBLISHABLE_KEY"
    }

    private let logger = PrimerLogging.shared.logger

    static let shared = SecretsManager()

    private init() {}

    lazy private var properties: [String: String] = {
        guard let fileUrl = Bundle.main.url(forResource: "secrets.defaults", withExtension: "properties") else {
            logger.warn(message: "Secrets file was not found in bundle. Check that `secrets.defaults.properties` is present in the root folder of the app.")
            return [:]
        }
        guard let fileContents = FileManager.default.contents(atPath: fileUrl.path) else {
            logger.warn(message: "Failed to load secrets file at path: \(fileUrl.path). Check that it is present and well formed.")
            return [:]
        }
        guard let fileAsString = String(data: fileContents, encoding: .utf8) else {
            logger.warn(message: "Failed to load secrets file as string. Check the file is a well formed and valid text file")
            return [:]
        }
        var mapping: [String: String] = [:]
        fileAsString.split(separator: "\n").forEach { item in
            // Allow skipping of comments lines
            guard !item.hasPrefix("#") else{
                return
            }
            let components = item.split(separator: "=")
            if components.count == 2 {
                mapping[String(components[0])] = String(components[1])
            } else {
                logger.warn(message: "Tried to load poorly formed secret: \(item)")
            }
        }
        return mapping
    }()

    func value(forKey key: Keys) -> String? {
        guard properties.keys.contains(key.rawValue) else {
            logger.warn(message: "Tried to get secret `(key.rawValue)` but it wasn't present in the secrets file.")
            return nil
        }
        return properties[key.rawValue]
    }

}
