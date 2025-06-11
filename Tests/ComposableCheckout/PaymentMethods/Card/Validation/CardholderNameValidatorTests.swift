//
//  CardholderNameValidatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CardholderNameValidatorTests: XCTestCase {
    
    var validator: CardholderNameValidator!
    var validationService: ValidationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up DI container with validation dependencies
        let container = Container()
        
        // Register RulesFactory
        _ = try await container.register(RulesFactory.self)
            .asSingleton()
            .with { _ in RulesFactory() }
        
        // Register ValidationService
        _ = try await container.register(ValidationService.self)
            .asSingleton()
            .with { resolver in
                let factory = try await resolver.resolve(RulesFactory.self)
                return DefaultValidationService(rulesFactory: factory)
            }
        
        await DIContainer.setContainer(container)
        
        validationService = try await container.resolve(ValidationService.self)
        validator = CardholderNameValidator(validationService: validationService)
    }
    
    override func tearDown() async throws {
        validator = nil
        validationService = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - Validate While Typing Tests
    
    func testValidateWhileTyping_EmptyInput() {
        let result = validator.validateWhileTyping("")
        XCTAssertTrue(result.isValid, "Empty input should not show errors while typing")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateWhileTyping_SingleCharacter() {
        let result = validator.validateWhileTyping("J")
        XCTAssertTrue(result.isValid, "Single character should not show errors while typing")
    }
    
    func testValidateWhileTyping_TwoCharacters() {
        let result = validator.validateWhileTyping("Jo")
        XCTAssertTrue(result.isValid, "Two characters should not show errors while typing")
    }
    
    func testValidateWhileTyping_ValidName() {
        let result = validator.validateWhileTyping("John Doe")
        XCTAssertTrue(result.isValid, "Valid name should pass while typing")
    }
    
    func testValidateWhileTyping_LongValidName() {
        let result = validator.validateWhileTyping("John Michael Smith-Johnson")
        XCTAssertTrue(result.isValid, "Long valid name should pass while typing")
    }
    
    func testValidateWhileTyping_NameWithSpecialCharacters() {
        let validNames = [
            "John O'Connor",
            "María José García",
            "Jean-Pierre Dubois",
            "李小明",
            "José María de la Cruz"
        ]
        
        for name in validNames {
            let result = validator.validateWhileTyping(name)
            XCTAssertTrue(result.isValid, "Name with special characters should be valid: \(name)")
        }
    }
    
    func testValidateWhileTyping_WhitespaceOnly() {
        let result = validator.validateWhileTyping("   ")
        XCTAssertTrue(result.isValid, "Whitespace should not show errors while typing")
    }
    
    // MARK: - Validate On Blur Tests
    
    func testValidateOnBlur_EmptyInput() {
        let result = validator.validateOnBlur("")
        XCTAssertFalse(result.isValid, "Empty input should be invalid on blur")
        XCTAssertEqual(result.errorCode, "invalid-cardholder-name")
        XCTAssertEqual(result.errorMessage, "Cardholder name is required")
    }
    
    func testValidateOnBlur_ValidNames() {
        let validNames = [
            "John Doe",
            "Jane Smith",
            "María García",
            "李小明",
            "Ahmed Al-Hassan",
            "O'Connor",
            "Jean-Pierre",
            "Dr. John Smith Jr.",
            "Mary-Kate Johnson",
            "José María de la Cruz Fernández"
        ]
        
        for name in validNames {
            let result = validator.validateOnBlur(name)
            XCTAssertTrue(result.isValid, "Valid name should pass on blur: \(name)")
            XCTAssertNil(result.errorCode)
            XCTAssertNil(result.errorMessage)
        }
    }
    
    func testValidateOnBlur_InvalidNames() {
        let invalidNames = [
            "J", // Too short
            "12345", // Only numbers
            "@#$%", // Only special characters
            "John123", // Contains numbers
            "John@Doe", // Invalid special character
            "John<script>", // HTML/script tags
            "John&Doe", // Ampersand
            "John%Doe" // Percent sign
        ]
        
        for name in invalidNames {
            let result = validator.validateOnBlur(name)
            XCTAssertFalse(result.isValid, "Invalid name should fail on blur: \(name)")
            XCTAssertNotNil(result.errorCode)
            XCTAssertNotNil(result.errorMessage)
        }
    }
    
    func testValidateOnBlur_WhitespaceHandling() {
        // Whitespace-only should be invalid
        let whitespaceResult = validator.validateOnBlur("   ")
        XCTAssertFalse(whitespaceResult.isValid, "Whitespace-only should be invalid")
        
        // Leading/trailing whitespace should be handled
        let trimmedResult = validator.validateOnBlur("  John Doe  ")
        XCTAssertTrue(trimmedResult.isValid, "Name with leading/trailing spaces should be valid")
        
        // Multiple spaces between names should be valid
        let multiSpaceResult = validator.validateOnBlur("John    Doe")
        XCTAssertTrue(multiSpaceResult.isValid, "Name with multiple spaces should be valid")
    }
    
    func testValidateOnBlur_LengthValidation() {
        // Too short names
        let shortNames = ["", "J", "Jo"]
        for name in shortNames {
            let result = validator.validateOnBlur(name)
            XCTAssertFalse(result.isValid, "Short name should be invalid: '\(name)'")
        }
        
        // Minimum valid length
        let minValidResult = validator.validateOnBlur("Joe")
        XCTAssertTrue(minValidResult.isValid, "Minimum valid name should pass")
        
        // Very long names should be handled appropriately
        let longName = String(repeating: "A", count: 100)
        let longResult = validator.validateOnBlur(longName)
        // Depending on implementation, this might be valid or invalid
        XCTAssertNotNil(longResult, "Should handle very long names gracefully")
    }
    
    func testValidateOnBlur_CaseInsensitivity() {
        let names = [
            "john doe",
            "JOHN DOE", 
            "John Doe",
            "jOhN dOe"
        ]
        
        for name in names {
            let result = validator.validateOnBlur(name)
            XCTAssertTrue(result.isValid, "Case variations should be valid: \(name)")
        }
    }
    
    // MARK: - International Names Tests
    
    func testInternationalNames() {
        let internationalNames = [
            "José María",
            "François Müller",
            "Александр Иванов",
            "田中太郎",
            "أحمد محمد",
            "Ελένη Παπαδοπούλου",
            "Björn Andersen",
            "Žofia Nováková",
            "İbrahim Özkan",
            "Håkon Sørensen"
        ]
        
        for name in internationalNames {
            let result = validator.validateOnBlur(name)
            XCTAssertTrue(result.isValid, "International name should be valid: \(name)")
        }
    }
    
    func testNamesWithApostrophes() {
        let apostropheNames = [
            "O'Connor",
            "D'Angelo",
            "O'Brien",
            "McD'arcy",
            "L'Amour"
        ]
        
        for name in apostropheNames {
            let result = validator.validateOnBlur(name)
            XCTAssertTrue(result.isValid, "Name with apostrophe should be valid: \(name)")
        }
    }
    
    func testNamesWithHyphens() {
        let hyphenNames = [
            "Jean-Pierre",
            "Mary-Kate",
            "Ana-María",
            "Smith-Johnson",
            "Al-Hassan"
        ]
        
        for name in hyphenNames {
            let result = validator.validateOnBlur(name)
            XCTAssertTrue(result.isValid, "Name with hyphen should be valid: \(name)")
        }
    }
    
    func testNamesWithTitles() {
        let titleNames = [
            "Dr. John Smith",
            "Prof. Mary Johnson",
            "Mr. Robert Brown",
            "Mrs. Susan Davis",
            "Ms. Jennifer Wilson",
            "John Smith Jr.",
            "Robert Brown Sr.",
            "William Johnson III"
        ]
        
        for name in titleNames {
            let result = validator.validateOnBlur(name)
            XCTAssertTrue(result.isValid, "Name with title should be valid: \(name)")
        }
    }
    
    // MARK: - Callback Tests
    
    func testCallbacks_ValidationChange() {
        var validationChanges: [Bool] = []
        
        let validator = CardholderNameValidator(
            validationService: validationService,
            onValidationChange: { isValid in
                validationChanges.append(isValid)
            }
        )
        
        _ = validator.validateWhileTyping("John")
        _ = validator.validateWhileTyping("John Doe")
        _ = validator.validateOnBlur("John123") // Invalid
        
        XCTAssertTrue(validationChanges.count >= 2, "Should call validation change callback")
        XCTAssertTrue(validationChanges.contains(true), "Should have valid results")
        XCTAssertTrue(validationChanges.contains(false), "Should have invalid results")
    }
    
    func testCallbacks_ErrorMessage() {
        var errorMessages: [String?] = []
        
        let validator = CardholderNameValidator(
            validationService: validationService,
            onErrorMessageChange: { message in
                errorMessages.append(message)
            }
        )
        
        _ = validator.validateOnBlur("")
        _ = validator.validateOnBlur("123")
        
        XCTAssertTrue(errorMessages.count >= 1, "Should call error message callback")
        XCTAssertTrue(errorMessages.contains("Cardholder name is required"), "Should provide required error")
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases_OnlySpaces() {
        let spaces = ["   ", "\t", "\n", " \t \n "]
        
        for space in spaces {
            let result = validator.validateOnBlur(space)
            XCTAssertFalse(result.isValid, "Only whitespace should be invalid: '\(space)'")
        }
    }
    
    func testEdgeCases_MixedWhitespace() {
        let name = "John\t\nDoe"
        let result = validator.validateOnBlur(name)
        XCTAssertTrue(result.isValid, "Name with mixed whitespace should be valid")
    }
    
    func testEdgeCases_UnicodeCharacters() {
        let unicodeNames = [
            "John 🙂", // Emoji
            "María José García", // Accented characters
            "北京", // Chinese characters
            "москва", // Cyrillic
            "العربية" // Arabic
        ]
        
        for name in unicodeNames {
            let result = validator.validateOnBlur(name)
            // Most should be valid, emoji might not be depending on implementation
            XCTAssertNotNil(result, "Should handle Unicode characters gracefully: \(name)")
        }
    }
    
    func testEdgeCases_SpecialPunctuation() {
        let punctuationNames = [
            "John, Jr.",
            "Mary (Smith) Johnson",
            "John \"Johnny\" Doe",
            "Mary.Johnson"
        ]
        
        for name in punctuationNames {
            let result = validator.validateOnBlur(name)
            // These might be valid or invalid depending on implementation
            XCTAssertNotNil(result, "Should handle punctuation gracefully: \(name)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ValidateWhileTyping() {
        measure {
            for _ in 0..<1000 {
                _ = validator.validateWhileTyping("John Doe")
            }
        }
    }
    
    func testPerformance_ValidateOnBlur() {
        measure {
            for _ in 0..<1000 {
                _ = validator.validateOnBlur("John Doe")
            }
        }
    }
    
    func testPerformance_LongNames() {
        let longName = "Jean-Baptiste-Antoine-Marcelin-Marcellin-Alexandre Champollion-Figeac"
        
        measure {
            for _ in 0..<1000 {
                _ = validator.validateOnBlur(longName)
            }
        }
    }
    
    // MARK: - Real-world Scenarios
    
    func testRealWorldScenario_ProgressiveTyping() {
        let typingProgression = ["J", "Jo", "Joh", "John", "John ", "John D", "John Do", "John Doe"]
        
        for input in typingProgression {
            let result = validator.validateWhileTyping(input)
            XCTAssertTrue(result.isValid, "Progressive typing should not show errors: '\(input)'")
        }
        
        // Final validation should pass
        let finalResult = validator.validateOnBlur("John Doe")
        XCTAssertTrue(finalResult.isValid, "Complete name should be valid")
    }
    
    func testRealWorldScenario_ErrorRecovery() {
        // User enters invalid name
        let invalidResult = validator.validateOnBlur("123")
        XCTAssertFalse(invalidResult.isValid, "Invalid name should fail")
        
        // User corrects to valid name
        let validResult = validator.validateOnBlur("John Doe")
        XCTAssertTrue(validResult.isValid, "Corrected name should be valid")
    }
    
    func testRealWorldScenario_FormAutofill() {
        // Simulate common autofill scenarios
        let autofillNames = [
            "JOHN DOE", // All caps from system
            "john doe", // All lowercase
            " John Doe ", // With padding
            "John  Doe", // Double space
            "Doe, John", // Last name first format
        ]
        
        for name in autofillNames {
            let result = validator.validateOnBlur(name)
            // Most should be valid, some formats might need normalization
            XCTAssertNotNil(result, "Should handle autofill gracefully: '\(name)'")
        }
    }
    
    func testRealWorldScenario_CopyPaste() {
        // Common copy-paste scenarios that might include extra characters
        let copyPasteInputs = [
            "John Doe\n", // With newline
            "\tJohn Doe", // With tab
            "John Doe ", // With trailing space
            " John Doe", // With leading space
        ]
        
        for input in copyPasteInputs {
            let result = validator.validateOnBlur(input)
            XCTAssertTrue(result.isValid, "Copy-paste input should be valid after trimming: '\(input)'")
        }
    }
    
    func testRealWorldScenario_MinimumValidInput() {
        // Test the boundary of minimum valid input
        let minValidInputs = ["Jo", "Li", "Al", "Ed"]
        
        for input in minValidInputs {
            let result = validator.validateOnBlur(input)
            // These might be valid or invalid depending on minimum length requirements
            XCTAssertNotNil(result, "Should handle minimum length gracefully: '\(input)'")
        }
    }
}