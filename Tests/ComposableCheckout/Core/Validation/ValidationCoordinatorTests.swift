//
//  ValidationCoordinatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ValidationCoordinatorTests: XCTestCase {
    
    var mockCoordinator: MockValidationCoordinator!
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
        mockCoordinator = MockValidationCoordinator(validationService: validationService)
    }
    
    override func tearDown() async throws {
        mockCoordinator = nil
        validationService = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - While Typing Validation Tests
    
    func testValidateWhileTyping_LenientValidation() async throws {
        // While typing validation should be more lenient
        let partialCardNumber = "4111"
        let result = mockCoordinator.validateWhileTyping(partialCardNumber)
        
        // Should not show errors for partial input during typing
        XCTAssertTrue(result.isValid, "Partial input while typing should not show errors")
        XCTAssertEqual(mockCoordinator.validationChangeCallCount, 1, "Should trigger validation change callback")
    }
    
    func testValidateWhileTyping_ValidCompleteInput() async throws {
        let completeValidCardNumber = "4111111111111111"
        let result = mockCoordinator.validateWhileTyping(completeValidCardNumber)
        
        XCTAssertTrue(result.isValid, "Valid complete input should pass while typing validation")
        XCTAssertEqual(mockCoordinator.validationChangeCallCount, 1, "Should trigger validation change callback")
        XCTAssertEqual(mockCoordinator.errorMessageChangeCallCount, 0, "Should not trigger error message while typing")
    }
    
    func testValidateWhileTyping_InvalidButNoErrorsShown() async throws {
        let invalidInput = "clearly-invalid-input"
        let result = mockCoordinator.validateWhileTyping(invalidInput)
        
        // While typing validation should suppress errors
        XCTAssertTrue(result.isValid, "Invalid input while typing should not show errors immediately")
        XCTAssertEqual(mockCoordinator.validationChangeCallCount, 1, "Should trigger validation change callback")
        XCTAssertEqual(mockCoordinator.errorMessageChangeCallCount, 0, "Should not show error messages while typing")
    }
    
    func testValidateWhileTyping_CallbackInvocation() async throws {
        var validationState: Bool?
        mockCoordinator.onValidationChange = { isValid in
            validationState = isValid
        }
        
        let result = mockCoordinator.validateWhileTyping("4111111111111111")
        
        XCTAssertTrue(result.isValid)
        XCTAssertNotNil(validationState, "Validation change callback should be invoked")
        XCTAssertTrue(validationState!, "Callback should indicate valid state")
    }
    
    // MARK: - On Blur Validation Tests
    
    func testValidateOnBlur_ComprehensiveValidation() async throws {
        let validCardNumber = "4111111111111111"
        let result = mockCoordinator.validateOnBlur(validCardNumber)
        
        XCTAssertTrue(result.isValid, "Valid input should pass blur validation")
        XCTAssertEqual(mockCoordinator.validationChangeCallCount, 1, "Should trigger validation change callback")
        XCTAssertEqual(mockCoordinator.errorMessageChangeCallCount, 0, "Valid input should not trigger error message")
    }
    
    func testValidateOnBlur_ShowsErrorsForInvalidInput() async throws {
        let invalidCardNumber = "1234567890"
        let result = mockCoordinator.validateOnBlur(invalidCardNumber)
        
        XCTAssertFalse(result.isValid, "Invalid input should fail blur validation")
        XCTAssertEqual(mockCoordinator.validationChangeCallCount, 1, "Should trigger validation change callback")
        XCTAssertEqual(mockCoordinator.errorMessageChangeCallCount, 1, "Invalid input should trigger error message")
    }
    
    func testValidateOnBlur_ErrorMessageCallback() async throws {
        var errorMessage: String?
        mockCoordinator.onErrorMessageChange = { message in
            errorMessage = message
        }
        
        let result = mockCoordinator.validateOnBlur("invalid")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(errorMessage, "Error message callback should be invoked for invalid input")
        XCTAssertFalse(errorMessage!.isEmpty, "Error message should not be empty")
    }
    
    func testValidateOnBlur_ClearErrorForValidInput() async throws {
        var errorMessage: String? = "Previous error"
        mockCoordinator.onErrorMessageChange = { message in
            errorMessage = message
        }
        
        let result = mockCoordinator.validateOnBlur("4111111111111111")
        
        XCTAssertTrue(result.isValid)
        XCTAssertNil(errorMessage, "Error message should be cleared for valid input")
    }
    
    // MARK: - Validation Timing Strategy Tests
    
    func testValidationTimingStrategy_TypingVsBlur() async throws {
        let invalidInput = "123"
        
        // While typing - should be lenient
        let typingResult = mockCoordinator.validateWhileTyping(invalidInput)
        XCTAssertTrue(typingResult.isValid, "Typing validation should be lenient")
        
        // Reset counters
        mockCoordinator.resetCounters()
        
        // On blur - should be strict
        let blurResult = mockCoordinator.validateOnBlur(invalidInput)
        XCTAssertFalse(blurResult.isValid, "Blur validation should be strict")
        
        // Verify different callback patterns
        XCTAssertEqual(mockCoordinator.errorMessageChangeCallCount, 1, "Blur validation should show error message")
    }
    
    func testValidationTimingStrategy_ProgressiveValidation() async throws {
        // Simulate user typing progressively
        let progressiveInputs = ["4", "41", "411", "4111", "41111", "411111111111111", "4111111111111111"]
        
        for input in progressiveInputs {
            let result = mockCoordinator.validateWhileTyping(input)
            // All should pass while typing (lenient)
            XCTAssertTrue(result.isValid, "Progressive typing should not show errors: \(input)")
        }
        
        // Final validation on blur should be comprehensive
        let finalResult = mockCoordinator.validateOnBlur("4111111111111111")
        XCTAssertTrue(finalResult.isValid, "Complete valid input should pass blur validation")
    }
    
    // MARK: - Callback Coordination Tests
    
    func testCallbackCoordination_ValidationChangeOnly() async throws {
        var validationCallCount = 0
        var errorCallCount = 0
        
        mockCoordinator.onValidationChange = { _ in validationCallCount += 1 }
        mockCoordinator.onErrorMessageChange = { _ in errorCallCount += 1 }
        
        // Valid input while typing should only trigger validation change
        _ = mockCoordinator.validateWhileTyping("4111111111111111")
        
        XCTAssertEqual(validationCallCount, 1, "Should trigger validation change callback")
        XCTAssertEqual(errorCallCount, 0, "Should not trigger error message callback for valid typing")
    }
    
    func testCallbackCoordination_BothCallbacks() async throws {
        var validationCallCount = 0
        var errorCallCount = 0
        
        mockCoordinator.onValidationChange = { _ in validationCallCount += 1 }
        mockCoordinator.onErrorMessageChange = { _ in errorCallCount += 1 }
        
        // Invalid input on blur should trigger both callbacks
        _ = mockCoordinator.validateOnBlur("invalid")
        
        XCTAssertEqual(validationCallCount, 1, "Should trigger validation change callback")
        XCTAssertEqual(errorCallCount, 1, "Should trigger error message callback for invalid blur")
    }
    
    func testCallbackCoordination_NoCallbacks() async throws {
        // Test that coordinator works without callbacks set
        mockCoordinator.onValidationChange = nil
        mockCoordinator.onErrorMessageChange = nil
        
        let typingResult = mockCoordinator.validateWhileTyping("test")
        let blurResult = mockCoordinator.validateOnBlur("test")
        
        // Should not crash and should return results
        XCTAssertNotNil(typingResult, "Should return result even without callbacks")
        XCTAssertNotNil(blurResult, "Should return result even without callbacks")
    }
    
    // MARK: - Edge Cases
    
    func testValidation_EmptyInput() async throws {
        let emptyResult = mockCoordinator.validateWhileTyping("")
        XCTAssertTrue(emptyResult.isValid, "Empty input while typing should not show errors")
        
        let blurEmptyResult = mockCoordinator.validateOnBlur("")
        XCTAssertFalse(blurEmptyResult.isValid, "Empty input on blur should show validation error")
    }
    
    func testValidation_WhitespaceInput() async throws {
        let whitespaceResult = mockCoordinator.validateWhileTyping("   ")
        XCTAssertTrue(whitespaceResult.isValid, "Whitespace input while typing should not show errors")
        
        let blurWhitespaceResult = mockCoordinator.validateOnBlur("   ")
        XCTAssertFalse(blurWhitespaceResult.isValid, "Whitespace input on blur should show validation error")
    }
    
    func testValidation_VeryLongInput() async throws {
        let longInput = String(repeating: "1", count: 100)
        
        let typingResult = mockCoordinator.validateWhileTyping(longInput)
        let blurResult = mockCoordinator.validateOnBlur(longInput)
        
        // Both should handle long input gracefully
        XCTAssertNotNil(typingResult, "Should handle very long input during typing")
        XCTAssertNotNil(blurResult, "Should handle very long input during blur")
    }
    
    // MARK: - Performance Tests
    
    func testValidation_PerformanceWhileTyping() async throws {
        let input = "4111111111111111"
        
        measure {
            for _ in 0..<100 {
                _ = mockCoordinator.validateWhileTyping(input)
            }
        }
    }
    
    func testValidation_PerformanceOnBlur() async throws {
        let input = "4111111111111111"
        
        measure {
            for _ in 0..<100 {
                _ = mockCoordinator.validateOnBlur(input)
            }
        }
    }
}

// MARK: - Mock ValidationCoordinator

@available(iOS 15.0, *)
class MockValidationCoordinator: ValidationCoordinator {
    typealias InputType = String
    
    let validationService: ValidationService
    var onValidationChange: ((Bool) -> Void)?
    var onErrorMessageChange: ((String?) -> Void)?
    
    // Tracking for test verification
    var validationChangeCallCount = 0
    var errorMessageChangeCallCount = 0
    
    init(validationService: ValidationService) {
        self.validationService = validationService
    }
    
    func validateWhileTyping(_ input: String) -> ValidationResult {
        // Simulate lenient validation while typing
        validationChangeCallCount += 1
        onValidationChange?(true) // Always positive feedback while typing
        
        // For card numbers, be lenient with partial input
        if input.count < 13 {
            return .valid // Don't show errors for partial input
        }
        
        // For longer input, actually validate but don't show errors
        let actualResult = validationService.validateCardNumber(input)
        return .valid // Return valid regardless to suppress errors while typing
    }
    
    func validateOnBlur(_ input: String) -> ValidationResult {
        // Comprehensive validation on blur
        validationChangeCallCount += 1
        
        let result = validationService.validateCardNumber(input)
        
        if result.isValid {
            onValidationChange?(true)
            errorMessageChangeCallCount += 1
            onErrorMessageChange?(nil) // Clear any existing error
        } else {
            onValidationChange?(false)
            errorMessageChangeCallCount += 1
            
            if let message = result.errorMessage {
                onErrorMessageChange?(message)
            }
        }
        
        return result
    }
    
    func resetCounters() {
        validationChangeCallCount = 0
        errorMessageChangeCallCount = 0
    }
}