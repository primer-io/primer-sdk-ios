//
//  SensitiveDataMasker.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

actor SensitiveDataMasker {
    // MARK: - Constants

    private enum Replacement {
        static let card = "[REDACTED_CARD]"
        static let cvv = "$1 [REDACTED]"
        static let token = "$1[REDACTED_TOKEN]"
        static let apiKey = "$1 [REDACTED]"
        static let email = "[REDACTED_EMAIL]"
        static let phone = "[REDACTED_PHONE]"
    }

    private enum Placeholder {
        static let uuidPrefix = "___UUID_PLACEHOLDER_"
        static let uuidSuffix = "___"
    }

    // MARK: - UUID Protection Pattern

    /// UUID pattern (8-4-4-4-12 hex format) - protected from masking to prevent false positives
    private let uuidPattern: NSRegularExpression

    // MARK: - Masking Patterns

    private let patterns: [MaskingPattern]

    // MARK: - Initialization

    init() {
        // UUID pattern to protect from masking
        self.uuidPattern = try! NSRegularExpression(
            pattern: #"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b"#,
            options: []
        )

        self.patterns = [
            // Card Number Masking: Standard 16-digit (4-4-4-4) and Amex 15-digit (4-6-5) formats
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"\b\d{4}[\s\-]?(\d{4}[\s\-]?\d{4}[\s\-]?\d{3,4}|\d{6}[\s\-]?\d{5})\b"#,
                    options: []
                ),
                replacement: Replacement.card
            ),

            // CVV/CVC Masking: 3-4 digits following "CVV"/"CVC" keywords
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"(?i)(cvv|cvc)[\s:=]*\d{3,4}"#,
                    options: []
                ),
                replacement: Replacement.cvv
            ),

            // Bearer Token Masking
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"(?i)(authorization:?\s*bearer\s+)[a-zA-Z0-9_\-\.]+"#,
                    options: []
                ),
                replacement: Replacement.token
            ),

            // API Key Masking
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"(?i)(api[_\-]?key|key|token)[\s:=]+[a-zA-Z0-9_\-]{16,}"#,
                    options: []
                ),
                replacement: Replacement.apiKey
            ),

            // Email Address Masking
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"#,
                    options: []
                ),
                replacement: Replacement.email
            ),

             // Phone Number Masking (stricter patterns to avoid UUID false positives):
            //   - International: +1 234 567 8901 (requires + prefix)
            //   - Parenthesized area code: (234) 567-8901
            //   - 10-digit with separators: 234-567-8901 (requires two separators)
            // Notes:
            //   - Separators (spaces or hyphens) are required to avoid masking UUIDs or numeric IDs.
            //   - Unformatted 10-digit strings like "5551234567" are NOT masked to prevent masking transaction IDs, account numbers, etc.
            //   - Leading \b removed from ( and + patterns since those are non-word chars.
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"(\+\d{1,3}[\s\-]?\d{1,4}[\s\-]?\d{1,4}[\s\-]?\d{1,9}|\(\d{3}\)[\s\-]?\d{3}[\s\-]?\d{4}|\b\d{3}[\s\-]\d{3}[\s\-]\d{4})\b"#,
                    options: []
                ),
                replacement: Replacement.phone
            )
        ]
    }

    // MARK: - Public Methods

    func mask(text: String) -> String {
        // Step 1: Extract and protect UUIDs from masking
        let (textWithPlaceholders, uuids) = protectUUIDs(in: text)

        // Step 2: Apply masking patterns
        var maskedText = textWithPlaceholders
        for pattern in patterns {
            let range = NSRange(location: 0, length: maskedText.utf16.count)
            maskedText = pattern.regex.stringByReplacingMatches(
                in: maskedText,
                options: [],
                range: range,
                withTemplate: pattern.replacement
            )
        }

        // Step 3: Restore UUIDs
        return restoreUUIDs(in: maskedText, uuids: uuids)
    }

    // MARK: - Private Methods - UUID Protection

    private func protectUUIDs(in text: String) -> (String, [String]) {
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = uuidPattern.matches(in: text, options: [], range: range)

        guard !matches.isEmpty else { return (text, []) }

        var uuids: [String] = []
        var result = text

        // Process matches in reverse order to preserve indices
        for match in matches.reversed() {
            guard let swiftRange = Range(match.range, in: result) else { continue }
            let uuid = String(result[swiftRange])
            let placeholder = "\(Placeholder.uuidPrefix)\(uuids.count)\(Placeholder.uuidSuffix)"
            result.replaceSubrange(swiftRange, with: placeholder)
            uuids.insert(uuid, at: 0)
        }

        return (result, uuids)
    }

    private func restoreUUIDs(in text: String, uuids: [String]) -> String {
        var result = text
        for (index, uuid) in uuids.enumerated() {
            let placeholder = "\(Placeholder.uuidPrefix)\(index)\(Placeholder.uuidSuffix)"
            result = result.replacingOccurrences(of: placeholder, with: uuid)
        }
        return result
    }

    // MARK: - Nested Types

    private struct MaskingPattern {
        let regex: NSRegularExpression
        let replacement: String
    }
}
