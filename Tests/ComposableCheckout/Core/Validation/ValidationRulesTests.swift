//
//  ValidationRulesTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ValidationRulesTests: XCTestCase {
    
    // MARK: - RequiredFieldRule Tests
    
    func testRequiredFieldRule_ValidInput() async throws {
        let rule = RequiredFieldRule(fieldName: "Test Field")
        
        let result = rule.validate("valid input")
        XCTAssertTrue(result.isValid, "Non-empty input should pass required field validation")
    }
    
    func testRequiredFieldRule_NilInput() async throws {
        let rule = RequiredFieldRule(fieldName: "Test Field")
        
        let result = rule.validate(nil)
        XCTAssertFalse(result.isValid, "Nil input should fail required field validation")
        
        if !result.isValid, let code = result.errorCode, let message = result.errorMessage {
            XCTAssertEqual(code, "required-test-field", "Should generate correct error code")
            XCTAssertTrue(message.contains("Test Field"), "Error message should mention field name")
            XCTAssertTrue(message.contains("required"), "Error message should mention requirement")
        } else {
            XCTFail("Invalid result should contain error code and message")
        }
    }
    
    func testRequiredFieldRule_EmptyString() async throws {
        let rule = RequiredFieldRule(fieldName: "Test Field")
        
        let result = rule.validate("")
        XCTAssertFalse(result.isValid, "Empty string should fail required field validation")
    }
    
    func testRequiredFieldRule_WhitespaceOnly() async throws {
        let rule = RequiredFieldRule(fieldName: "Test Field")
        
        let result = rule.validate("   \t\n   ")
        XCTAssertFalse(result.isValid, "Whitespace-only input should fail required field validation")
    }
    
    func testRequiredFieldRule_CustomErrorCode() async throws {
        let rule = RequiredFieldRule(fieldName: "Custom Field", errorCode: "custom-error-code")
        
        let result = rule.validate(nil)
        XCTAssertFalse(result.isValid)
        
        if !result.isValid, let code = result.errorCode {
            XCTAssertEqual(code, "custom-error-code", "Should use custom error code")
        } else {
            XCTFail("Invalid result should contain error code")
        }
    }
    
    func testRequiredFieldRule_WhitespaceAroundValidInput() async throws {
        let rule = RequiredFieldRule(fieldName: "Test Field")
        
        let result = rule.validate("  valid input  ")
        XCTAssertTrue(result.isValid, "Input with whitespace around valid content should pass")
    }
    
    // MARK: - LengthRule Tests
    
    func testLengthRule_ValidLength() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 3, maxLength: 10)
        
        let result = rule.validate("valid")
        XCTAssertTrue(result.isValid, "Input within length range should pass validation")
    }
    
    func testLengthRule_MinLengthOnly() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 3)
        
        let validResult = rule.validate("test")
        XCTAssertTrue(validResult.isValid, "Input meeting minimum length should pass")
        
        let veryLongResult = rule.validate(String(repeating: "a", count: 1000))
        XCTAssertTrue(veryLongResult.isValid, "Very long input should pass when no max length set")
    }
    
    func testLengthRule_TooShort() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 5, maxLength: 15)
        
        let result = rule.validate("abc")
        XCTAssertFalse(result.isValid, "Input shorter than minimum should fail validation")
        
        if !result.isValid, let code = result.errorCode, let message = result.errorMessage {
            XCTAssertEqual(code, "length-test-field-min", "Should generate correct min length error code")
            XCTAssertTrue(message.contains("at least 5"), "Error message should mention minimum length")
        } else {
            XCTFail("Invalid result should contain error code and message")
        }
    }
    
    func testLengthRule_TooLong() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 3, maxLength: 8)
        
        let result = rule.validate("this is way too long")
        XCTAssertFalse(result.isValid, "Input longer than maximum should fail validation")
        
        if !result.isValid, let code = result.errorCode, let message = result.errorMessage {
            XCTAssertEqual(code, "length-test-field-max", "Should generate correct max length error code")
            XCTAssertTrue(message.contains("not exceed 8"), "Error message should mention maximum length")
        } else {
            XCTFail("Invalid result should contain error code and message")
        }
    }
    
    func testLengthRule_ExactMinLength() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 5, maxLength: 10)
        
        let result = rule.validate("exact")
        XCTAssertTrue(result.isValid, "Input exactly at minimum length should pass")
    }
    
    func testLengthRule_ExactMaxLength() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 3, maxLength: 8)
        
        let result = rule.validate("exactmax")
        XCTAssertTrue(result.isValid, "Input exactly at maximum length should pass")
    }
    
    func testLengthRule_TrimsWhitespace() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 5, maxLength: 10)
        
        // Input with whitespace that would be too short after trimming
        let result = rule.validate("  ab  ")
        XCTAssertFalse(result.isValid, "Should trim whitespace before checking length")
    }
    
    func testLengthRule_CustomErrorPrefix() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 5, errorCodePrefix: "custom-prefix")
        
        let result = rule.validate("abc")
        XCTAssertFalse(result.isValid)
        
        if !result.isValid, let code = result.errorCode {
            XCTAssertEqual(code, "custom-prefix-min", "Should use custom error code prefix")
        } else {
            XCTFail("Invalid result should contain error code")
        }
    }
    
    // MARK: - CharacterSetRule Tests
    
    func testCharacterSetRule_ValidCharacters() async throws {
        let numericCharacterSet = CharacterSet(charactersIn: "0123456789")
        let rule = CharacterSetRule(fieldName: "Numeric Field", allowedCharacterSet: numericCharacterSet)
        
        let result = rule.validate("12345")
        XCTAssertTrue(result.isValid, "Input with only allowed characters should pass validation")
    }
    
    func testCharacterSetRule_InvalidCharacters() async throws {
        let numericCharacterSet = CharacterSet(charactersIn: "0123456789")
        let rule = CharacterSetRule(fieldName: "Numeric Field", allowedCharacterSet: numericCharacterSet)
        
        let result = rule.validate("123a5")
        XCTAssertFalse(result.isValid, "Input with disallowed characters should fail validation")
        
        if !result.isValid, let code = result.errorCode, let message = result.errorMessage {
            XCTAssertEqual(code, "invalid-chars-numeric-field", "Should generate correct character set error code")
            XCTAssertTrue(message.contains("invalid characters"), "Error message should mention invalid characters")
        } else {
            XCTFail("Invalid result should contain error code and message")
        }
    }
    
    func testCharacterSetRule_EmptyInput() async throws {
        let alphaCharacterSet = CharacterSet.letters
        let rule = CharacterSetRule(fieldName: "Alpha Field", allowedCharacterSet: alphaCharacterSet)
        
        let result = rule.validate("")
        XCTAssertTrue(result.isValid, "Empty input should pass character set validation")
    }
    
    func testCharacterSetRule_SpecialCharacters() async throws {
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()")
        let rule = CharacterSetRule(fieldName: "Special Field", allowedCharacterSet: specialCharacterSet)
        
        let validResult = rule.validate("!@#")
        XCTAssertTrue(validResult.isValid, "Input with allowed special characters should pass")
        
        let invalidResult = rule.validate("!@#abc")
        XCTAssertFalse(invalidResult.isValid, "Input with disallowed characters should fail")
    }
    
    func testCharacterSetRule_UnicodeCharacters() async throws {
        let emojiCharacterSet = CharacterSet(charactersIn: "😀😃😄😁")
        let rule = CharacterSetRule(fieldName: "Emoji Field", allowedCharacterSet: emojiCharacterSet)
        
        let validResult = rule.validate("😀😃")
        XCTAssertTrue(validResult.isValid, "Input with allowed emoji characters should pass")
        
        let invalidResult = rule.validate("😀😇") // 😇 not in allowed set
        XCTAssertFalse(invalidResult.isValid, "Input with disallowed emoji should fail")
    }
    
    func testCharacterSetRule_AlphanumericCharacterSet() async throws {
        let alphanumericCharacterSet = CharacterSet.alphanumerics
        let rule = CharacterSetRule(fieldName: "Alphanumeric Field", allowedCharacterSet: alphanumericCharacterSet)
        
        let validResult = rule.validate("Test123")
        XCTAssertTrue(validResult.isValid, "Alphanumeric input should pass")
        
        let invalidResult = rule.validate("Test-123")
        XCTAssertFalse(invalidResult.isValid, "Input with hyphen should fail alphanumeric validation")
    }
    
    func testCharacterSetRule_CustomErrorCode() async throws {
        let numericCharacterSet = CharacterSet.decimalDigits
        let rule = CharacterSetRule(fieldName: "Test Field", allowedCharacterSet: numericCharacterSet, errorCode: "custom-char-error")
        
        let result = rule.validate("abc")
        XCTAssertFalse(result.isValid)
        
        if !result.isValid, let code = result.errorCode {
            XCTAssertEqual(code, "custom-char-error", "Should use custom error code")
        } else {
            XCTFail("Invalid result should contain error code")
        }
    }
    
    // MARK: - Combined Rule Tests
    
    func testCombinedRules_RequiredAndLength() async throws {
        let requiredRule = RequiredFieldRule(fieldName: "Password")
        let lengthRule = LengthRule(fieldName: "Password", minLength: 8, maxLength: 20)
        
        // Test empty input
        let emptyResult = requiredRule.validate("")
        XCTAssertFalse(emptyResult.isValid, "Empty input should fail required validation")
        
        // Test too short but non-empty
        let shortInput = "short"
        let requiredShortResult = requiredRule.validate(shortInput)
        let lengthShortResult = lengthRule.validate(shortInput)
        
        XCTAssertTrue(requiredShortResult.isValid, "Non-empty input should pass required validation")
        XCTAssertFalse(lengthShortResult.isValid, "Too short input should fail length validation")
        
        // Test valid input
        let validInput = "validpassword"
        let requiredValidResult = requiredRule.validate(validInput)
        let lengthValidResult = lengthRule.validate(validInput)
        
        XCTAssertTrue(requiredValidResult.isValid, "Valid input should pass required validation")
        XCTAssertTrue(lengthValidResult.isValid, "Valid input should pass length validation")
    }
    
    func testCombinedRules_LengthAndCharacterSet() async throws {
        let lengthRule = LengthRule(fieldName: "PIN", minLength: 4, maxLength: 6)
        let numericRule = CharacterSetRule(fieldName: "PIN", allowedCharacterSet: CharacterSet.decimalDigits)
        
        // Test valid PIN
        let validPin = "1234"
        let lengthResult = lengthRule.validate(validPin)
        let numericResult = numericRule.validate(validPin)
        
        XCTAssertTrue(lengthResult.isValid, "Valid PIN should pass length validation")
        XCTAssertTrue(numericResult.isValid, "Numeric PIN should pass character set validation")
        
        // Test PIN with correct length but invalid characters
        let invalidPin = "12a4"
        let lengthInvalidResult = lengthRule.validate(invalidPin)
        let numericInvalidResult = numericRule.validate(invalidPin)
        
        XCTAssertTrue(lengthInvalidResult.isValid, "Correct length should pass length validation")
        XCTAssertFalse(numericInvalidResult.isValid, "Non-numeric characters should fail character set validation")
    }
    
    // MARK: - Edge Cases
    
    func testValidationRules_WhitespaceHandling() async throws {
        let requiredRule = RequiredFieldRule(fieldName: "Test")
        let lengthRule = LengthRule(fieldName: "Test", minLength: 3, maxLength: 10)
        
        // Test various whitespace scenarios
        let inputs = [
            "   ",           // Only spaces
            "\t\t",         // Only tabs
            "\n\n",         // Only newlines
            " \t\n ",       // Mixed whitespace
            " valid ",      // Valid content with whitespace
            "  ab  "        // Content too short after trimming
        ]
        
        for input in inputs {
            let reqResult = requiredRule.validate(input)
            let lenResult = lengthRule.validate(input)
            
            if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                XCTAssertFalse(reqResult.isValid, "Whitespace-only input should fail required validation: '\(input)'")
            } else {
                XCTAssertTrue(reqResult.isValid, "Input with content should pass required validation: '\(input)'")
            }
        }
    }
    
    func testValidationRules_EdgeCaseLengths() async throws {
        let rule = LengthRule(fieldName: "Test", minLength: 0, maxLength: 1)
        
        let emptyResult = rule.validate("")
        XCTAssertTrue(emptyResult.isValid, "Empty string should pass when min length is 0")
        
        let singleCharResult = rule.validate("a")
        XCTAssertTrue(singleCharResult.isValid, "Single character should pass when max length is 1")
        
        let twoCharResult = rule.validate("ab")
        XCTAssertFalse(twoCharResult.isValid, "Two characters should fail when max length is 1")
    }
}
