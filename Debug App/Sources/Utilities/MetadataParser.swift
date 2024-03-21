//
//  MetadataParser.swift
//  Debug App
//
//  Created by Niall Quinn on 11/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation


struct MetadataParser {

    func parse(_ metadata: String?) -> [String: Any] {
        guard let metadata = metadata else { return [:] }

        if let jsonData = metadata.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            return jsonObject
        }

        let keyValuePairs = metadata
            .split(separator: "\n")
            .map { $0.split(separator: "=").map { String($0).trimmingCharacters(in: .whitespaces) } }
            .filter { $0.count > 1 }
            .map { (keyValue: [String]) -> (String, Any) in
                let (key, value) = (keyValue[0], keyValue[1])
                let parsedValue = parseValue(value)
                return (key, parsedValue)
            }

        return Dictionary(uniqueKeysWithValues: keyValuePairs)
    }

    private func parseValue(_ value: String) -> Any {
        // Boolean
        if value.lowercased() == "true" { return true }
        if value.lowercased() == "false" { return false }

        if let int = Int(value) { return int }
        if let number = Double(value) { return number }
        
        // String
        if value.hasPrefix("\"") && value.hasSuffix("\"") {
            return String(value.dropFirst().dropLast())
        }

        // the rest is returned as is
        return value
    }
}
