//
//  ValidationRule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public protocol ValidationRule {
    associatedtype Input
    func validate(_ input: Input) -> ValidationResult
}

public struct RequiredFieldRule: ValidationRule {
    private let fieldName: String
    private let errorCode: String

    public init(fieldName: String, errorCode: String? = nil) {
        self.fieldName = fieldName
        self.errorCode = errorCode ?? "required-\(fieldName.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }

    public func validate(_ input: String?) -> ValidationResult {
        guard let input = input, !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(
                code: errorCode,
                message: "\(fieldName) is required"
            )
        }
        return .valid
    }
}

/// Rule that validates input length against minimum and optional maximum
public struct LengthRule: ValidationRule {
    private let fieldName: String
    private let minLength: Int
    private let maxLength: Int?
    private let errorCodePrefix: String

    public init(fieldName: String, minLength: Int, maxLength: Int? = nil, errorCodePrefix: String? = nil) {
        self.fieldName = fieldName
        self.minLength = minLength
        self.maxLength = maxLength
        self.errorCodePrefix = errorCodePrefix ?? "length-\(fieldName.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }

    public func validate(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count < minLength {
            return .invalid(
                code: "\(errorCodePrefix)-min",
                message: "\(fieldName) must be at least \(minLength) characters"
            )
        }

        if let maxLength, trimmed.count > maxLength {
            return .invalid(
                code: "\(errorCodePrefix)-max",
                message: "\(fieldName) must not exceed \(maxLength) characters"
            )
        }

        return .valid
    }
}

/// Rule that validates input against a character set
public struct CharacterSetRule: ValidationRule {
    private let fieldName: String
    private let allowedCharacterSet: CharacterSet
    private let errorCode: String

    public init(fieldName: String, allowedCharacterSet: CharacterSet, errorCode: String? = nil) {
        self.fieldName = fieldName
        self.allowedCharacterSet = allowedCharacterSet
        self.errorCode = errorCode ?? "invalid-chars-\(fieldName.lowercased().replacingOccurrences(of: " ", with: "-"))"
    }

    public func validate(_ input: String) -> ValidationResult {
        let disallowedChars = CharacterSet(charactersIn: input).subtracting(allowedCharacterSet)

        if !disallowedChars.isEmpty {
            return .invalid(
                code: errorCode,
                message: "\(fieldName) contains invalid characters"
            )
        }

        return .valid
    }
}
