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

    // MARK: - Masking Patterns

    private let patterns: [MaskingPattern]

    // MARK: - Initialization

    init() {
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

            // Phone Number Masking (word boundaries prevent matching substrings of longer numbers like diagnosticsIds)
            MaskingPattern(
                regex: try! NSRegularExpression(
                    pattern: #"\b(\+?\d{1,3}[\s\-]?)?(\(?\d{3}\)?[\s\-]?)?\d{3}[\s\-]?\d{4}\b"#,
                    options: []
                ),
                replacement: Replacement.phone
            )
        ]
    }

    // MARK: - Public Methods

    func mask(text: String) -> String {
        var maskedText = text

        for pattern in patterns {
            let range = NSRange(location: 0, length: maskedText.utf16.count)
            maskedText = pattern.regex.stringByReplacingMatches(
                in: maskedText,
                options: [],
                range: range,
                withTemplate: pattern.replacement
            )
        }

        return maskedText
    }

    // MARK: - Nested Types

    private struct MaskingPattern {
        let regex: NSRegularExpression
        let replacement: String
    }
}
