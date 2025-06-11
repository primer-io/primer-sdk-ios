//
//  PaymentFormValidatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PaymentFormValidatorTests: XCTestCase {
    
    var formValidator: CardFormValidator!
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
        formValidator = CardFormValidator(validationService: validationService)
    }
    
    override func tearDown() async throws {
        formValidator = nil
        validationService = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - Form Validation Tests
    
    func testValidateForm_AllValidCardFields() {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe"
        ]
        
        let results = formValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        for (fieldType, error) in results {
            XCTAssertNil(error, "\(fieldType.stringValue) should have no validation error")
        }
    }
    
    func testValidateForm_AllValidBillingFields() {
        let fields: [PrimerInputElementType: String?] = [
            .firstName: "John",
            .lastName: "Doe",
            .addressLine1: "123 Main St",
            .addressLine2: "Apt 4B",
            .city: "New York",
            .state: "NY",
            .postalCode: "10001",
            .countryCode: "US"
        ]
        
        let results = formValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        for (fieldType, error) in results {
            XCTAssertNil(error, "\(fieldType.stringValue) should have no validation error")
        }
    }
    
    func testValidateForm_MixedCardAndBillingFields() {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe",
            .firstName: "John",
            .lastName: "Doe",
            .addressLine1: "123 Main St",
            .city: "New York",
            .postalCode: "10001"
        ]
        
        let results = formValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        for (fieldType, error) in results {
            XCTAssertNil(error, "\(fieldType.stringValue) should have no validation error")
        }
    }
    
    func testValidateForm_WithInvalidFields() {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "invalid", // Invalid card number
            .expiryDate: "13/30", // Invalid month
            .cvv: "12345", // Too long for standard cards
            .cardholderName: "", // Empty name
            .firstName: "", // Empty first name
            .postalCode: "" // Empty postal code
        ]
        
        let results = formValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        // All fields should have errors
        for (fieldType, error) in results {
            XCTAssertNotNil(error, "\(fieldType.stringValue) should have validation error")
            XCTAssertNotNil(error?.code, "Error should have code")
            XCTAssertNotNil(error?.message, "Error should have message")
        }
    }
    
    func testValidateForm_WithNilValues() {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: nil,
            .expiryDate: nil,
            .cvv: nil,
            .cardholderName: nil
        ]
        
        let results = formValidator.validateForm(fields: fields)
        
        XCTAssertEqual(results.count, fields.count, "Should return result for each field")
        
        // All fields should have errors for nil values
        for (fieldType, error) in results {
            XCTAssertNotNil(error, "\(fieldType.stringValue) should have error for nil value")
            XCTAssertTrue(error?.code.hasPrefix("required-") ?? false, "Error should be required type")
        }
    }
    
    func testValidateForm_EmptyFields() {
        let fields: [PrimerInputElementType: String?] = [:]
        
        let results = formValidator.validateForm(fields: fields)
        
        XCTAssertTrue(results.isEmpty, "Empty fields should return empty results")
    }
    
    // MARK: - Individual Field Validation Tests
    
    func testValidateField_CardNumber() {
        // Valid card number
        let validResult = formValidator.validateField(type: .cardNumber, value: "4111111111111111")
        XCTAssertTrue(validResult.isValid, "Valid card number should pass")
        
        // Invalid card number
        let invalidResult = formValidator.validateField(type: .cardNumber, value: "invalid")
        XCTAssertFalse(invalidResult.isValid, "Invalid card number should fail")
        
        // Nil value
        let nilResult = formValidator.validateField(type: .cardNumber, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil card number should fail")
        XCTAssertEqual(nilResult.errorCode, "required-cardNumber")
        XCTAssertEqual(nilResult.errorMessage, "Card number is required.")
        
        // Empty value
        let emptyResult = formValidator.validateField(type: .cardNumber, value: "")
        XCTAssertFalse(emptyResult.isValid, "Empty card number should fail")
        XCTAssertEqual(emptyResult.errorCode, "required-cardNumber")
    }
    
    func testValidateField_CVV() {
        // Set card network context
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        
        // Valid CVV for Visa
        let validResult = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertTrue(validResult.isValid, "Valid CVV should pass")
        
        // Invalid CVV
        let invalidResult = formValidator.validateField(type: .cvv, value: "12345")
        XCTAssertFalse(invalidResult.isValid, "Invalid CVV should fail")
        
        // Nil value
        let nilResult = formValidator.validateField(type: .cvv, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil CVV should fail")
        XCTAssertEqual(nilResult.errorMessage, "CVV is required.")
    }
    
    func testValidateField_ExpiryDate() {
        // Valid expiry date
        let validResult = formValidator.validateField(type: .expiryDate, value: "12/30")
        XCTAssertTrue(validResult.isValid, "Valid expiry date should pass")
        
        // Invalid format
        let invalidFormatResult = formValidator.validateField(type: .expiryDate, value: "1230")
        XCTAssertFalse(invalidFormatResult.isValid, "Invalid format should fail")
        XCTAssertEqual(invalidFormatResult.errorCode, "invalid-expiry-format")
        XCTAssertEqual(invalidFormatResult.errorMessage, "Please enter date as MM/YY")
        
        // Expired date
        let expiredResult = formValidator.validateField(type: .expiryDate, value: "12/20")
        XCTAssertFalse(expiredResult.isValid, "Expired date should fail")
        
        // Nil value
        let nilResult = formValidator.validateField(type: .expiryDate, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil expiry date should fail")
        XCTAssertEqual(nilResult.errorMessage, "Expiry date is required.")
    }
    
    func testValidateField_CardholderName() {
        // Valid name
        let validResult = formValidator.validateField(type: .cardholderName, value: "John Doe")
        XCTAssertTrue(validResult.isValid, "Valid cardholder name should pass")
        
        // Invalid name
        let invalidResult = formValidator.validateField(type: .cardholderName, value: "123")
        XCTAssertFalse(invalidResult.isValid, "Invalid cardholder name should fail")
        
        // Nil value
        let nilResult = formValidator.validateField(type: .cardholderName, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil cardholder name should fail")
        XCTAssertEqual(nilResult.errorMessage, "Cardholder name is required.")
    }
    
    func testValidateField_BillingAddressFields() {
        let billingFields: [PrimerInputElementType] = [
            .firstName, .lastName, .addressLine1, .city, .state, .postalCode, .countryCode
        ]
        
        for fieldType in billingFields {
            // Valid value
            let validResult = formValidator.validateField(type: fieldType, value: "Valid Value")
            XCTAssertTrue(validResult.isValid, "\(fieldType.stringValue) with valid value should pass")
            
            // Empty value
            let emptyResult = formValidator.validateField(type: fieldType, value: "")
            XCTAssertFalse(emptyResult.isValid, "\(fieldType.stringValue) with empty value should fail")
            
            // Whitespace only
            let whitespaceResult = formValidator.validateField(type: fieldType, value: "   ")
            XCTAssertFalse(whitespaceResult.isValid, "\(fieldType.stringValue) with whitespace should fail")
            
            // Nil value
            let nilResult = formValidator.validateField(type: fieldType, value: nil)
            XCTAssertFalse(nilResult.isValid, "\(fieldType.stringValue) with nil value should fail")
        }
    }
    
    func testValidateField_AddressLine2Optional() {
        // Address line 2 is typically optional, but let's test it
        let validResult = formValidator.validateField(type: .addressLine2, value: "Apt 4B")
        XCTAssertTrue(validResult.isValid, "Address line 2 with value should pass")
        
        let emptyResult = formValidator.validateField(type: .addressLine2, value: "")
        XCTAssertFalse(emptyResult.isValid, "Empty address line 2 should fail in this implementation")
    }
    
    // MARK: - Context Update Tests
    
    func testUpdateContext_CardNetwork() {
        // Initial state should be unknown
        let initialResult = formValidator.validateField(type: .cvv, value: "123")
        // This should pass for standard 3-digit CVV
        
        // Update to Amex
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.amex)
        
        // Now 3-digit CVV should fail for Amex (which expects 4 digits)
        let amexResult = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertFalse(amexResult.isValid, "3-digit CVV should fail for Amex")
        
        // 4-digit CVV should pass for Amex
        let amexValidResult = formValidator.validateField(type: .cvv, value: "1234")
        XCTAssertTrue(amexValidResult.isValid, "4-digit CVV should pass for Amex")
    }
    
    func testUpdateContext_NonCardNetworkKey() {
        formValidator.updateContext(key: "someOtherKey", value: "someValue")
        
        // CVV validation should still work with default network
        let result = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertTrue(result.isValid, "CVV validation should work with non-card network context")
    }
    
    func testUpdateContext_InvalidCardNetworkValue() {
        formValidator.updateContext(key: "cardNetwork", value: "not a card network")
        
        // Should not crash and should still validate
        let result = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertNotNil(result, "Should handle invalid card network value gracefully")
    }
    
    // MARK: - Error Message Tests
    
    func testErrorMessages_RequiredFields() {
        let expectedMessages: [PrimerInputElementType: String] = [
            .cardNumber: "Card number is required.",
            .expiryDate: "Expiry date is required.",
            .cvv: "CVV is required.",
            .cardholderName: "Cardholder name is required.",
            .firstName: "First name is required.",
            .lastName: "Last name is required.",
            .addressLine1: "Address line 1 is required.",
            .city: "City is required.",
            .state: "State is required.",
            .postalCode: "Postal code is required.",
            .countryCode: "Country is required."
        ]
        
        for (fieldType, expectedMessage) in expectedMessages {
            let result = formValidator.validateField(type: fieldType, value: nil)
            XCTAssertEqual(result.errorMessage, expectedMessage, "Error message for \(fieldType.stringValue) should match")
        }
    }
    
    func testErrorMessages_UnknownField() {
        // Test with a field type that doesn't have a specific message
        let result = formValidator.validateField(type: .phoneNumber, value: nil)
        XCTAssertEqual(result.errorMessage, "This field is required.", "Unknown field should get default message")
    }
    
    // MARK: - Integration Tests
    
    func testIntegration_CompleteCardForm() {
        // Simulate complete card form validation
        let cardFields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe"
        ]
        
        // Update context with detected card network
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        
        let results = formValidator.validateForm(fields: cardFields)
        let hasErrors = results.values.contains { $0 != nil }
        
        XCTAssertFalse(hasErrors, "Complete valid card form should have no errors")
    }
    
    func testIntegration_CompleteFormWithBilling() {
        // Simulate complete form with card and billing
        let allFields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe",
            .firstName: "John",
            .lastName: "Doe",
            .addressLine1: "123 Main St",
            .addressLine2: "Apt 4B",
            .city: "New York",
            .state: "NY",
            .postalCode: "10001",
            .countryCode: "US"
        ]
        
        let results = formValidator.validateForm(fields: allFields)
        let hasErrors = results.values.contains { $0 != nil }
        
        XCTAssertFalse(hasErrors, "Complete valid form should have no errors")
    }
    
    func testIntegration_AmexCardValidation() {
        // Test Amex card with 4-digit CVV
        let amexFields: [PrimerInputElementType: String?] = [
            .cardNumber: "378282246310005", // Valid Amex number
            .expiryDate: "12/30",
            .cvv: "1234", // 4-digit CVV for Amex
            .cardholderName: "John Doe"
        ]
        
        // Update context with Amex network
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.amex)
        
        let results = formValidator.validateForm(fields: amexFields)
        let hasErrors = results.values.contains { $0 != nil }
        
        XCTAssertFalse(hasErrors, "Valid Amex form should have no errors")
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases_WhitespaceHandling() {
        // Test fields with only whitespace
        let whitespaceFields: [PrimerInputElementType: String?] = [
            .cardNumber: "   ",
            .cardholderName: "\t\n",
            .firstName: "  "
        ]
        
        let results = formValidator.validateForm(fields: whitespaceFields)
        
        for (fieldType, error) in results {
            XCTAssertNotNil(error, "\(fieldType.stringValue) with whitespace should have error")
        }
    }
    
    func testEdgeCases_MixedValidInvalid() {
        let mixedFields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111", // Valid
            .expiryDate: "invalid", // Invalid
            .cvv: "123", // Valid
            .cardholderName: "", // Invalid
            .firstName: "John" // Valid
        ]
        
        let results = formValidator.validateForm(fields: mixedFields)
        
        XCTAssertNil(results[.cardNumber], "Valid card number should have no error")
        XCTAssertNotNil(results[.expiryDate], "Invalid expiry should have error")
        XCTAssertNil(results[.cvv], "Valid CVV should have no error")
        XCTAssertNotNil(results[.cardholderName], "Empty cardholder name should have error")
        XCTAssertNil(results[.firstName], "Valid first name should have no error")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_FormValidation() {
        let fields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe",
            .firstName: "John",
            .lastName: "Doe",
            .addressLine1: "123 Main St",
            .city: "New York",
            .postalCode: "10001"
        ]
        
        measure {
            for _ in 0..<100 {
                _ = formValidator.validateForm(fields: fields)
            }
        }
    }
    
    func testPerformance_FieldValidation() {
        measure {
            for _ in 0..<1000 {
                _ = formValidator.validateField(type: .cardNumber, value: "4111111111111111")
                _ = formValidator.validateField(type: .cvv, value: "123")
                _ = formValidator.validateField(type: .expiryDate, value: "12/30")
            }
        }
    }
    
    // MARK: - Real-world Scenarios
    
    func testRealWorldScenario_FieldByFieldValidation() {
        // Simulate user filling form field by field
        
        // 1. User enters card number
        let cardResult = formValidator.validateField(type: .cardNumber, value: "4111111111111111")
        XCTAssertTrue(cardResult.isValid, "Valid card number should pass")
        
        // 2. Update context with detected network
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        
        // 3. User enters CVV
        let cvvResult = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertTrue(cvvResult.isValid, "Valid CVV for Visa should pass")
        
        // 4. User enters expiry
        let expiryResult = formValidator.validateField(type: .expiryDate, value: "12/30")
        XCTAssertTrue(expiryResult.isValid, "Valid expiry should pass")
        
        // 5. User enters name
        let nameResult = formValidator.validateField(type: .cardholderName, value: "John Doe")
        XCTAssertTrue(nameResult.isValid, "Valid name should pass")
        
        // 6. Final form validation
        let allFields: [PrimerInputElementType: String?] = [
            .cardNumber: "4111111111111111",
            .expiryDate: "12/30",
            .cvv: "123",
            .cardholderName: "John Doe"
        ]
        
        let finalResults = formValidator.validateForm(fields: allFields)
        let hasErrors = finalResults.values.contains { $0 != nil }
        XCTAssertFalse(hasErrors, "Complete form should be valid")
    }
    
    func testRealWorldScenario_NetworkChange() {
        // User starts with Visa card
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.visa)
        
        let visaCVVResult = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertTrue(visaCVVResult.isValid, "3-digit CVV should be valid for Visa")
        
        // User changes to Amex card
        formValidator.updateContext(key: "cardNetwork", value: CardNetwork.amex)
        
        let amexCVVResult = formValidator.validateField(type: .cvv, value: "123")
        XCTAssertFalse(amexCVVResult.isValid, "3-digit CVV should be invalid for Amex")
        
        let amexValidCVVResult = formValidator.validateField(type: .cvv, value: "1234")
        XCTAssertTrue(amexValidCVVResult.isValid, "4-digit CVV should be valid for Amex")
    }
}
