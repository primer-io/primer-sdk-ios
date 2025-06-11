//
//  ExpiryDateValidatorTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ExpiryDateValidatorTests: XCTestCase {
    
    var validator: ExpiryDateValidator!
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
        validator = ExpiryDateValidator(validationService: validationService)
    }
    
    override func tearDown() async throws {
        validator = nil
        validationService = nil
        
        // Clean up global container
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        try await super.tearDown()
    }
    
    // MARK: - ExpiryDateInput Tests
    
    func testExpiryDateInput_ValidFormattedDate() {
        let input = ExpiryDateInput(formattedDate: "12/25")
        XCTAssertNotNil(input)
        XCTAssertEqual(input?.month, "12")
        XCTAssertEqual(input?.year, "25")
    }
    
    func testExpiryDateInput_InvalidFormattedDate() {
        XCTAssertNil(ExpiryDateInput(formattedDate: "1225"))
        XCTAssertNil(ExpiryDateInput(formattedDate: "12/25/30"))
        XCTAssertNil(ExpiryDateInput(formattedDate: ""))
        XCTAssertNil(ExpiryDateInput(formattedDate: "12"))
    }
    
    func testExpiryDateInput_DirectInit() {
        let input = ExpiryDateInput(month: "12", year: "25")
        XCTAssertEqual(input.month, "12")
        XCTAssertEqual(input.year, "25")
    }
    
    // MARK: - Validate While Typing Tests
    
    func testValidateWhileTyping_EmptyInput() {
        let result = validator.validateWhileTyping("")
        XCTAssertTrue(result.isValid, "Empty input should not show errors while typing")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateWhileTyping_PartialInput() {
        let result = validator.validateWhileTyping("1")
        XCTAssertTrue(result.isValid, "Partial input should not show errors while typing")
        
        let result2 = validator.validateWhileTyping("12")
        XCTAssertTrue(result2.isValid, "Partial input should not show errors while typing")
        
        let result3 = validator.validateWhileTyping("12/")
        XCTAssertTrue(result3.isValid, "Partial input should not show errors while typing")
        
        let result4 = validator.validateWhileTyping("12/2")
        XCTAssertTrue(result4.isValid, "Partial input should not show errors while typing")
    }
    
    func testValidateWhileTyping_ValidFutureDate() {
        // Calculate future date
        let currentDate = Date()
        let calendar = Calendar.current
        var futureComponents = calendar.dateComponents([.year, .month], from: currentDate)
        futureComponents.year = futureComponents.year! + 1
        
        let futureYear = (futureComponents.year! % 100)
        let futureMonth = futureComponents.month!
        
        let input = String(format: "%02d/%02d", futureMonth, futureYear)
        let result = validator.validateWhileTyping(input)
        
        XCTAssertTrue(result.isValid, "Valid future date should pass while typing")
    }
    
    func testValidateWhileTyping_ExpiredDate() {
        // Use a clearly expired date
        let result = validator.validateWhileTyping("12/20") // December 2020
        XCTAssertFalse(result.isValid, "Expired date should fail while typing")
        XCTAssertEqual(result.errorCode, "expired-date")
        XCTAssertEqual(result.errorMessage, "Card has expired")
    }
    
    func testValidateWhileTyping_InvalidMonth() {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let input = String(format: "13/%02d", currentYear + 1) // Month 13
        
        let result = validator.validateWhileTyping(input)
        XCTAssertTrue(result.isValid, "Invalid month should be valid while typing (lenient)")
    }
    
    func testValidateWhileTyping_CallbacksInvoked() {
        var monthChanges: [String] = []
        var yearChanges: [String] = []
        
        validator.onMonthChange = { month in
            monthChanges.append(month)
        }
        
        validator.onYearChange = { year in
            yearChanges.append(year)
        }
        
        // Test complete date that triggers callbacks
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let input = String(format: "12/%02d", currentYear + 1)
        _ = validator.validateWhileTyping(input)
        
        XCTAssertEqual(monthChanges.count, 1, "Month callback should be invoked")
        XCTAssertEqual(yearChanges.count, 1, "Year callback should be invoked")
        XCTAssertEqual(monthChanges.first, "12")
        XCTAssertEqual(yearChanges.first, String(format: "%02d", currentYear + 1))
    }
    
    // MARK: - Validate On Blur Tests
    
    func testValidateOnBlur_EmptyInput() {
        let result = validator.validateOnBlur("")
        XCTAssertFalse(result.isValid, "Empty input should be invalid on blur")
        XCTAssertEqual(result.errorCode, "invalid-expiry-date")
        XCTAssertEqual(result.errorMessage, "Expiry date is required")
    }
    
    func testValidateOnBlur_InvalidFormat() {
        let invalidFormats = ["1225", "12/25/30", "12", "ab/cd", "12/"]
        
        for format in invalidFormats {
            let result = validator.validateOnBlur(format)
            XCTAssertFalse(result.isValid, "Invalid format '\(format)' should fail on blur")
            XCTAssertEqual(result.errorCode, "invalid-expiry-format")
            XCTAssertEqual(result.errorMessage, "Please enter date as MM/YY")
        }
    }
    
    func testValidateOnBlur_ValidFutureDate() {
        // Calculate future date
        let currentDate = Date()
        let calendar = Calendar.current
        var futureComponents = calendar.dateComponents([.year, .month], from: currentDate)
        futureComponents.year = futureComponents.year! + 2 // Clearly in the future
        
        let futureYear = (futureComponents.year! % 100)
        let futureMonth = futureComponents.month!
        
        let input = String(format: "%02d/%02d", futureMonth, futureYear)
        let result = validator.validateOnBlur(input)
        
        XCTAssertTrue(result.isValid, "Valid future date should pass on blur")
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateOnBlur_ExpiredDate() {
        let result = validator.validateOnBlur("12/20") // December 2020
        XCTAssertFalse(result.isValid, "Expired date should fail on blur")
        XCTAssertNotNil(result.errorCode)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateOnBlur_InvalidMonth() {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let input = String(format: "13/%02d", currentYear + 1) // Month 13
        
        let result = validator.validateOnBlur(input)
        XCTAssertFalse(result.isValid, "Invalid month should fail on blur")
        XCTAssertNotNil(result.errorCode)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateOnBlur_InvalidYear() {
        let result = validator.validateOnBlur("12/ab")
        XCTAssertFalse(result.isValid, "Invalid year should fail on blur")
    }
    
    func testValidateOnBlur_BoundaryMonths() {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        
        // Test month 01
        let jan = String(format: "01/%02d", currentYear + 1)
        let janResult = validator.validateOnBlur(jan)
        XCTAssertTrue(janResult.isValid, "January should be valid")
        
        // Test month 12
        let dec = String(format: "12/%02d", currentYear + 1)
        let decResult = validator.validateOnBlur(dec)
        XCTAssertTrue(decResult.isValid, "December should be valid")
        
        // Test month 00
        let zero = String(format: "00/%02d", currentYear + 1)
        let zeroResult = validator.validateOnBlur(zero)
        XCTAssertFalse(zeroResult.isValid, "Month 00 should be invalid")
    }
    
    // MARK: - Current Date Edge Cases
    
    func testCurrentDateValidation() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate) % 100
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Current month should be valid (edge case)
        let currentInput = String(format: "%02d/%02d", currentMonth, currentYear)
        let currentResult = validator.validateOnBlur(currentInput)
        XCTAssertTrue(currentResult.isValid, "Current month should be valid")
        
        // Previous month should be invalid
        let prevMonth = currentMonth == 1 ? 12 : currentMonth - 1
        let prevYear = currentMonth == 1 ? currentYear - 1 : currentYear
        let prevInput = String(format: "%02d/%02d", prevMonth, prevYear)
        let prevResult = validator.validateOnBlur(prevInput)
        
        if prevYear < currentYear {
            XCTAssertFalse(prevResult.isValid, "Previous year should be invalid")
        } else {
            XCTAssertFalse(prevResult.isValid, "Previous month should be invalid")
        }
    }
    
    // MARK: - Callback Tests
    
    func testCallbacks_ValidationChange() {
        var validationChanges: [Bool] = []
        
        let validator = ExpiryDateValidator(
            validationService: validationService,
            onValidationChange: { isValid in
                validationChanges.append(isValid)
            }
        )
        
        _ = validator.validateWhileTyping("12/25")
        _ = validator.validateWhileTyping("12/20") // Expired
        
        XCTAssertEqual(validationChanges.count, 2, "Should call validation change callback")
        XCTAssertTrue(validationChanges.contains(true), "Should have valid result")
        XCTAssertTrue(validationChanges.contains(false), "Should have invalid result")
    }
    
    func testCallbacks_ErrorMessage() {
        var errorMessages: [String?] = []
        
        let validator = ExpiryDateValidator(
            validationService: validationService,
            onErrorMessageChange: { message in
                errorMessages.append(message)
            }
        )
        
        _ = validator.validateWhileTyping("12/20") // Expired
        _ = validator.validateOnBlur("")
        
        XCTAssertTrue(errorMessages.count >= 1, "Should call error message callback")
        XCTAssertTrue(errorMessages.contains("Card has expired"), "Should provide expired error")
        XCTAssertTrue(errorMessages.contains("Expiry date is required"), "Should provide required error")
    }
    
    func testCallbacks_MonthYear() {
        var monthValues: [String] = []
        var yearValues: [String] = []
        
        let validator = ExpiryDateValidator(
            validationService: validationService,
            onMonthChange: { month in
                monthValues.append(month)
            },
            onYearChange: { year in
                yearValues.append(year)
            }
        )
        
        _ = validator.validateWhileTyping("12/25")
        _ = validator.validateWhileTyping("06/27")
        
        XCTAssertEqual(monthValues, ["12", "06"], "Should track month changes")
        XCTAssertEqual(yearValues, ["25", "27"], "Should track year changes")
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases_WhitespaceInput() {
        let result = validator.validateOnBlur("   ")
        XCTAssertFalse(result.isValid, "Whitespace should be treated as empty")
    }
    
    func testEdgeCases_LeadingZeros() {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let input = String(format: "01/%02d", currentYear + 1)
        
        let result = validator.validateOnBlur(input)
        XCTAssertTrue(result.isValid, "Should accept leading zeros")
    }
    
    func testEdgeCases_SingleDigitMonth() {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let input = String(format: "1/%02d", currentYear + 1)
        
        let result = validator.validateOnBlur(input)
        XCTAssertTrue(result.isValid, "Should accept single digit month")
    }
    
    func testEdgeCases_FourDigitYear() {
        let currentYear = Calendar.current.component(.year, from: Date()) + 1
        let input = String(format: "12/%04d", currentYear)
        
        // This should fail format validation since we expect MM/YY
        let result = validator.validateOnBlur(input)
        XCTAssertFalse(result.isValid, "Four digit year should be invalid format")
    }
    
    func testEdgeCases_ExtraSlashes() {
        let inputs = ["12//25", "12/25/", "/12/25"]
        
        for input in inputs {
            let result = validator.validateOnBlur(input)
            XCTAssertFalse(result.isValid, "Extra slashes should be invalid: \(input)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ValidateWhileTyping() {
        measure {
            for _ in 0..<1000 {
                _ = validator.validateWhileTyping("12/25")
            }
        }
    }
    
    func testPerformance_ValidateOnBlur() {
        measure {
            for _ in 0..<1000 {
                _ = validator.validateOnBlur("12/25")
            }
        }
    }
    
    func testPerformance_CallbackInvocation() {
        var callCount = 0
        
        let validator = ExpiryDateValidator(
            validationService: validationService,
            onValidationChange: { _ in callCount += 1 },
            onMonthChange: { _ in callCount += 1 },
            onYearChange: { _ in callCount += 1 }
        )
        
        measure {
            for _ in 0..<1000 {
                _ = validator.validateWhileTyping("12/25")
            }
        }
    }
    
    // MARK: - Real-world Scenarios
    
    func testRealWorldScenario_ProgressiveTyping() {
        var validationResults: [Bool] = []
        var monthChanges: [String] = []
        var yearChanges: [String] = []
        
        let validator = ExpiryDateValidator(
            validationService: validationService,
            onValidationChange: { isValid in
                validationResults.append(isValid)
            },
            onMonthChange: { month in
                monthChanges.append(month)
            },
            onYearChange: { year in
                yearChanges.append(year)
            }
        )
        
        // Simulate progressive typing
        let inputs = ["1", "12", "12/", "12/2", "12/25"]
        
        for input in inputs {
            _ = validator.validateWhileTyping(input)
        }
        
        // Final validation
        let finalResult = validator.validateOnBlur("12/25")
        
        // Only the complete date should trigger callbacks
        XCTAssertEqual(monthChanges.count, 1, "Should only call month callback for complete date")
        XCTAssertEqual(yearChanges.count, 1, "Should only call year callback for complete date")
        XCTAssertEqual(monthChanges.first, "12")
        XCTAssertEqual(yearChanges.first, "25")
    }
    
    func testRealWorldScenario_ErrorRecovery() {
        // User enters expired date
        let expiredResult = validator.validateOnBlur("12/20")
        XCTAssertFalse(expiredResult.isValid, "Expired date should be invalid")
        
        // User corrects to future date
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let futureInput = String(format: "12/%02d", currentYear + 1)
        let correctedResult = validator.validateOnBlur(futureInput)
        XCTAssertTrue(correctedResult.isValid, "Corrected date should be valid")
    }
    
    func testRealWorldScenario_MonthValidation() {
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let futureYear = currentYear + 1
        
        // Test all valid months
        for month in 1...12 {
            let input = String(format: "%02d/%02d", month, futureYear)
            let result = validator.validateOnBlur(input)
            XCTAssertTrue(result.isValid, "Month \(month) should be valid")
        }
        
        // Test invalid months
        let invalidMonths = [0, 13, 25, 99]
        for month in invalidMonths {
            let input = String(format: "%02d/%02d", month, futureYear)
            let result = validator.validateOnBlur(input)
            XCTAssertFalse(result.isValid, "Month \(month) should be invalid")
        }
    }
}