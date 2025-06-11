//
//  ValidationFrameworkTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ValidationFrameworkTests: XCTestCase {
    
    var validationService: DefaultValidationService!
    var rulesFactory: RulesFactory!
    var mockContainer: Container!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up DI container with validation dependencies
        mockContainer = Container()
        
        // Register RulesFactory
        _ = try await mockContainer.register(RulesFactory.self)
            .asSingleton()
            .with { _ in RulesFactory() }
        
        // Register ValidationService
        _ = try await mockContainer.register(ValidationService.self)
            .asSingleton()
            .with { resolver in
                let factory = try await resolver.resolve(RulesFactory.self)
                return DefaultValidationService(rulesFactory: factory)
            }
        
        await DIContainer.setContainer(mockContainer)
        
        // Resolve dependencies for tests
        rulesFactory = try await mockContainer.resolve(RulesFactory.self)
        validationService = try await mockContainer.resolve(ValidationService.self) as? DefaultValidationService
    }
    
    override func tearDown() async throws {
        validationService = nil
        rulesFactory = nil
        mockContainer = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - ValidationService Tests
    
    func testValidateCardNumber_ValidVisa() async throws {
        let result = validationService.validateCardNumber("4111111111111111")
        XCTAssertTrue(result.isValid, "Valid Visa card number should pass validation")
    }
    
    func testValidateCardNumber_ValidMasterCard() async throws {
        let result = validationService.validateCardNumber("5555555555554444")
        XCTAssertTrue(result.isValid, "Valid MasterCard number should pass validation")
    }
    
    func testValidateCardNumber_InvalidLength() async throws {
        let result = validationService.validateCardNumber("411111111111111")
        XCTAssertFalse(result.isValid, "Card number with incorrect length should fail validation")
    }
    
    func testValidateCardNumber_InvalidFormat() async throws {
        let result = validationService.validateCardNumber("4111-1111-1111-1111")
        XCTAssertFalse(result.isValid, "Card number with dashes should fail validation")
    }
    
    func testValidateCardNumber_EmptyString() async throws {
        let result = validationService.validateCardNumber("")
        XCTAssertFalse(result.isValid, "Empty card number should fail validation")
    }
    
    func testValidateExpiry_ValidFutureDate() async throws {
        let result = validationService.validateExpiry(month: "12", year: "30")
        XCTAssertTrue(result.isValid, "Valid future expiry date should pass validation")
    }
    
    func testValidateExpiry_InvalidMonth() async throws {
        let result = validationService.validateExpiry(month: "13", year: "25")
        XCTAssertFalse(result.isValid, "Invalid month should fail validation")
    }
    
    func testValidateExpiry_InvalidYear() async throws {
        let result = validationService.validateExpiry(month: "12", year: "20")
        XCTAssertFalse(result.isValid, "Past year should fail validation")
    }
    
    func testValidateExpiry_EmptyValues() async throws {
        let result = validationService.validateExpiry(month: "", year: "")
        XCTAssertFalse(result.isValid, "Empty expiry values should fail validation")
    }
    
    func testValidateCVV_ValidVisa() async throws {
        let result = validationService.validateCVV("123", cardNetwork: .visa)
        XCTAssertTrue(result.isValid, "Valid 3-digit CVV for Visa should pass validation")
    }
    
    func testValidateCVV_ValidAmex() async throws {
        let result = validationService.validateCVV("1234", cardNetwork: .amex)
        XCTAssertTrue(result.isValid, "Valid 4-digit CVV for Amex should pass validation")
    }
    
    func testValidateCVV_InvalidLengthForVisa() async throws {
        let result = validationService.validateCVV("1234", cardNetwork: .visa)
        XCTAssertFalse(result.isValid, "4-digit CVV for Visa should fail validation")
    }
    
    func testValidateCVV_InvalidLengthForAmex() async throws {
        let result = validationService.validateCVV("123", cardNetwork: .amex)
        XCTAssertFalse(result.isValid, "3-digit CVV for Amex should fail validation")
    }
    
    func testValidateCVV_NonNumeric() async throws {
        let result = validationService.validateCVV("12a", cardNetwork: .visa)
        XCTAssertFalse(result.isValid, "Non-numeric CVV should fail validation")
    }
    
    func testValidateCardholderName_ValidName() async throws {
        let result = validationService.validateCardholderName("John Doe")
        XCTAssertTrue(result.isValid, "Valid cardholder name should pass validation")
    }
    
    func testValidateCardholderName_EmptyName() async throws {
        let result = validationService.validateCardholderName("")
        XCTAssertFalse(result.isValid, "Empty cardholder name should fail validation")
    }
    
    func testValidateCardholderName_WhitespaceOnly() async throws {
        let result = validationService.validateCardholderName("   ")
        XCTAssertFalse(result.isValid, "Whitespace-only cardholder name should fail validation")
    }
    
    // MARK: - Field Type Validation Tests
    
    func testValidateField_CardNumber() async throws {
        let result = validationService.validateField(type: .cardNumber, value: "4111111111111111")
        XCTAssertTrue(result.isValid, "Valid card number field should pass validation")
        
        let nilResult = validationService.validateField(type: .cardNumber, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil card number field should fail validation")
    }
    
    func testValidateField_ExpiryDate() async throws {
        let result = validationService.validateField(type: .expiryDate, value: "12/30")
        XCTAssertTrue(result.isValid, "Valid expiry date field should pass validation")
        
        let nilResult = validationService.validateField(type: .expiryDate, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil expiry date field should fail validation")
    }
    
    func testValidateField_CVV() async throws {
        let result = validationService.validateField(type: .cvv, value: "123")
        XCTAssertTrue(result.isValid, "Valid CVV field should pass validation")
        
        let nilResult = validationService.validateField(type: .cvv, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil CVV field should fail validation")
    }
    
    func testValidateField_CardholderName() async throws {
        let result = validationService.validateField(type: .cardholderName, value: "John Doe")
        XCTAssertTrue(result.isValid, "Valid cardholder name field should pass validation")
        
        let nilResult = validationService.validateField(type: .cardholderName, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil cardholder name field should fail validation")
    }
    
    func testValidateField_PostalCode() async throws {
        let result = validationService.validateField(type: .postalCode, value: "12345")
        XCTAssertTrue(result.isValid, "Valid postal code field should pass validation")
        
        let nilResult = validationService.validateField(type: .postalCode, value: nil)
        XCTAssertFalse(nilResult.isValid, "Nil postal code field should fail validation")
    }
    
    func testValidateField_AddressLine2Optional() async throws {
        let result = validationService.validateField(type: .addressLine2, value: nil)
        XCTAssertTrue(result.isValid, "AddressLine2 should be optional and pass validation when nil")
        
        let withValueResult = validationService.validateField(type: .addressLine2, value: "Apt 2B")
        XCTAssertTrue(withValueResult.isValid, "AddressLine2 with value should pass validation")
    }
    
    func testValidateField_UnknownType() async throws {
        let result = validationService.validateField(type: .unknown, value: "any value")
        XCTAssertFalse(result.isValid, "Unknown field type should fail validation")
    }
    
    // MARK: - Generic Validation Tests
    
    func testGenericValidation_RequiredFieldRule() async throws {
        let rule = RequiredFieldRule(fieldName: "Test Field")
        
        let validResult = validationService.validate(input: "valid input", with: rule)
        XCTAssertTrue(validResult.isValid, "Non-empty input should pass required field validation")
        
        let invalidResult = validationService.validate(input: nil, with: rule)
        XCTAssertFalse(invalidResult.isValid, "Nil input should fail required field validation")
        
        let emptyResult = validationService.validate(input: "", with: rule)
        XCTAssertFalse(emptyResult.isValid, "Empty input should fail required field validation")
    }
    
    func testGenericValidation_LengthRule() async throws {
        let rule = LengthRule(fieldName: "Test Field", minLength: 3, maxLength: 10)
        
        let validResult = validationService.validate(input: "valid", with: rule)
        XCTAssertTrue(validResult.isValid, "Input within length range should pass validation")
        
        let tooShortResult = validationService.validate(input: "ab", with: rule)
        XCTAssertFalse(tooShortResult.isValid, "Input too short should fail validation")
        
        let tooLongResult = validationService.validate(input: "this is way too long", with: rule)
        XCTAssertFalse(tooLongResult.isValid, "Input too long should fail validation")
    }
    
    func testGenericValidation_CharacterSetRule() async throws {
        let numericCharacterSet = CharacterSet(charactersIn: "0123456789")
        let rule = CharacterSetRule(fieldName: "Test Field", allowedCharacterSet: numericCharacterSet)
        
        let validResult = validationService.validate(input: "12345", with: rule)
        XCTAssertTrue(validResult.isValid, "Numeric input should pass numeric character set validation")
        
        let invalidResult = validationService.validate(input: "123a5", with: rule)
        XCTAssertFalse(invalidResult.isValid, "Input with non-numeric characters should fail validation")
    }
    
    // MARK: - Validation Cache Tests
    
    func testValidationCache_SameInputReturnsCachedResult() async throws {
        let cardNumber = "4111111111111111"
        
        // First validation
        let result1 = validationService.validateCardNumber(cardNumber)
        
        // Second validation with same input should use cache
        let result2 = validationService.validateCardNumber(cardNumber)
        
        XCTAssertTrue(result1.isValid)
        XCTAssertTrue(result2.isValid)
        XCTAssertEqual(result1.isValid, result2.isValid, "Cached result should match original result")
    }
    
    func testValidationCache_DifferentInputsNotCached() async throws {
        let validCard = "4111111111111111"
        let invalidCard = "1234567890123456"
        
        let validResult = validationService.validateCardNumber(validCard)
        let invalidResult = validationService.validateCardNumber(invalidCard)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNotEqual(validResult.isValid, invalidResult.isValid, "Different inputs should have different results")
    }
    
    func testValidationCache_ClearCache() async throws {
        // This test verifies that cache clearing functionality exists
        // Note: ValidationResultCache is internal, so we test indirectly
        let cardNumber = "4111111111111111"
        
        // Validate to populate cache
        let result1 = validationService.validateCardNumber(cardNumber)
        XCTAssertTrue(result1.isValid)
        
        // Clear cache (internal operation)
        ValidationResultCache.shared.clearCache()
        
        // Validate again - should work the same way
        let result2 = validationService.validateCardNumber(cardNumber)
        XCTAssertTrue(result2.isValid)
        XCTAssertEqual(result1.isValid, result2.isValid, "Results should be consistent after cache clear")
    }
    
    // MARK: - Service Health Check Tests
    
    func testServiceHealthCheck() async throws {
        let healthReport = validationService.performServiceHealthCheck()
        
        XCTAssertTrue(healthReport.isHealthy, "Validation service should be healthy with proper setup")
        XCTAssertTrue(healthReport.issues.isEmpty, "Healthy service should have no issues")
        
        // Check that health report contains useful information
        XCTAssertFalse(healthReport.summary.isEmpty, "Health report should have a non-empty summary")
    }
    
    func testPerformanceBenchmark() async throws {
        let benchmark = validationService.benchmarkValidationPerformance()
        
        XCTAssertGreaterThan(benchmark.totalIterations, 0, "Benchmark should run iterations")
        XCTAssertFalse(benchmark.averageValidationTimes.isEmpty, "Benchmark should measure validation times")
        XCTAssertFalse(benchmark.summary.isEmpty, "Benchmark should have a summary")
        
        // Verify that common validation operations are benchmarked
        XCTAssertNotNil(benchmark.averageValidationTimes["cardNumber"], "Card number validation should be benchmarked")
        XCTAssertNotNil(benchmark.averageValidationTimes["cvv"], "CVV validation should be benchmarked")
        XCTAssertNotNil(benchmark.averageValidationTimes["expiry"], "Expiry validation should be benchmarked")
    }
    
    // MARK: - Error Handling Tests
    
    func testValidationError_ProperErrorCodes() async throws {
        let invalidCardResult = validationService.validateCardNumber("invalid")
        XCTAssertFalse(invalidCardResult.isValid)
        
        if !invalidCardResult.isValid, let code = invalidCardResult.errorCode {
            XCTAssertFalse(code.isEmpty, "Error code should not be empty")
        } else {
            XCTFail("Invalid result should contain error code and message")
        }
    }
    
    func testValidationError_ProperErrorMessages() async throws {
        let nilCardResult = validationService.validateField(type: .cardNumber, value: nil)
        XCTAssertFalse(nilCardResult.isValid)
        
        if !nilCardResult.isValid, let message = nilCardResult.errorMessage {
            XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            XCTAssertTrue(message.contains("required"), "Error message should indicate field is required")
        } else {
            XCTFail("Invalid result should contain error code and message")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompletePaymentFormValidation() async throws {
        // Test a complete payment form validation scenario
        let cardNumber = "4111111111111111"
        let expiry = "12/30"
        let cvv = "123"
        let cardholderName = "John Doe"
        
        let cardResult = validationService.validateField(type: .cardNumber, value: cardNumber)
        let expiryResult = validationService.validateField(type: .expiryDate, value: expiry)
        let cvvResult = validationService.validateField(type: .cvv, value: cvv)
        let nameResult = validationService.validateField(type: .cardholderName, value: cardholderName)
        
        XCTAssertTrue(cardResult.isValid, "Valid card number should pass")
        XCTAssertTrue(expiryResult.isValid, "Valid expiry should pass")
        XCTAssertTrue(cvvResult.isValid, "Valid CVV should pass")
        XCTAssertTrue(nameResult.isValid, "Valid cardholder name should pass")
        
        // All fields valid means form is ready for submission
        let allFieldsValid = [cardResult, expiryResult, cvvResult, nameResult].allSatisfy { $0.isValid }
        XCTAssertTrue(allFieldsValid, "Complete valid payment form should pass all validations")
    }
    
    func testPaymentFormValidation_IncompleteForm() async throws {
        // Test incomplete form validation
        let cardNumber = "4111111111111111"
        let expiry = "" // Missing expiry
        let cvv = "123"
        let cardholderName = "John Doe"
        
        let cardResult = validationService.validateField(type: .cardNumber, value: cardNumber)
        let expiryResult = validationService.validateField(type: .expiryDate, value: expiry)
        let cvvResult = validationService.validateField(type: .cvv, value: cvv)
        let nameResult = validationService.validateField(type: .cardholderName, value: cardholderName)
        
        XCTAssertTrue(cardResult.isValid, "Valid card number should pass")
        XCTAssertFalse(expiryResult.isValid, "Empty expiry should fail")
        XCTAssertTrue(cvvResult.isValid, "Valid CVV should pass")
        XCTAssertTrue(nameResult.isValid, "Valid cardholder name should pass")
        
        // Form should not be valid if any field fails
        let allFieldsValid = [cardResult, expiryResult, cvvResult, nameResult].allSatisfy { $0.isValid }
        XCTAssertFalse(allFieldsValid, "Incomplete payment form should fail validation")
    }
}