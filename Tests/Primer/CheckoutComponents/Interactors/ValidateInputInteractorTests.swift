//
//  ValidateInputInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ValidateInputInteractorTests: XCTestCase {

    private var sut: ValidateInputInteractorImpl!
    private var mockValidationService: MockValidationService!

    override func setUp() {
        super.setUp()
        mockValidationService = MockValidationService()
        sut = ValidateInputInteractorImpl(validationService: mockValidationService)
    }

    override func tearDown() {
        sut = nil
        mockValidationService = nil
        super.tearDown()
    }

    // MARK: - Single Field Validation Tests

    func test_validate_callsValidationService() async {
        // Given
        let value = TestData.CardNumbers.validVisa
        let type = PrimerInputElementType.cardNumber

        // When
        _ = await sut.validate(value: value, type: type)

        // Then
        XCTAssertEqual(mockValidationService.validateFieldCallCount, 1)
        XCTAssertEqual(mockValidationService.lastFieldType, type)
        XCTAssertEqual(mockValidationService.lastFieldValue, value)
    }

    func test_validate_withValidInput_returnsValidResult() async {
        // Given
        mockValidationService.stubbedValidationResult = ValidationResult.valid
        let value = TestData.CardNumbers.validVisa
        let type = PrimerInputElementType.cardNumber

        // When
        let result = await sut.validate(value: value, type: type)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validate_withInvalidInput_returnsInvalidResult() async {
        // Given
        mockValidationService.stubbedValidationResult = ValidationResult.invalid(
            code: TestData.ErrorCodes.invalidCard,
            message: TestData.ErrorMessages.invalidCardNumber
        )
        let value = TestData.CardNumbers.tooShort
        let type = PrimerInputElementType.cardNumber

        // When
        let result = await sut.validate(value: value, type: type)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, TestData.ErrorCodes.invalidCard)
        XCTAssertEqual(result.errorMessage, TestData.ErrorMessages.invalidCardNumber)
    }

    func test_validate_differentFieldTypes() async {
        // Given
        let testCases: [(PrimerInputElementType, String)] = [
            (.cardNumber, TestData.CardNumbers.validVisa),
            (.cvv, TestData.CVV.valid3Digit),
            (.cardholderName, TestData.CardholderNames.valid),
            (.firstName, TestData.Names.firstName),
            (.lastName, TestData.Names.lastName),
            (.email, TestData.EmailAddresses.valid),
            (.phoneNumber, TestData.PhoneNumbers.validUS),
            (.postalCode, TestData.PostalCodes.validUS)
        ]

        for (type, value) in testCases {
            mockValidationService.reset()

            // When
            _ = await sut.validate(value: value, type: type)

            // Then
            XCTAssertEqual(mockValidationService.lastFieldType, type, "Field type mismatch for \(type)")
            XCTAssertEqual(mockValidationService.lastFieldValue, value, "Field value mismatch for \(type)")
        }
    }

    // MARK: - Multiple Fields Validation Tests

    func test_validateMultiple_validatesAllFields() async {
        // Given
        let fields: [PrimerInputElementType: String] = [
            .cardNumber: TestData.CardNumbers.validVisa,
            .cvv: TestData.CVV.valid3Digit,
            .cardholderName: TestData.CardholderNames.valid
        ]

        // When
        let results = await sut.validateMultiple(fields: fields)

        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(mockValidationService.validateFieldCallCount, 3)
    }

    func test_validateMultiple_allValid_returnsAllValidResults() async {
        // Given
        mockValidationService.stubbedValidationResult = ValidationResult.valid
        let fields: [PrimerInputElementType: String] = [
            .cardNumber: TestData.CardNumbers.validVisa,
            .cvv: TestData.CVV.valid3Digit
        ]

        // When
        let results = await sut.validateMultiple(fields: fields)

        // Then
        XCTAssertTrue(results[.cardNumber]?.isValid ?? false)
        XCTAssertTrue(results[.cvv]?.isValid ?? false)
    }

    func test_validateMultiple_withMixedResults_returnsCorrectResults() async {
        // Given
        mockValidationService.stubResult(
            for: .cardNumber,
            result: ValidationResult.valid
        )
        mockValidationService.stubResult(
            for: .cvv,
            result: ValidationResult.invalid(code: TestData.ErrorCodes.invalidCVV, message: TestData.ErrorMessages.invalidCVV)
        )

        let fields: [PrimerInputElementType: String] = [
            .cardNumber: TestData.CardNumbers.validVisa,
            .cvv: TestData.CVV.tooShort
        ]

        // When
        let results = await sut.validateMultiple(fields: fields)

        // Then
        XCTAssertTrue(results[.cardNumber]?.isValid ?? false)
        XCTAssertFalse(results[.cvv]?.isValid ?? true)
        XCTAssertEqual(results[.cvv]?.errorCode, TestData.ErrorCodes.invalidCVV)
    }

    func test_validateMultiple_withEmptyFields_returnsEmptyResults() async {
        // Given
        let fields: [PrimerInputElementType: String] = [:]

        // When
        let results = await sut.validateMultiple(fields: fields)

        // Then
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(mockValidationService.validateFieldCallCount, 0)
    }

    func test_validateMultiple_preservesFieldKeys() async {
        // Given
        let fields: [PrimerInputElementType: String] = [
            .firstName: TestData.Names.firstName,
            .lastName: TestData.Names.lastName,
            .email: TestData.EmailAddresses.valid
        ]

        // When
        let results = await sut.validateMultiple(fields: fields)

        // Then
        XCTAssertNotNil(results[.firstName])
        XCTAssertNotNil(results[.lastName])
        XCTAssertNotNil(results[.email])
        XCTAssertNil(results[.cardNumber]) // Not in input
    }
}
