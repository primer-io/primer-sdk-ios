//
//  CardNumberValidatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CardNumberValidatorTests: XCTestCase {
    
    var validator: CardNumberValidator!
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
        validator = CardNumberValidator(validationService: validationService)
    }
    
    override func tearDown() async throws {
        validator = nil
        validationService = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - String Extension Tests
    
    func testSanitizedCardNumber() {
        XCTAssertEqual("4111 1111 1111 1111".sanitizedCardNumber, "4111111111111111")
        XCTAssertEqual("4111-1111-1111-1111".sanitizedCardNumber, "4111111111111111")
        XCTAssertEqual("4111.1111.1111.1111".sanitizedCardNumber, "4111111111111111")
        XCTAssertEqual("4111abcd1111efgh1111".sanitizedCardNumber, "411111111111")
        XCTAssertEqual("".sanitizedCardNumber, "")
        XCTAssertEqual("abc".sanitizedCardNumber, "")
    }
    
    func testHasValidCardLength() {
        // Valid lengths (13-19 digits)
        XCTAssertTrue("4111111111111".hasValidCardLength) // 13 digits (Visa minimum)
        XCTAssertTrue("4111111111111111".hasValidCardLength) // 16 digits (most common)
        XCTAssertTrue("4111111111111111111".hasValidCardLength) // 19 digits (Visa maximum)
        
        // Invalid lengths
        XCTAssertFalse("411111111111".hasValidCardLength) // 12 digits (too short)
        XCTAssertFalse("41111111111111111111".hasValidCardLength) // 20 digits (too long)
        XCTAssertFalse("".hasValidCardLength) // Empty
        XCTAssertFalse("4111".hasValidCardLength) // Too short
    }
    
    func testIsCompleteCardNumber() {
        let visa = CardNetwork.visa
        let amex = CardNetwork.amex
        
        XCTAssertTrue("4111111111111111".isCompleteCardNumber(for: visa)) // 16 digits for Visa
        XCTAssertFalse("411111111111111".isCompleteCardNumber(for: visa)) // 15 digits for Visa
        
        XCTAssertTrue("378282246310005".isCompleteCardNumber(for: amex)) // 15 digits for Amex
        XCTAssertFalse("37828224631000".isCompleteCardNumber(for: amex)) // 14 digits for Amex
    }
    
    // MARK: - CardNetwork Extension Tests
    
    func testShouldPerformFullValidation() {
        let visa = CardNetwork.visa
        
        XCTAssertTrue(visa.shouldPerformFullValidation(for: "4111111111111111")) // 16 digits
        XCTAssertTrue(visa.shouldPerformFullValidation(for: "4111111111111")) // 13 digits (minimum)
        XCTAssertFalse(visa.shouldPerformFullValidation(for: "411111111111")) // 12 digits (too short)
        XCTAssertFalse(visa.shouldPerformFullValidation(for: "411")) // Very short
    }
    
    func testValidationHint() {
        let visa = CardNetwork.visa
        
        XCTAssertEqual(visa.validationHint(for: "4111"), "Enter 12 more digits")
        XCTAssertEqual(visa.validationHint(for: "411111111111111"), "Enter 1 more digit")
        XCTAssertNil(visa.validationHint(for: "4111111111111111")) // Complete number
    }
    
    // MARK: - Validate While Typing Tests
    
    func testValidateWhileTyping_EmptyInput() {
        let result = validator.validateWhileTyping("")
        XCTAssertTrue(result.isValid, "Empty input should not show errors while typing")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateWhileTyping_PartialInput() {
        let result = validator.validateWhileTyping("4111")
        XCTAssertTrue(result.isValid, "Partial input should not show errors while typing")
    }
    
    func testValidateWhileTyping_CompleteValidVisa() {
        var networkChangeCallCount = 0
        var detectedNetwork: CardNetwork?
        
        validator.onCardNetworkChange = { network in
            networkChangeCallCount += 1
            detectedNetwork = network
        }
        
        let result = validator.validateWhileTyping("4111111111111111")
        
        XCTAssertTrue(result.isValid, "Valid complete card number should pass while typing")
        XCTAssertEqual(networkChangeCallCount, 1, "Should detect and notify network change")
        XCTAssertEqual(detectedNetwork, .visa, "Should detect Visa network")
    }
    
    func testValidateWhileTyping_CompleteInvalidCard() {
        let result = validator.validateWhileTyping("4111111111111112") // Invalid Luhn
        XCTAssertFalse(result.isValid, "Invalid complete card should fail validation even while typing")
    }
    
    func testValidateWhileTyping_NetworkDetection() {
        var detectedNetworks: [CardNetwork] = []
        
        validator.onCardNetworkChange = { network in
            detectedNetworks.append(network)
        }
        
        // Test various card networks
        _ = validator.validateWhileTyping("4111111111111111") // Visa
        _ = validator.validateWhileTyping("5555555555554444") // Mastercard
        _ = validator.validateWhileTyping("378282246310005") // Amex
        
        XCTAssertTrue(detectedNetworks.contains(.visa), "Should detect Visa")
        XCTAssertTrue(detectedNetworks.contains(.masterCard), "Should detect Mastercard")
        XCTAssertTrue(detectedNetworks.contains(.amex), "Should detect Amex")
    }
    
    func testValidateWhileTyping_FormattedInput() {
        let result = validator.validateWhileTyping("4111 1111 1111 1111")
        XCTAssertTrue(result.isValid, "Should handle formatted input")
    }
    
    // MARK: - Validate On Blur Tests
    
    func testValidateOnBlur_EmptyInput() {
        let result = validator.validateOnBlur("")
        
        XCTAssertFalse(result.isValid, "Empty input should be invalid on blur")
        XCTAssertEqual(result.errorCode, "invalid-card-number")
        XCTAssertEqual(result.errorMessage, "Card number is required")
    }
    
    func testValidateOnBlur_ValidVisaCard() {
        let result = validator.validateOnBlur("4111111111111111")
        XCTAssertTrue(result.isValid, "Valid Visa card should pass blur validation")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateOnBlur_ValidMastercardCard() {
        let result = validator.validateOnBlur("5555555555554444")
        XCTAssertTrue(result.isValid, "Valid Mastercard should pass blur validation")
    }
    
    func testValidateOnBlur_ValidAmexCard() {
        let result = validator.validateOnBlur("378282246310005")
        XCTAssertTrue(result.isValid, "Valid Amex card should pass blur validation")
    }
    
    func testValidateOnBlur_InvalidLuhnChecksum() {
        let result = validator.validateOnBlur("4111111111111112")
        XCTAssertFalse(result.isValid, "Invalid Luhn checksum should fail")
        XCTAssertNotNil(result.errorCode)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateOnBlur_InvalidLength() {
        let result = validator.validateOnBlur("411111111111")
        XCTAssertFalse(result.isValid, "Invalid length should fail")
    }
    
    func testValidateOnBlur_FormattedInput() {
        let result = validator.validateOnBlur("4111 1111 1111 1111")
        XCTAssertTrue(result.isValid, "Should handle formatted input on blur")
    }
    
    func testValidateOnBlur_NonNumericInput() {
        let result = validator.validateOnBlur("not-a-card-number")
        XCTAssertFalse(result.isValid, "Non-numeric input should fail")
    }
    
    // MARK: - Internal Helper Method Tests
    
    func testInternalValidationHint() {
        // Test for empty input
        XCTAssertNil(validator.internalValidationHint(for: ""))
        
        // Test for partial Visa input
        let visaHint = validator.internalValidationHint(for: "4111")
        XCTAssertNotNil(visaHint)
        XCTAssertTrue(visaHint!.contains("12 more digit"))
        
        // Test for complete input
        XCTAssertNil(validator.internalValidationHint(for: "4111111111111111"))
    }
    
    func testInternalValidateWithContext() {
        // Test valid input
        let (validResult, validHint) = validator.internalValidateWithContext("4111111111111111")
        XCTAssertTrue(validResult.isValid)
        XCTAssertNil(validHint)
        
        // Test partial input
        let (partialResult, partialHint) = validator.internalValidateWithContext("4111")
        XCTAssertFalse(partialResult.isValid)
        XCTAssertNotNil(partialHint)
        
        // Test empty input
        let (emptyResult, emptyHint) = validator.internalValidateWithContext("")
        XCTAssertFalse(emptyResult.isValid)
        XCTAssertNil(emptyHint)
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases_WhitespaceInput() {
        let result = validator.validateOnBlur("   ")
        XCTAssertFalse(result.isValid, "Whitespace should be treated as empty")
    }
    
    func testEdgeCases_MixedFormatting() {
        let inputs = [
            "4111-1111-1111-1111",
            "4111.1111.1111.1111",
            "4111 1111 1111 1111",
            "4111_1111_1111_1111"
        ]
        
        for input in inputs {
            let result = validator.validateOnBlur(input)
            XCTAssertTrue(result.isValid, "Should handle various formatting: \(input)")
        }
    }
    
    func testEdgeCases_VeryLongInput() {
        let longInput = String(repeating: "4", count: 100)
        let result = validator.validateOnBlur(longInput)
        XCTAssertFalse(result.isValid, "Very long input should be invalid")
    }
    
    func testEdgeCases_SpecialCharacters() {
        let result = validator.validateOnBlur("4111@1111#1111$1111")
        XCTAssertTrue(result.isValid, "Should extract numbers from special characters")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ValidateWhileTyping() {
        measure {
            for _ in 0..<100 {
                _ = validator.validateWhileTyping("4111111111111111")
            }
        }
    }
    
    func testPerformance_ValidateOnBlur() {
        measure {
            for _ in 0..<100 {
                _ = validator.validateOnBlur("4111111111111111")
            }
        }
    }
    
    func testPerformance_NetworkDetection() {
        measure {
            for _ in 0..<100 {
                _ = validator.validateWhileTyping("4111111111111111")
                _ = validator.validateWhileTyping("5555555555554444")
                _ = validator.validateWhileTyping("378282246310005")
            }
        }
    }
    
    // MARK: - Network Change Callback Tests
    
    func testNetworkChangeCallback_MultipleNetworks() {
        var networkChanges: [(String, CardNetwork)] = []
        
        validator.onCardNetworkChange = { network in
            networkChanges.append(("detected", network))
        }
        
        // Test progressive typing that changes networks
        _ = validator.validateWhileTyping("4") // Should detect Visa
        _ = validator.validateWhileTyping("5") // Should detect Mastercard
        _ = validator.validateWhileTyping("3") // Should detect Amex
        
        XCTAssertEqual(networkChanges.count, 3, "Should detect all network changes")
    }
    
    func testNetworkChangeCallback_NoCallbackForUnknown() {
        var callbackCount = 0
        
        validator.onCardNetworkChange = { _ in
            callbackCount += 1
        }
        
        _ = validator.validateWhileTyping("9") // Unknown network
        
        XCTAssertEqual(callbackCount, 0, "Should not call callback for unknown networks")
    }
    
    func testNetworkChangeCallback_CallbackTiming() {
        var callbackCount = 0
        
        validator.onCardNetworkChange = { _ in
            callbackCount += 1
        }
        
        // Multiple calls with same network should still trigger callbacks
        _ = validator.validateWhileTyping("4111")
        _ = validator.validateWhileTyping("4111111")
        _ = validator.validateWhileTyping("4111111111")
        
        XCTAssertEqual(callbackCount, 3, "Should call callback on each validation with known network")
    }
}