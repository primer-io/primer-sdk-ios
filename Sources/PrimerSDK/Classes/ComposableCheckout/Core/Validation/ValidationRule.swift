//
//  ValidationResult.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Protocol defining a validation rule that can be applied to input data
public protocol ValidationRule {
    associatedtype Input

    /// Validates the input against this rule
    /// - Parameter input: The value to validate
    /// - Returns: A ValidationResult indicating success or failure
    func validate(_ input: Input) -> ValidationResult
}

/// Rule that ensures a field is not empty
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

        if let maxLength = maxLength, trimmed.count > maxLength {
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
