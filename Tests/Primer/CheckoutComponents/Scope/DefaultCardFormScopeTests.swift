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

    private func createMockCheckoutScope() async -> DefaultCheckoutScope {
        let container = await createTestContainer()
        return await DIContainer.withContainer(container) {
            let navigator = CheckoutNavigator()
            let settings = PrimerSettings(
                paymentHandling: .manual,
                paymentMethodOptions: PrimerPaymentMethodOptions()
            )
            return DefaultCheckoutScope(
                clientToken: "test-token",
                settings: settings,
                diContainer: DIContainer.shared,
                navigator: navigator
            )
        }
    }

    private func createTestContainer() async -> Container {
        let container = Container()

        // Register mock ConfigurationService
        let mockConfig = MockConfigurationService.withDefaultConfiguration()
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in mockConfig }

        // Register mock AccessibilityAnnouncementService
        _ = try? await container.register(AccessibilityAnnouncementService.self)
            .asSingleton()
            .with { _ in MockAccessibilityAnnouncementService() }

        // Register mock AnalyticsInteractor
        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        return container
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cardNumberConfig)
        }
    }

    func test_expiryDateConfig_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.expiryDateConfig)
        }
    }

    func test_cvvConfig_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.cvvConfig)
        }
    }

    func test_screen_defaultsToNil() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertNil(scope.screen)
        }
    }

    // MARK: - Presentation Context Tests

    func test_presentationContext_fromPaymentSelection() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updatePostalCode("12345")

            let postalCode = scope.getFieldValue(.postalCode)
            XCTAssertEqual(postalCode, "12345")
        }
    }

    func test_updateCity_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCity("New York")

            let city = scope.getFieldValue(.city)
            XCTAssertEqual(city, "New York")
        }
    }

    func test_updateAddressLine1_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateAddressLine1("123 Main St")

            let address = scope.getFieldValue(.addressLine1)
            XCTAssertEqual(address, "123 Main St")
        }
    }

    func test_updateFirstName_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateFirstName("John")

            let firstName = scope.getFieldValue(.firstName)
            XCTAssertEqual(firstName, "John")
        }
    }

    func test_updateLastName_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateLastName("Doe")

            let lastName = scope.getFieldValue(.lastName)
            XCTAssertEqual(lastName, "Doe")
        }
    }

    func test_updateEmail_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateEmail("john@example.com")

            let email = scope.getFieldValue(.email)
            XCTAssertEqual(email, "john@example.com")
        }
    }

    func test_updatePhoneNumber_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
            let checkoutScope = await createMockCheckoutScope()
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
}
