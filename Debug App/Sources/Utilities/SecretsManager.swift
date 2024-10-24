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

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    lazy var properties: [Keys: String] = {
        guard let fileUrl = bundle.url(forResource: "secrets.defaults", withExtension: "properties") else {
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
        var mapping: [Keys: String] = [:]
        fileAsString.components(separatedBy: "\n").forEach { item in
            // Allow skipping of comments lines
            guard !item.hasPrefix("#") else{
                return
            }
            let components = item.components(separatedBy: "=")
            if components.count == 2, let key = Keys(rawValue: components[0]) {
                mapping[key] = components[1]
            } else {
                logger.warn(message: "Tried to load poorly formed secret: \(item)")
            }
        }
        return mapping
    }()

    func value(forKey key: Keys) -> String? {
        properties.keys.contains(key) ? properties[key] : nil
    }

}
