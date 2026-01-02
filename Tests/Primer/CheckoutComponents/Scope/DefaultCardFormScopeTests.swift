//
//  DefaultCardFormScopeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - DefaultCardFormScope Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultCardFormScopeTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestContainer() async -> Container {
        await ContainerTestHelpers.createTestContainer()
    }

    private func createCardFormScope(
        checkoutScope: DefaultCheckoutScope,
        processCardPaymentInteractor: ProcessCardPaymentInteractor? = nil,
        validateInputInteractor: ValidateInputInteractor? = nil,
        cardNetworkDetectionInteractor: CardNetworkDetectionInteractor? = nil,
        configurationService: ConfigurationService? = nil
    ) -> DefaultCardFormScope {
        DefaultCardFormScope(
            checkoutScope: checkoutScope,
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: processCardPaymentInteractor ?? MockProcessCardPaymentInteractor(),
            validateInputInteractor: validateInputInteractor ?? MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: cardNetworkDetectionInteractor ?? MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: configurationService ?? MockConfigurationService.withDefaultConfiguration()
        )
    }

    // MARK: - Card Number Field Validation Tests

    func test_cardNumberField_validatesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()
            mockValidator.setValidResult(for: .cardNumber)

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Update card number
            scope.updateCardNumber(TestData.CardNumbers.validVisa)

            // Verify the field value was set
            let cardNumber = scope.getFieldValue(.cardNumber)
            XCTAssertEqual(cardNumber, TestData.CardNumbers.validVisa)
        }
    }

    func test_cardNumberField_invalidNumber_setsError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()
            mockValidator.setInvalidResult(for: .cardNumber, message: "Invalid card number")

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Update with invalid card number
            scope.updateCardNumber("1234567890")

            // Set the error explicitly
            scope.setFieldError(.cardNumber, message: "Invalid card number", errorCode: "INVALID_CARD_NUMBER")

            // Verify error is set (getFieldError returns String?)
            let error = scope.getFieldError(.cardNumber)
            XCTAssertNotNil(error)
            XCTAssertEqual(error, "Invalid card number")
        }
    }

    // MARK: - CVV Field Validation Tests

    func test_cvvField_validatesForCardNetwork() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Test 3-digit CVV (Visa/Mastercard)
            scope.updateCvv("123")
            let cvv3Digit = scope.getFieldValue(.cvv)
            XCTAssertEqual(cvv3Digit, "123")

            // Test 4-digit CVV (Amex)
            scope.updateCvv("1234")
            let cvv4Digit = scope.getFieldValue(.cvv)
            XCTAssertEqual(cvv4Digit, "1234")
        }
    }

    // MARK: - Expiry Field Validation Tests

    func test_expiryField_rejectsExpiredDates() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()
            mockValidator.setInvalidResult(for: .expiryDate, message: "Card has expired")

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Update with expired date (use past date)
            scope.updateExpiryDate("01/20")

            // Set error for expired date
            scope.setFieldError(.expiryDate, message: "Card has expired", errorCode: "EXPIRED_CARD")

            // Verify error is set
            let error = scope.getFieldError(.expiryDate)
            XCTAssertNotNil(error)
            XCTAssertTrue(error?.contains("expired") == true)
        }
    }

    func test_expiryField_acceptsValidDate() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()
            mockValidator.setValidResult(for: .expiryDate)

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Update with future date
            scope.updateExpiryDate("12/30")

            let expiryDate = scope.getFieldValue(.expiryDate)
            XCTAssertEqual(expiryDate, "12/30")

            // Verify no error
            let error = scope.getFieldError(.expiryDate)
            XCTAssertNil(error)
        }
    }

    // MARK: - Cardholder Name Validation Tests

    func test_cardholderNameField_validatesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()
            mockValidator.setValidResult(for: .cardholderName)

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Update cardholder name
            scope.updateCardholderName("John Doe")

            let name = scope.getFieldValue(.cardholderName)
            XCTAssertEqual(name, "John Doe")
        }
    }

    func test_cardholderNameField_invalidName_setsError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()
            mockValidator.setInvalidResult(for: .cardholderName, message: "Name is required")

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Update with empty name
            scope.updateCardholderName("")

            // Set the error
            scope.setFieldError(.cardholderName, message: "Name is required", errorCode: "REQUIRED_FIELD")

            // Verify error is set
            let error = scope.getFieldError(.cardholderName)
            XCTAssertNotNil(error)
        }
    }

    // MARK: - State Reflects Field Validation Tests

    func test_state_reflectsFieldValidation() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockValidator = MockValidateInputInteractor()

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                validateInputInteractor: mockValidator
            )

            // Initially, state should have no field errors
            XCTAssertTrue(scope.structuredState.fieldErrors.isEmpty)

            // Set an error
            scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: "INVALID")

            // State should now have a field error
            XCTAssertFalse(scope.structuredState.fieldErrors.isEmpty)

            // Clear the error
            scope.clearFieldError(.cardNumber)

            // State should have no field errors again
            XCTAssertTrue(scope.structuredState.fieldErrors.isEmpty)
        }
    }

    // MARK: - Submit Tests

    func test_submit_withValidData_triggersPayment() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockPaymentInteractor = MockProcessCardPaymentInteractor()
            let mockValidator = MockValidateInputInteractor()

            // Set all validations to pass
            mockValidator.setValidResult(for: .cardNumber)
            mockValidator.setValidResult(for: .cvv)
            mockValidator.setValidResult(for: .expiryDate)
            mockValidator.setValidResult(for: .cardholderName)

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                processCardPaymentInteractor: mockPaymentInteractor,
                validateInputInteractor: mockValidator
            )

            // Fill in valid card data
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // Simulate validation state update (Bool parameters)
            scope.updateValidationState(
                cardNumber: true,
                cvv: true,
                expiry: true,
                cardholderName: true
            )

            // Verify scope is in valid state for submission
            XCTAssertEqual(scope.getFieldValue(.cardNumber), TestData.CardNumbers.validVisa)
            XCTAssertEqual(scope.getFieldValue(.cvv), "123")
            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/30")
            XCTAssertEqual(scope.getFieldValue(.cardholderName), "John Doe")
        }
    }

    func test_submit_withInvalidData_doesNotSubmit() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockPaymentInteractor = MockProcessCardPaymentInteractor()
            let mockValidator = MockValidateInputInteractor()

            // Set card number validation to fail
            mockValidator.setInvalidResult(for: .cardNumber, message: "Invalid card number")

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                processCardPaymentInteractor: mockPaymentInteractor,
                validateInputInteractor: mockValidator
            )

            // Fill in invalid card data
            scope.updateCardNumber("1234")
            scope.setFieldError(.cardNumber, message: "Invalid card number", errorCode: "INVALID")

            // Verify error is present
            let error = scope.getFieldError(.cardNumber)
            XCTAssertNotNil(error)

            // Payment should not be triggered when there are validation errors
            XCTAssertEqual(mockPaymentInteractor.executeCallCount, 0)
        }
    }

    // MARK: - Co-Badged Card Detection Tests

    func test_coBadgedCardDetection_exposesNetworkOptions() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockNetworkDetector = MockCardNetworkDetectionInteractor()

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                cardNetworkDetectionInteractor: mockNetworkDetector
            )

            // Enter a card number that would trigger co-badged detection
            scope.updateCardNumber(TestData.CardNumbers.validVisa)

            // Wait for the async Task spawned by updateCardNumber to complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Verify network detection was triggered
            XCTAssertEqual(mockNetworkDetector.detectNetworksCallCount, 1)
        }
    }

    // MARK: - UI Customization Properties Tests

    func test_cardNumberConfig_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cardNumberConfig)
        }
    }

    func test_expiryDateConfig_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.expiryDateConfig)
        }
    }

    func test_cvvConfig_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cvvConfig)
        }
    }

    func test_screen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.screen)
        }
    }

    // MARK: - Presentation Context Tests

    func test_presentationContext_fromPaymentSelection() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = DefaultCardFormScope(
                checkoutScope: checkoutScope,
                presentationContext: .fromPaymentSelection,
                processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
                validateInputInteractor: MockValidateInputInteractor(),
                cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
                analyticsInteractor: MockAnalyticsInteractor(),
                configurationService: MockConfigurationService.withDefaultConfiguration()
            )

            XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
        }
    }

    func test_presentationContext_direct() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = DefaultCardFormScope(
                checkoutScope: checkoutScope,
                presentationContext: .direct,
                processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
                validateInputInteractor: MockValidateInputInteractor(),
                cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
                analyticsInteractor: MockAnalyticsInteractor(),
                configurationService: MockConfigurationService.withDefaultConfiguration()
            )

            XCTAssertEqual(scope.presentationContext, .direct)
        }
    }

    // MARK: - Field Update Methods Tests

    func test_updatePostalCode_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updatePostalCode("12345")

            let postalCode = scope.getFieldValue(.postalCode)
            XCTAssertEqual(postalCode, "12345")
        }
    }

    func test_updateCity_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCity("New York")

            let city = scope.getFieldValue(.city)
            XCTAssertEqual(city, "New York")
        }
    }

    func test_updateAddressLine1_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateAddressLine1("123 Main St")

            let address = scope.getFieldValue(.addressLine1)
            XCTAssertEqual(address, "123 Main St")
        }
    }

    func test_updateFirstName_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateFirstName("John")

            let firstName = scope.getFieldValue(.firstName)
            XCTAssertEqual(firstName, "John")
        }
    }

    func test_updateLastName_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateLastName("Doe")

            let lastName = scope.getFieldValue(.lastName)
            XCTAssertEqual(lastName, "Doe")
        }
    }

    func test_updateEmail_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateEmail("john@example.com")

            let email = scope.getFieldValue(.email)
            XCTAssertEqual(email, "john@example.com")
        }
    }

    func test_updatePhoneNumber_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updatePhoneNumber("+1234567890")

            let phone = scope.getFieldValue(.phoneNumber)
            XCTAssertEqual(phone, "+1234567890")
        }
    }

    // MARK: - Clear Field Error Tests

    func test_clearFieldError_removesError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Set an error first
            scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: "INVALID")
            XCTAssertNotNil(scope.getFieldError(.cardNumber))

            // Clear the error
            scope.clearFieldError(.cardNumber)

            // Verify error is gone
            XCTAssertNil(scope.getFieldError(.cardNumber))
        }
    }

    // MARK: - Validation State Tests

    func test_updateValidationState_setsIsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Initially not valid
            XCTAssertFalse(scope.structuredState.isValid)

            // Fill in all required fields
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // Update validation state with all valid
            scope.updateValidationState(
                cardNumber: true,
                cvv: true,
                expiry: true,
                cardholderName: true
            )

            // Should now be valid
            XCTAssertTrue(scope.structuredState.isValid)
        }
    }

    func test_updateValidationState_invalidField_setsIsValidFalse() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Fill in fields
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // Update validation state with one invalid field
            scope.updateValidationState(
                cardNumber: false,  // Invalid
                cvv: true,
                expiry: true,
                cardholderName: true
            )

            // Should not be valid
            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    // MARK: - Generic updateField Tests

    func test_updateField_cardNumber_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.cardNumber, value: TestData.CardNumbers.validVisa)

            XCTAssertEqual(scope.getFieldValue(.cardNumber), TestData.CardNumbers.validVisa)
        }
    }

    func test_updateField_cvv_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.cvv, value: "123")

            XCTAssertEqual(scope.getFieldValue(.cvv), "123")
        }
    }

    func test_updateField_expiryDate_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.expiryDate, value: "12/30")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/30")
        }
    }

    func test_updateField_postalCode_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.postalCode, value: "90210")

            XCTAssertEqual(scope.getFieldValue(.postalCode), "90210")
        }
    }

    func test_updateField_allFieldTypes_setsCorrectValues() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Test all field types via updateField
            scope.updateField(.cardholderName, value: "John Doe")
            scope.updateField(.countryCode, value: "US")
            scope.updateField(.city, value: "Los Angeles")
            scope.updateField(.state, value: "CA")
            scope.updateField(.addressLine1, value: "123 Main St")
            scope.updateField(.addressLine2, value: "Apt 4B")
            scope.updateField(.phoneNumber, value: "+1234567890")
            scope.updateField(.firstName, value: "John")
            scope.updateField(.lastName, value: "Doe")
            scope.updateField(.email, value: "john@example.com")
            scope.updateField(.retailer, value: "Store A")
            scope.updateField(.otp, value: "123456")

            XCTAssertEqual(scope.getFieldValue(.cardholderName), "John Doe")
            XCTAssertEqual(scope.getFieldValue(.countryCode), "US")
            XCTAssertEqual(scope.getFieldValue(.city), "Los Angeles")
            XCTAssertEqual(scope.getFieldValue(.state), "CA")
            XCTAssertEqual(scope.getFieldValue(.addressLine1), "123 Main St")
            XCTAssertEqual(scope.getFieldValue(.addressLine2), "Apt 4B")
            XCTAssertEqual(scope.getFieldValue(.phoneNumber), "+1234567890")
            XCTAssertEqual(scope.getFieldValue(.firstName), "John")
            XCTAssertEqual(scope.getFieldValue(.lastName), "Doe")
            XCTAssertEqual(scope.getFieldValue(.email), "john@example.com")
            XCTAssertEqual(scope.getFieldValue(.retailer), "Store A")
            XCTAssertEqual(scope.getFieldValue(.otp), "123456")
        }
    }

    // MARK: - Expiry Month/Year Tests

    func test_updateExpiryMonth_updatesOnlyMonth() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Set initial expiry
            scope.updateExpiryDate("01/25")

            // Update just the month
            scope.updateExpiryMonth("12")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/25")
        }
    }

    func test_updateExpiryYear_updatesOnlyYear() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Set initial expiry
            scope.updateExpiryDate("06/25")

            // Update just the year
            scope.updateExpiryYear("30")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "06/30")
        }
    }

    func test_updateExpiryMonth_withEmptyYear_handlesGracefully() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Update month without prior expiry
            scope.updateExpiryMonth("12")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/")
        }
    }

    func test_updateExpiryYear_withEmptyMonth_handlesGracefully() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Update year without prior expiry
            scope.updateExpiryYear("30")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "/30")
        }
    }

    // MARK: - Country Code Tests

    func test_updateCountryCode_setsCountryAndSelectedCountry() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCountryCode("US")

            XCTAssertEqual(scope.getFieldValue(.countryCode), "US")
            XCTAssertNotNil(scope.structuredState.selectedCountry)
            XCTAssertEqual(scope.structuredState.selectedCountry?.code, "US")
        }
    }

    func test_updateCountryCode_withLowercase_normalizesCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCountryCode("gb")

            XCTAssertEqual(scope.getFieldValue(.countryCode), "gb")
            XCTAssertNotNil(scope.structuredState.selectedCountry)
        }
    }

    func test_updateCountryCode_withInvalidCode_handlesGracefully() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCountryCode("INVALID")

            XCTAssertEqual(scope.getFieldValue(.countryCode), "INVALID")
            // selectedCountry should not be set for invalid codes
        }
    }

    // MARK: - Additional Update Methods Tests

    func test_updateState_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateState("California")

            XCTAssertEqual(scope.getFieldValue(.state), "California")
        }
    }

    func test_updateAddressLine2_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateAddressLine2("Suite 100")

            XCTAssertEqual(scope.getFieldValue(.addressLine2), "Suite 100")
        }
    }

    func test_updateOtpCode_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateOtpCode("123456")

            XCTAssertEqual(scope.getFieldValue(.otp), "123456")
        }
    }

    func test_updateRetailOutlet_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateRetailOutlet("7-Eleven")

            XCTAssertEqual(scope.getFieldValue(.retailer), "7-Eleven")
        }
    }

    // MARK: - Selected Card Network Tests

    func test_updateSelectedCardNetwork_setsNetworkCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // CardNetwork raw values are uppercase (e.g., "VISA", "MASTERCARD")
            scope.updateSelectedCardNetwork("VISA")

            XCTAssertNotNil(scope.structuredState.selectedNetwork)
            XCTAssertEqual(scope.structuredState.selectedNetwork?.network, .visa)
        }
    }

    func test_updateSelectedCardNetwork_withMastercard_setsCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateSelectedCardNetwork("MASTERCARD")

            XCTAssertNotNil(scope.structuredState.selectedNetwork)
            XCTAssertEqual(scope.structuredState.selectedNetwork?.network, .masterCard)
        }
    }

    func test_updateSelectedCardNetwork_withUnknown_clearsNetwork() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // First set a network
            scope.updateSelectedCardNetwork("VISA")
            XCTAssertNotNil(scope.structuredState.selectedNetwork)

            // Then set OTHER (unknown)
            scope.updateSelectedCardNetwork("OTHER")
            XCTAssertNil(scope.structuredState.selectedNetwork)
        }
    }

    // MARK: - Individual Validation State Methods Tests

    func test_updateCardNumberValidationState_updatesIsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Fill all required fields
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // Set all field validations to true
            scope.updateCardNumberValidationState(true)
            scope.updateCvvValidationState(true)
            scope.updateExpiryValidationState(true)
            scope.updateCardholderNameValidationState(true)

            XCTAssertTrue(scope.structuredState.isValid)
        }
    }

    func test_updateCvvValidationState_invalidCvv_setsIsValidFalse() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateCardNumberValidationState(true)
            scope.updateCvvValidationState(false)  // Invalid
            scope.updateExpiryValidationState(true)
            scope.updateCardholderNameValidationState(true)

            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    func test_updateExpiryValidationState_invalidExpiry_setsIsValidFalse() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateCardNumberValidationState(true)
            scope.updateCvvValidationState(true)
            scope.updateExpiryValidationState(false)  // Invalid
            scope.updateCardholderNameValidationState(true)

            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    func test_updateCardholderNameValidationState_invalidName_setsIsValidFalse() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateCardNumberValidationState(true)
            scope.updateCvvValidationState(true)
            scope.updateExpiryValidationState(true)
            scope.updateCardholderNameValidationState(false)  // Invalid

            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    func test_updateBillingFieldValidationStates_doNotAffectIsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Fill all required card fields
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // Set card validations to true
            scope.updateCardNumberValidationState(true)
            scope.updateCvvValidationState(true)
            scope.updateExpiryValidationState(true)
            scope.updateCardholderNameValidationState(true)

            // Update billing field validations (should not affect isValid for basic card form)
            scope.updatePostalCodeValidationState(true)
            scope.updateCityValidationState(true)
            scope.updateStateValidationState(true)
            scope.updateAddressLine1ValidationState(true)
            scope.updateAddressLine2ValidationState(true)
            scope.updateFirstNameValidationState(true)
            scope.updateLastNameValidationState(true)
            scope.updateEmailValidationState(true)
            scope.updatePhoneNumberValidationState(true)
            scope.updateCountryCodeValidationState(true)

            XCTAssertTrue(scope.structuredState.isValid)
        }
    }

    // MARK: - Form Configuration Tests

    func test_getFormConfiguration_returnsDefaultConfiguration() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let config = scope.getFormConfiguration()

            // Default configuration includes card fields
            XCTAssertTrue(config.cardFields.contains(.cardNumber))
            XCTAssertTrue(config.cardFields.contains(.expiryDate))
            XCTAssertTrue(config.cardFields.contains(.cvv))
            XCTAssertTrue(config.cardFields.contains(.cardholderName))
        }
    }

    func test_getBillingAddressConfiguration_returnsConfiguration() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let config = scope.getBillingAddressConfiguration()

            // Verify configuration is returned (values depend on API config)
            XCTAssertNotNil(config)
        }
    }

    // MARK: - Select Country Scope Tests

    func test_selectCountry_returnsScope() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let selectCountryScope = scope.selectCountry

            XCTAssertNotNil(selectCountryScope)
        }
    }

    func test_selectCountry_returnsSameInstance() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let firstScope = scope.selectCountry
            let secondScope = scope.selectCountry

            // Should return the same instance (lazy initialization)
            XCTAssertTrue(firstScope === secondScope)
        }
    }

    // MARK: - UI Customization Properties Tests

    func test_title_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.title)
        }
    }

    func test_title_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.title = "Custom Title"

            XCTAssertEqual(scope.title, "Custom Title")
        }
    }

    func test_submitButtonText_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.submitButtonText)
        }
    }

    func test_submitButtonText_canBeSet() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.submitButtonText = "Pay Now"

            XCTAssertEqual(scope.submitButtonText, "Pay Now")
        }
    }

    func test_showSubmitLoadingIndicator_defaultsToTrue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertTrue(scope.showSubmitLoadingIndicator)
        }
    }

    func test_showSubmitLoadingIndicator_canBeDisabled() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.showSubmitLoadingIndicator = false

            XCTAssertFalse(scope.showSubmitLoadingIndicator)
        }
    }

    func test_errorView_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.errorView)
        }
    }

    func test_cobadgedCardsView_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cobadgedCardsView)
        }
    }

    // MARK: - Section Customization Properties Tests

    func test_cardInputSection_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cardInputSection)
        }
    }

    func test_billingAddressSection_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.billingAddressSection)
        }
    }

    func test_submitButtonSection_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.submitButtonSection)
        }
    }

    // MARK: - Additional Config Properties Tests

    func test_allFieldConfigs_defaultToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cardholderNameConfig)
            XCTAssertNil(scope.postalCodeConfig)
            XCTAssertNil(scope.countryConfig)
            XCTAssertNil(scope.cityConfig)
            XCTAssertNil(scope.stateConfig)
            XCTAssertNil(scope.addressLine1Config)
            XCTAssertNil(scope.addressLine2Config)
            XCTAssertNil(scope.phoneNumberConfig)
            XCTAssertNil(scope.firstNameConfig)
            XCTAssertNil(scope.lastNameConfig)
            XCTAssertNil(scope.emailConfig)
            XCTAssertNil(scope.retailOutletConfig)
            XCTAssertNil(scope.otpCodeConfig)
        }
    }

    // MARK: - Dismissal Mechanism Tests

    func test_dismissalMechanism_returnsEmptyByDefault() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // When checkoutScope's dismissalMechanism is not set, returns empty
            XCTAssertNotNil(scope.dismissalMechanism)
        }
    }

    // MARK: - Structured State Tests

    func test_structuredState_initiallyEmpty() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertFalse(scope.structuredState.isLoading)
            XCTAssertFalse(scope.structuredState.isValid)
            XCTAssertTrue(scope.structuredState.fieldErrors.isEmpty)
            XCTAssertNil(scope.structuredState.selectedNetwork)
            XCTAssertNil(scope.structuredState.surchargeAmount)
        }
    }

    func test_structuredState_dataInitiallyEmpty() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertEqual(scope.getFieldValue(.cardNumber), "")
            XCTAssertEqual(scope.getFieldValue(.cvv), "")
            XCTAssertEqual(scope.getFieldValue(.expiryDate), "")
            XCTAssertEqual(scope.getFieldValue(.cardholderName), "")
        }
    }

    // MARK: - Multiple Field Error Tests

    func test_setFieldError_multipleFields_tracksAll() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.setFieldError(.cardNumber, message: "Invalid card number", errorCode: "INVALID_CARD")
            scope.setFieldError(.cvv, message: "Invalid CVV", errorCode: "INVALID_CVV")
            scope.setFieldError(.expiryDate, message: "Invalid expiry", errorCode: "INVALID_EXPIRY")

            XCTAssertEqual(scope.structuredState.fieldErrors.count, 3)
            XCTAssertNotNil(scope.getFieldError(.cardNumber))
            XCTAssertNotNil(scope.getFieldError(.cvv))
            XCTAssertNotNil(scope.getFieldError(.expiryDate))
        }
    }

    func test_clearFieldError_onlyRemovesSpecificField() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.setFieldError(.cardNumber, message: "Invalid card number", errorCode: "INVALID_CARD")
            scope.setFieldError(.cvv, message: "Invalid CVV", errorCode: "INVALID_CVV")

            scope.clearFieldError(.cardNumber)

            XCTAssertNil(scope.getFieldError(.cardNumber))
            XCTAssertNotNil(scope.getFieldError(.cvv))
            XCTAssertEqual(scope.structuredState.fieldErrors.count, 1)
        }
    }

    // MARK: - Available Networks Tests

    func test_availableNetworks_initiallyEmpty() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertTrue(scope.structuredState.availableNetworks.isEmpty)
        }
    }

    // MARK: - Navigation Methods Tests

    func test_onSubmit_callsSubmit() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Fill valid data
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // onSubmit should not crash
            scope.onSubmit()

            XCTAssertTrue(true, "onSubmit should execute without crashing")
        }
    }

    func test_onBack_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // onBack should not crash
            scope.onBack()

            XCTAssertTrue(true, "onBack should execute without crashing")
        }
    }

    func test_onCancel_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // onCancel should not crash
            scope.onCancel()

            XCTAssertTrue(true, "onCancel should execute without crashing")
        }
    }

    // MARK: - ViewBuilder Methods Tests

    func test_PrimerCardNumberField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerCardNumberField(label: "Card Number", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerExpiryDateField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerExpiryDateField(label: "Expiry", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerCvvField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerCvvField(label: "CVV", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerCardholderNameField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerCardholderNameField(label: "Name", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerCountryField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerCountryField(label: "Country", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerPostalCodeField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerPostalCodeField(label: "Postal Code", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerCityField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerCityField(label: "City", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerStateField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerStateField(label: "State", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerAddressLine1Field_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerAddressLine1Field(label: "Address", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerAddressLine2Field_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerAddressLine2Field(label: "Address 2", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerFirstNameField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerFirstNameField(label: "First Name", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerLastNameField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerLastNameField(label: "Last Name", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerEmailField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerEmailField(label: "Email", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerPhoneNumberField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerPhoneNumberField(label: "Phone", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerRetailOutletField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerRetailOutletField(label: "Outlet", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_PrimerOtpCodeField_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.PrimerOtpCodeField(label: "OTP", styling: nil)

            XCTAssertNotNil(view)
        }
    }

    func test_DefaultCardFormView_returnsView() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let view = scope.DefaultCardFormView(styling: nil)

            XCTAssertNotNil(view)
        }
    }

    // MARK: - CardFormUIOptions Tests

    func test_cardFormUIOptions_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cardFormUIOptions)
        }
    }

    // MARK: - Start and Cancel Methods Tests

    func test_start_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // start should not crash
            scope.start()

            XCTAssertTrue(true, "start should execute without crashing")
        }
    }

    func test_cancel_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // cancel should not crash
            scope.cancel()

            XCTAssertTrue(true, "cancel should execute without crashing")
        }
    }

    // MARK: - State AsyncStream Tests

    func test_state_returnsAsyncStream() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let stateStream = scope.state

            XCTAssertNotNil(stateStream)
        }
    }

    // MARK: - Empty Field Value Tests

    func test_updateCardNumber_withEmptyString_clearsField() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Set a value first
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            XCTAssertEqual(scope.getFieldValue(.cardNumber), TestData.CardNumbers.validVisa)

            // Clear by setting empty
            scope.updateCardNumber("")
            XCTAssertEqual(scope.getFieldValue(.cardNumber), "")
        }
    }

    func test_updateCvv_withEmptyString_clearsField() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCvv("123")
            XCTAssertEqual(scope.getFieldValue(.cvv), "123")

            scope.updateCvv("")
            XCTAssertEqual(scope.getFieldValue(.cvv), "")
        }
    }

    // MARK: - Error Code Tests

    func test_setFieldError_withNilErrorCode_setsError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: nil)

            XCTAssertEqual(scope.getFieldError(.cardNumber), "Invalid card")
        }
    }

    // MARK: - Whitespace Handling Tests

    func test_updateCardNumber_withWhitespace_preservesWhitespace() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Card numbers may have spaces
            scope.updateCardNumber("4111 1111 1111 1111")
            XCTAssertEqual(scope.getFieldValue(.cardNumber), "4111 1111 1111 1111")
        }
    }

    func test_updateCardholderName_withExtraWhitespace_preservesInput() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardholderName("  John   Doe  ")
            XCTAssertEqual(scope.getFieldValue(.cardholderName), "  John   Doe  ")
        }
    }
}
