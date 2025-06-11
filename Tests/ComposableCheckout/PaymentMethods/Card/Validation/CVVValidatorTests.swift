//
//  CVVValidatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CVVValidatorTests: XCTestCase {
    
    var validationService: ValidationService!
    var visaValidator: CVVValidator!
    var amexValidator: CVVValidator!
    
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
        visaValidator = CVVValidator(validationService: validationService, cardNetwork: .visa)
        amexValidator = CVVValidator(validationService: validationService, cardNetwork: .amex)
    }
    
    override func tearDown() async throws {
        validationService = nil
        visaValidator = nil
        amexValidator = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - String Extension Tests
    
    func testIsValidCVVFormat() {
        // Valid formats
        XCTAssertTrue("123".isValidCVVFormat)
        XCTAssertTrue("1234".isValidCVVFormat)
        XCTAssertTrue("999".isValidCVVFormat)
        
        // Invalid formats
        XCTAssertFalse("".isValidCVVFormat) // Empty
        XCTAssertFalse("12a".isValidCVVFormat) // Contains letters
        XCTAssertFalse("12.3".isValidCVVFormat) // Contains special characters
        XCTAssertFalse("12 3".isValidCVVFormat) // Contains spaces
    }
    
    func testHasValidCVVLength() {
        // Visa/Mastercard (3 digits)
        XCTAssertTrue("123".hasValidCVVLength(for: .visa))
        XCTAssertTrue("123".hasValidCVVLength(for: .masterCard))
        XCTAssertFalse("12".hasValidCVVLength(for: .visa))
        XCTAssertFalse("1234".hasValidCVVLength(for: .visa))
        
        // Amex (4 digits)
        XCTAssertTrue("1234".hasValidCVVLength(for: .amex))
        XCTAssertFalse("123".hasValidCVVLength(for: .amex))
        XCTAssertFalse("12345".hasValidCVVLength(for: .amex))
    }
    
    func testCVVCompletionStatus() {
        // Test for Visa (3 digits)
        XCTAssertEqual("12".cvvCompletionStatus(for: .visa), .incomplete(remaining: 1))
        XCTAssertEqual("123".cvvCompletionStatus(for: .visa), .complete)
        XCTAssertEqual("1234".cvvCompletionStatus(for: .visa), .tooLong)
        XCTAssertEqual("12a".cvvCompletionStatus(for: .visa), .invalidFormat)
        
        // Test for Amex (4 digits)
        XCTAssertEqual("123".cvvCompletionStatus(for: .amex), .incomplete(remaining: 1))
        XCTAssertEqual("1234".cvvCompletionStatus(for: .amex), .complete)
        XCTAssertEqual("12345".cvvCompletionStatus(for: .amex), .tooLong)
        XCTAssertEqual("123a".cvvCompletionStatus(for: .amex), .invalidFormat)
    }
    
    // MARK: - CardNetwork Extension Tests
    
    func testExpectedCVVLength() {
        XCTAssertEqual(CardNetwork.visa.expectedCVVLength, 3)
        XCTAssertEqual(CardNetwork.masterCard.expectedCVVLength, 3)
        XCTAssertEqual(CardNetwork.amex.expectedCVVLength, 4)
        XCTAssertEqual(CardNetwork.discover.expectedCVVLength, 3)
    }
    
    func testCVVFieldName() {
        XCTAssertEqual(CardNetwork.visa.cvvFieldName, "CVV (3 digits)")
        XCTAssertEqual(CardNetwork.masterCard.cvvFieldName, "CVV (3 digits)")
        XCTAssertEqual(CardNetwork.amex.cvvFieldName, "Security Code (4 digits)")
        XCTAssertEqual(CardNetwork.discover.cvvFieldName, "CVV (3 digits)")
    }
    
    // MARK: - CVVCompletionStatus Tests
    
    func testCVVCompletionStatusUserDescription() {
        XCTAssertEqual(CVVCompletionStatus.incomplete(remaining: 1).userDescription, "Enter 1 more digit")
        XCTAssertEqual(CVVCompletionStatus.incomplete(remaining: 2).userDescription, "Enter 2 more digits")
        XCTAssertEqual(CVVCompletionStatus.complete.userDescription, "CVV complete")
        XCTAssertEqual(CVVCompletionStatus.tooLong.userDescription, "CVV too long")
        XCTAssertEqual(CVVCompletionStatus.invalidFormat.userDescription, "CVV must contain only numbers")
    }
    
    // MARK: - Validate While Typing Tests (Visa)
    
    func testValidateWhileTyping_Visa_EmptyInput() {
        let result = visaValidator.validateWhileTyping("")
        XCTAssertTrue(result.isValid, "Empty input should not show errors while typing")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateWhileTyping_Visa_PartialValidInput() {
        let result = visaValidator.validateWhileTyping("12")
        XCTAssertTrue(result.isValid, "Partial valid input should not show errors while typing")
    }
    
    func testValidateWhileTyping_Visa_CompleteValidInput() {
        let result = visaValidator.validateWhileTyping("123")
        XCTAssertTrue(result.isValid, "Complete valid CVV should pass while typing")
    }
    
    func testValidateWhileTyping_Visa_InvalidFormat() {
        let result = visaValidator.validateWhileTyping("12a")
        XCTAssertFalse(result.isValid, "Invalid format should fail immediately")
        XCTAssertEqual(result.errorCode, "invalid-cvv-format")
        XCTAssertEqual(result.errorMessage, "Input should contain only digits")
    }
    
    func testValidateWhileTyping_Visa_TooLong() {
        let result = visaValidator.validateWhileTyping("1234")
        XCTAssertTrue(result.isValid, "Too long input should not show errors while typing (lenient)")
    }
    
    // MARK: - Validate While Typing Tests (Amex)
    
    func testValidateWhileTyping_Amex_PartialValidInput() {
        let result = amexValidator.validateWhileTyping("123")
        XCTAssertTrue(result.isValid, "Partial Amex CVV should not show errors while typing")
    }
    
    func testValidateWhileTyping_Amex_CompleteValidInput() {
        let result = amexValidator.validateWhileTyping("1234")
        XCTAssertTrue(result.isValid, "Complete valid Amex CVV should pass while typing")
    }
    
    func testValidateWhileTyping_Amex_InvalidFormat() {
        let result = amexValidator.validateWhileTyping("123a")
        XCTAssertFalse(result.isValid, "Invalid format should fail immediately for Amex")
        XCTAssertEqual(result.errorCode, "invalid-cvv-format")
    }
    
    // MARK: - Validate On Blur Tests (Visa)
    
    func testValidateOnBlur_Visa_EmptyInput() {
        let result = visaValidator.validateOnBlur("")
        XCTAssertFalse(result.isValid, "Empty input should be invalid on blur")
        XCTAssertEqual(result.errorCode, "invalid-cvv")
        XCTAssertEqual(result.errorMessage, "CVV is required")
    }
    
    func testValidateOnBlur_Visa_ValidInput() {
        let result = visaValidator.validateOnBlur("123")
        XCTAssertTrue(result.isValid, "Valid Visa CVV should pass blur validation")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateOnBlur_Visa_TooShort() {
        let result = visaValidator.validateOnBlur("12")
        XCTAssertFalse(result.isValid, "Too short CVV should fail blur validation")
        XCTAssertNotNil(result.errorCode)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateOnBlur_Visa_TooLong() {
        let result = visaValidator.validateOnBlur("1234")
        XCTAssertFalse(result.isValid, "Too long CVV should fail blur validation")
        XCTAssertNotNil(result.errorCode)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateOnBlur_Visa_InvalidFormat() {
        let result = visaValidator.validateOnBlur("12a")
        XCTAssertFalse(result.isValid, "Invalid format should fail blur validation")
        XCTAssertNotNil(result.errorCode)
        XCTAssertNotNil(result.errorMessage)
    }
    
    // MARK: - Validate On Blur Tests (Amex)
    
    func testValidateOnBlur_Amex_ValidInput() {
        let result = amexValidator.validateOnBlur("1234")
        XCTAssertTrue(result.isValid, "Valid Amex CVV should pass blur validation")
    }
    
    func testValidateOnBlur_Amex_TooShort() {
        let result = amexValidator.validateOnBlur("123")
        XCTAssertFalse(result.isValid, "Too short Amex CVV should fail")
    }
    
    func testValidateOnBlur_Amex_TooLong() {
        let result = amexValidator.validateOnBlur("12345")
        XCTAssertFalse(result.isValid, "Too long Amex CVV should fail")
    }
    
    // MARK: - Card Network Update Tests
    
    func testUpdateCardNetwork() {
        // Start with Visa (3 digits)
        let validator = CVVValidator(validationService: validationService, cardNetwork: .visa)
        
        // 3-digit CVV should be valid for Visa
        let visaResult = validator.validateOnBlur("123")
        XCTAssertTrue(visaResult.isValid, "3 digits should be valid for Visa")
        
        // Update to Amex (4 digits)
        validator.updateCardNetwork(.amex)
        
        // Same 3-digit CVV should now be invalid for Amex
        let amexResult = validator.validateOnBlur("123")
        XCTAssertFalse(amexResult.isValid, "3 digits should be invalid for Amex")
        
        // 4-digit CVV should be valid for Amex
        let amexValidResult = validator.validateOnBlur("1234")
        XCTAssertTrue(amexValidResult.isValid, "4 digits should be valid for Amex")
    }
    
    func testUpdateCardNetwork_DifferentLengths() {
        let validator = CVVValidator(validationService: validationService, cardNetwork: .masterCard)
        
        // Test all standard networks
        let networks: [CardNetwork] = [.visa, .masterCard, .discover, .amex]
        
        for network in networks {
            validator.updateCardNetwork(network)
            let expectedLength = network.expectedCVVLength
            let validCVV = String(repeating: "1", count: expectedLength)
            
            let result = validator.validateOnBlur(validCVV)
            XCTAssertTrue(result.isValid, "Should accept \(expectedLength) digits for \(network)")
        }
    }
    
    // MARK: - Internal Helper Method Tests
    
    func testInternalCompletionStatus() {
        // Test with Visa
        XCTAssertEqual(visaValidator.internalCompletionStatus(for: "12"), .incomplete(remaining: 1))
        XCTAssertEqual(visaValidator.internalCompletionStatus(for: "123"), .complete)
        XCTAssertEqual(visaValidator.internalCompletionStatus(for: "1234"), .tooLong)
        XCTAssertEqual(visaValidator.internalCompletionStatus(for: "12a"), .invalidFormat)
        
        // Test with Amex
        XCTAssertEqual(amexValidator.internalCompletionStatus(for: "123"), .incomplete(remaining: 1))
        XCTAssertEqual(amexValidator.internalCompletionStatus(for: "1234"), .complete)
        XCTAssertEqual(amexValidator.internalCompletionStatus(for: "12345"), .tooLong)
    }
    
    func testInternalValidateWithStatus() {
        // Test valid input
        let (validResult, validStatus) = visaValidator.internalValidateWithStatus("123")
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validStatus, .complete)
        
        // Test incomplete input
        let (incompleteResult, incompleteStatus) = visaValidator.internalValidateWithStatus("12")
        XCTAssertFalse(incompleteResult.isValid)
        XCTAssertEqual(incompleteStatus, .incomplete(remaining: 1))
        
        // Test invalid format
        let (invalidResult, invalidStatus) = visaValidator.internalValidateWithStatus("12a")
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertEqual(invalidStatus, .invalidFormat)
    }
    
    func testInternalFieldDescription() {
        XCTAssertEqual(visaValidator.internalFieldDescription(), "CVV (3 digits)")
        XCTAssertEqual(amexValidator.internalFieldDescription(), "Security Code (4 digits)")
    }
    
    // MARK: - Callback Tests
    
    func testValidationChangeCallback() {
        var validationChanges: [Bool] = []
        
        let validator = CVVValidator(
            validationService: validationService,
            cardNetwork: .visa,
            onValidationChange: { isValid in
                validationChanges.append(isValid)
            }
        )
        
        _ = validator.validateWhileTyping("12")
        _ = validator.validateWhileTyping("123")
        _ = validator.validateWhileTyping("12a")
        
        XCTAssertEqual(validationChanges.count, 3, "Should call validation change callback")
        XCTAssertEqual(validationChanges, [true, true, false], "Should track validation state changes")
    }
    
    func testErrorMessageChangeCallback() {
        var errorMessages: [String?] = []
        
        let validator = CVVValidator(
            validationService: validationService,
            cardNetwork: .visa,
            onErrorMessageChange: { message in
                errorMessages.append(message)
            }
        )
        
        _ = validator.validateWhileTyping("123")
        _ = validator.validateWhileTyping("12a")
        _ = validator.validateOnBlur("")
        
        XCTAssertTrue(errorMessages.count >= 2, "Should call error message callback")
        XCTAssertTrue(errorMessages.contains("Input should contain only digits"), "Should provide format error")
        XCTAssertTrue(errorMessages.contains("CVV is required"), "Should provide required error")
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases_WhitespaceInput() {
        let result = visaValidator.validateOnBlur("   ")
        XCTAssertFalse(result.isValid, "Whitespace should be treated as empty")
    }
    
    func testEdgeCases_LeadingZeros() {
        let result = visaValidator.validateOnBlur("001")
        XCTAssertTrue(result.isValid, "Should accept leading zeros")
    }
    
    func testEdgeCases_AllSameDigits() {
        let visaResult = visaValidator.validateOnBlur("111")
        let amexResult = amexValidator.validateOnBlur("1111")
        
        XCTAssertTrue(visaResult.isValid, "Should accept all same digits for Visa")
        XCTAssertTrue(amexResult.isValid, "Should accept all same digits for Amex")
    }
    
    func testEdgeCases_MixedCharacters() {
        let result = visaValidator.validateWhileTyping("1a2")
        XCTAssertFalse(result.isValid, "Should reject mixed characters")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ValidateWhileTyping() {
        measure {
            for _ in 0..<1000 {
                _ = visaValidator.validateWhileTyping("123")
            }
        }
    }
    
    func testPerformance_ValidateOnBlur() {
        measure {
            for _ in 0..<1000 {
                _ = visaValidator.validateOnBlur("123")
            }
        }
    }
    
    func testPerformance_NetworkUpdates() {
        let validator = CVVValidator(validationService: validationService, cardNetwork: .visa)
        
        measure {
            for _ in 0..<1000 {
                validator.updateCardNetwork(.amex)
                validator.updateCardNetwork(.visa)
            }
        }
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testRealWorldScenario_ProgressiveTyping() {
        var validationResults: [Bool] = []
        
        let validator = CVVValidator(
            validationService: validationService,
            cardNetwork: .visa,
            onValidationChange: { isValid in
                validationResults.append(isValid)
            }
        )
        
        // Simulate user typing CVV progressively
        let inputs = ["1", "12", "123"]
        
        for input in inputs {
            _ = validator.validateWhileTyping(input)
        }
        
        // Final blur validation
        let finalResult = validator.validateOnBlur("123")
        
        XCTAssertTrue(finalResult.isValid, "Progressive typing should result in valid CVV")
        XCTAssertEqual(validationResults, [true, true, true], "Progressive typing should be valid throughout")
    }
    
    func testRealWorldScenario_CardNetworkSwitch() {
        let validator = CVVValidator(validationService: validationService, cardNetwork: .visa)
        
        // User enters 3-digit CVV for Visa
        let visaResult = validator.validateOnBlur("123")
        XCTAssertTrue(visaResult.isValid, "3 digits should be valid for Visa")
        
        // User switches to Amex card
        validator.updateCardNetwork(.amex)
        
        // Same CVV should now be invalid for Amex
        let amexResult = validator.validateOnBlur("123")
        XCTAssertFalse(amexResult.isValid, "3 digits should be invalid for Amex")
        
        // User adds fourth digit
        let amexValidResult = validator.validateOnBlur("1234")
        XCTAssertTrue(amexValidResult.isValid, "4 digits should be valid for Amex")
    }
}