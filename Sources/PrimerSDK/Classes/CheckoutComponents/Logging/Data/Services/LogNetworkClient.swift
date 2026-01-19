//
//  LogNetworkClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

actor LogNetworkClient {
    // MARK: - JSON Encoder

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        // Use custom key encoding to handle specific snake_case fields
        encoder.keyEncodingStrategy = .custom { keys in
            let key = keys.last!.stringValue

            switch key {
            case "primer_account_id", "useragent_details", "patch_minor":
                return CustomCodingKey(stringValue: key)
            default:
                return CustomCodingKey(stringValue: key.convertToSnakeCase())
            }
        }

        // Disable forward slash escaping for iOS 13.0+ (always available for iOS 15.0+)
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]

        return encoder
    }()

    // MARK: - Custom Coding Key

    private struct CustomCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    // MARK: - Public Methods

    func send(payload: LogPayload, to endpoint: URL, token: String?) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let jsonData = try encoder.encode(payload)
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LoggingError.networkError
        }
    }
}

// MARK: - Errors

extension LoggingError {
    static let networkError = LoggingError.encodingFailed // Reuse existing error for now
}

// MARK: - String Extension

private extension String {
    func convertToSnakeCase() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, range: range, withTemplate: "$1_$2").lowercased() ?? lowercased()
    }
}
