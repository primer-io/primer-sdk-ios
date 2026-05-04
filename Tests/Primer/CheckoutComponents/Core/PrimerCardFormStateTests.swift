//
//  PrimerCardFormStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class PrimerCardFormStateTests: XCTestCase {

    // MARK: - CardFormConfiguration Tests

    func test_defaultConfiguration_hasStandardCardFields() {
        // Given
        let config = CardFormConfiguration.default

        // Then
        XCTAssertTrue(config.cardFields.contains(.cardNumber))
        XCTAssertTrue(config.cardFields.contains(.expiryDate))
        XCTAssertTrue(config.cardFields.contains(.cvv))
        XCTAssertTrue(config.cardFields.contains(.cardholderName))
        XCTAssertTrue(config.billingFields.isEmpty)
        XCTAssertFalse(config.requiresBillingAddress)
    }

    func test_configuration_allFields_combinesCardAndBilling() {
        // Given
        let config = CardFormConfiguration(
            cardFields: [.cardNumber, .cvv],
            billingFields: [.firstName, .lastName],
            requiresBillingAddress: true
        )

        // When
        let allFields = config.allFields

        // Then
        XCTAssertEqual(allFields.count, 4)
        XCTAssertEqual(allFields[0], .cardNumber)
        XCTAssertEqual(allFields[1], .cvv)
        XCTAssertEqual(allFields[2], .firstName)
        XCTAssertEqual(allFields[3], .lastName)
    }

    func test_configuration_equality() {
        let config1 = CardFormConfiguration(cardFields: [.cardNumber], billingFields: [.email])
        let config2 = CardFormConfiguration(cardFields: [.cardNumber], billingFields: [.email])
        let config3 = CardFormConfiguration(cardFields: [.cvv])

        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }

    // MARK: - FieldError Tests

    func test_fieldError_equality_sameFieldAndMessage_areEqual() {
        let error1 = FieldError(fieldType: .cardNumber, message: "Invalid", errorCode: "E001")
        let error2 = FieldError(fieldType: .cardNumber, message: "Invalid", errorCode: "E001")

        XCTAssertEqual(error1, error2)
    }

    func test_fieldError_equality_differentField_areNotEqual() {
        let error1 = FieldError(fieldType: .cardNumber, message: "Invalid")
        let error2 = FieldError(fieldType: .cvv, message: "Invalid")

        XCTAssertNotEqual(error1, error2)
    }

    func test_fieldError_equality_differentMessage_areNotEqual() {
        let error1 = FieldError(fieldType: .cardNumber, message: "Invalid")
        let error2 = FieldError(fieldType: .cardNumber, message: "Required")

        XCTAssertNotEqual(error1, error2)
    }

    func test_fieldError_identifiable_hasDeterministicId() {
        let error1 = FieldError(fieldType: .cardNumber, message: "Invalid")
        let error2 = FieldError(fieldType: .cardNumber, message: "Different message")
        let error3 = FieldError(fieldType: .expiryDate, message: "Invalid")

        XCTAssertEqual(error1.id, error2.id)
        XCTAssertNotEqual(error1.id, error3.id)
    }

    // MARK: - FormData Tests

    func test_formData_subscript_getAndSet() {
        // Given
        var formData = FormData()

        // When
        formData[.cardNumber] = "4111111111111111"

        // Then
        XCTAssertEqual(formData[.cardNumber], "4111111111111111")
    }

    func test_formData_subscript_defaultsToEmptyString() {
        let formData = FormData()
        XCTAssertEqual(formData[.cardNumber], "")
    }

    func test_formData_initWithDictionary() {
        // Given
        let data: [PrimerInputElementType: String] = [
            .cardNumber: "4111",
            .cvv: "123",
        ]

        // When
        let formData = FormData(data)

        // Then
        XCTAssertEqual(formData[.cardNumber], "4111")
        XCTAssertEqual(formData[.cvv], "123")
        XCTAssertEqual(formData.dictionary.count, 2)
    }

    func test_formData_equality() {
        let data1 = FormData([.cardNumber: "4111"])
        let data2 = FormData([.cardNumber: "4111"])
        let data3 = FormData([.cardNumber: "5111"])

        XCTAssertEqual(data1, data2)
        XCTAssertNotEqual(data1, data3)
    }

    // MARK: - PrimerCountry Tests

    func test_country_equality_sameData_areEqual() {
        let country1 = PrimerCountry(code: "US", name: "United States", flag: "🇺🇸", dialCode: "+1")
        let country2 = PrimerCountry(code: "US", name: "United States", flag: "🇺🇸", dialCode: "+1")

        XCTAssertEqual(country1, country2)
    }

    func test_country_equality_differentCode_areNotEqual() {
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "GB", name: "United Kingdom")

        XCTAssertNotEqual(country1, country2)
    }

    func test_country_identifiable_hasDeterministicId() {
        let country1 = PrimerCountry(code: "US", name: "United States")
        let country2 = PrimerCountry(code: "US", name: "USA")
        let country3 = PrimerCountry(code: "GB", name: "United Kingdom")

        XCTAssertEqual(country1.id, country2.id)
        XCTAssertNotEqual(country1.id, country3.id)
    }

    // MARK: - PrimerCardFormState Tests

    func test_state_defaultInit_hasExpectedDefaults() {
        let state = PrimerCardFormState()

        XCTAssertEqual(state.configuration, .default)
        XCTAssertTrue(state.fieldErrors.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isValid)
        XCTAssertNil(state.selectedCountry)
        XCTAssertNil(state.selectedNetwork)
        XCTAssertTrue(state.availableNetworks.isEmpty)
        XCTAssertNil(state.surchargeAmountRaw)
        XCTAssertNil(state.surchargeAmount)
        XCTAssertNil(state.binData)
    }

    func test_state_displayFields_matchesConfiguration() {
        let config = CardFormConfiguration(
            cardFields: [.cardNumber, .cvv],
            billingFields: [.email]
        )
        let state = PrimerCardFormState(configuration: config)

        XCTAssertEqual(state.displayFields.count, 3)
    }

    func test_state_hasError_returnsTrueForExistingError() {
        let state = PrimerCardFormState(
            fieldErrors: [FieldError(fieldType: .cardNumber, message: "Invalid")]
        )

        XCTAssertTrue(state.hasError(for: .cardNumber))
        XCTAssertFalse(state.hasError(for: .cvv))
    }

    func test_state_errorMessage_returnsMessageForField() {
        let state = PrimerCardFormState(
            fieldErrors: [FieldError(fieldType: .cardNumber, message: "Card number is invalid")]
        )

        XCTAssertEqual(state.errorMessage(for: .cardNumber), "Card number is invalid")
        XCTAssertNil(state.errorMessage(for: .cvv))
    }

    func test_state_setError_addsNewError() {
        // Given
        var state = PrimerCardFormState()

        // When
        state.setError("Required", for: .cardNumber, errorCode: "E001")

        // Then
        XCTAssertEqual(state.fieldErrors.count, 1)
        XCTAssertEqual(state.fieldErrors.first?.fieldType, .cardNumber)
        XCTAssertEqual(state.fieldErrors.first?.message, "Required")
        XCTAssertEqual(state.fieldErrors.first?.errorCode, "E001")
    }

    func test_state_setError_replacesExistingErrorForSameField() {
        // Given
        var state = PrimerCardFormState(
            fieldErrors: [FieldError(fieldType: .cardNumber, message: "Old error")]
        )

        // When
        state.setError("New error", for: .cardNumber)

        // Then
        XCTAssertEqual(state.fieldErrors.count, 1)
        XCTAssertEqual(state.errorMessage(for: .cardNumber), "New error")
    }

    func test_state_clearError_removesErrorForField() {
        // Given
        var state = PrimerCardFormState(
            fieldErrors: [
                FieldError(fieldType: .cardNumber, message: "Invalid"),
                FieldError(fieldType: .cvv, message: "Required"),
            ]
        )

        // When
        state.clearError(for: .cardNumber)

        // Then
        XCTAssertEqual(state.fieldErrors.count, 1)
        XCTAssertFalse(state.hasError(for: .cardNumber))
        XCTAssertTrue(state.hasError(for: .cvv))
    }

    func test_state_clearError_noOpForNonExistentField() {
        // Given
        var state = PrimerCardFormState()

        // When
        state.clearError(for: .cardNumber)

        // Then
        XCTAssertTrue(state.fieldErrors.isEmpty)
    }
}
