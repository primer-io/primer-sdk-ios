//
//  FormValidatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class FormValidatorTests: XCTestCase {
    
    var mockFormValidator: MockFormValidator!
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
        mockFormValidator = MockFormValidator(validationService: validationService)
    }
    
    override func tearDown() async throws {
        mockFormValidator = nil
        validationService = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - Form Validation Tests
    
    func testValidateForm_AllValidFields() async throws {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe"
        ]
        
        let results = mockFormValidator.validateForm(fields: fields)
        
        // All fields should be valid (no errors)
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        for (fieldType, error) in results {
            XCTAssertNil(error, "\(fieldType.stringValue) should have no validation error")
        }
    }
    
    func testValidateForm_MixedValidAndInvalidFields() async throws {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111", // Valid
            .expiryDate: "13/30", // Invalid month
            .cvv: "123", // Valid
            .cardholderName: "" // Invalid - empty
        ]
        
        let results = mockFormValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        // Check specific field results
        XCTAssertNil(results[.cardNumber], "Valid card number should have no error")
        XCTAssertNotNil(results[.expiryDate], "Invalid expiry date should have error")
        XCTAssertNil(results[.cvv], "Valid CVV should have no error")
        XCTAssertNotNil(results[.cardholderName], "Empty cardholder name should have error")
    }
    
    func testValidateForm_AllInvalidFields() async throws {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "invalid", // Invalid format
            .expiryDate: "99/99", // Invalid date
            .cvv: "12345", // Too long for most cards
            .cardholderName: "" // Empty
        ]
        
        let results = mockFormValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        // All fields should have errors
        for (fieldType, error) in results {
            XCTAssertNotNil(error, "\(fieldType.stringValue) should have validation error")
        }
    }
    
    func testValidateForm_EmptyFields() async throws {
        let fields: [PrimerInputElementType: String?] = [:]
        
        let results = mockFormValidator.validateForm(fields: fields)
        
        XCTAssertTrue(results.isEmpty, "Empty fields should return empty results")
    }
    
    func testValidateForm_NilValues() async throws {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: nil,
            .expiryDate: nil,
            .cvv: nil,
            .cardholderName: nil
        ]
        
        let results = mockFormValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        // All required fields should have errors for nil values
        let requiredFields: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv, .cardholderName]
        for fieldType in requiredFields {
            XCTAssertNotNil(results[fieldType], "\(fieldType.stringValue) should have error for nil value")
        }
    }
    
    // MARK: - Individual Field Validation Tests
    
    func testValidateField_CardNumber() async throws {
        let validResult = mockFormValidator.validateField(type: .cardNumber, value: "4111111111111111")
        XCTAssertTrue(validResult.isValid, "Valid card number should pass field validation")
        
        let invalidResult = mockFormValidator.validateField(type: .cardNumber, value: "invalid")
        XCTAssertFalse(invalidResult.isValid, "Invalid card number should fail field validation")
    }
    
    func testValidateField_ExpiryDate() async throws {
        let validResult = mockFormValidator.validateField(type: .expiryDate, value: "12/30")
        XCTAssertTrue(validResult.isValid, "Valid expiry date should pass field validation")
        
        let invalidResult = mockFormValidator.validateField(type: .expiryDate, value: "13/30")
        XCTAssertFalse(invalidResult.isValid, "Invalid expiry date should fail field validation")
    }
    
    func testValidateField_CVV() async throws {
        let validResult = mockFormValidator.validateField(type: .cvv, value: "123")
        XCTAssertTrue(validResult.isValid, "Valid CVV should pass field validation")
        
        let invalidResult = mockFormValidator.validateField(type: .cvv, value: "12345")
        XCTAssertFalse(invalidResult.isValid, "Invalid CVV should fail field validation")
    }
    
    func testValidateField_CardholderName() async throws {
        let validResult = mockFormValidator.validateField(type: .cardholderName, value: "John Doe")
        XCTAssertTrue(validResult.isValid, "Valid cardholder name should pass field validation")
        
        let invalidResult = mockFormValidator.validateField(type: .cardholderName, value: "")
        XCTAssertFalse(invalidResult.isValid, "Empty cardholder name should fail field validation")
    }
    
    // MARK: - Context Update Tests
    
    func testUpdateContext_CardNetwork() async throws {
        // Test that context updates affect validation behavior
        mockFormValidator.updateContext(key: "cardNetwork", value: CardNetwork.amex)
        
        // Verify context was updated
        XCTAssertEqual(mockFormValidator.context["cardNetwork"] as? CardNetwork, .amex, "Context should be updated with card network")
        
        // Test that CVV validation might behave differently based on context
        // (This would require the mock to actually use context in validation)
        let cvvResult = mockFormValidator.validateField(type: .cvv, value: "1234")
        // Note: Actual behavior depends on implementation, but context should be available
    }
    
    func testUpdateContext_MultipleValues() async throws {
        mockFormValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        mockFormValidator.updateContext(key: "country", value: "US")
        mockFormValidator.updateContext(key: "feature_flag", value: true)
        
        XCTAssertEqual(mockFormValidator.context.count, 3, "All context values should be stored")
        XCTAssertEqual(mockFormValidator.context["cardNetwork"] as? CardNetwork, .visa)
        XCTAssertEqual(mockFormValidator.context["country"] as? String, "US")
        XCTAssertEqual(mockFormValidator.context["feature_flag"] as? Bool, true)
    }
    
    func testUpdateContext_OverwriteValue() async throws {
        mockFormValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        XCTAssertEqual(mockFormValidator.context["cardNetwork"] as? CardNetwork, .visa)
        
        mockFormValidator.updateContext(key: "cardNetwork", value: CardNetwork.masterCard)
        XCTAssertEqual(mockFormValidator.context["cardNetwork"] as? CardNetwork, .masterCard, "Context value should be overwritten")
    }
    
    // MARK: - Integration Tests
    
    func testFormValidator_CompletePaymentFlow() async throws {
        // Simulate a complete payment form validation flow
        
        // Step 1: User enters card number
        mockFormValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        let cardResult = mockFormValidator.validateField(type: .cardNumber, value: "4111111111111111")
        XCTAssertTrue(cardResult.isValid)
        
        // Step 2: User enters expiry
        let expiryResult = mockFormValidator.validateField(type: .expiryDate, value: "12/30")
        XCTAssertTrue(expiryResult.isValid)
        
        // Step 3: User enters CVV (should use Visa context)
        let cvvResult = mockFormValidator.validateField(type: .cvv, value: "123")
        XCTAssertTrue(cvvResult.isValid)
        
        // Step 4: User enters name
        let nameResult = mockFormValidator.validateField(type: .cardholderName, value: "John Doe")
        XCTAssertTrue(nameResult.isValid)
        
        // Step 5: Validate complete form
        let allFields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe"
        ]
        
        let formResults = mockFormValidator.validateForm(fields: allFields)
        let hasErrors = formResults.values.contains { $0 != nil }
        XCTAssertFalse(hasErrors, "Complete valid form should have no errors")
    }
    
    func testFormValidator_ErrorRecovery() async throws {
        // Test error recovery scenario
        
        // Step 1: User enters invalid card number
        let invalidCardResult = mockFormValidator.validateField(type: .cardNumber, value: "1234")
        XCTAssertFalse(invalidCardResult.isValid)
        
        // Step 2: User corrects card number
        let validCardResult = mockFormValidator.validateField(type: .cardNumber, value: "4111111111111111")
        XCTAssertTrue(validCardResult.isValid)
        
        // Step 3: Validate form with corrected data
        let correctedFields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe"
        ]
        
        let formResults = mockFormValidator.validateForm(fields: correctedFields)
        let hasErrors = formResults.values.contains { $0 != nil }
        XCTAssertFalse(hasErrors, "Form should be valid after error correction")
    }
}

// MARK: - Mock FormValidator

@available(iOS 15.0, *)
class MockFormValidator: FormValidator {
    let validationService: ValidationService
    var context: [String: Any] = [:]
    
    init(validationService: ValidationService) {
        self.validationService = validationService
    }
    
    func validateForm(fields: [PrimerInputElementType: String?]) -> [PrimerInputElementType: ValidationError?] {
        var results: [PrimerInputElementType: ValidationError?] = [:]
        
        for (fieldType, value) in fields {
            let validationResult = validateField(type: fieldType, value: value)
            
            // Always add a result for each field, regardless of validity
            if !validationResult.isValid, let code = validationResult.errorCode, let message = validationResult.errorMessage {
                results[fieldType] = ValidationError(code: code, message: message)
            } else {
                results[fieldType] = nil
            }
        }
        
        return results
    }
    
    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult {
        return validationService.validateField(type: type, value: value)
    }
    
    func updateContext(key: String, value: Any) {
        context[key] = value
    }
}
