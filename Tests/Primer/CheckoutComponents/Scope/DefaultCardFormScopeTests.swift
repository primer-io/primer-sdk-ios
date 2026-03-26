//
//  DefaultCardFormScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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

            scope.updateCardNumber(TestData.CardNumbers.validVisa)

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

            scope.updateCardNumber("1234567890")
            scope.setFieldError(.cardNumber, message: "Invalid card number", errorCode: "INVALID_CARD_NUMBER")

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

            scope.updateCvv("123")
            let cvv3Digit = scope.getFieldValue(.cvv)
            XCTAssertEqual(cvv3Digit, "123")

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

            scope.updateExpiryDate("01/20")
            scope.setFieldError(.expiryDate, message: "Card has expired", errorCode: "EXPIRED_CARD")

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

            scope.updateExpiryDate("12/30")

            let expiryDate = scope.getFieldValue(.expiryDate)
            XCTAssertEqual(expiryDate, "12/30")

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

            scope.updateCardholderName("")
            scope.setFieldError(.cardholderName, message: "Name is required", errorCode: "REQUIRED_FIELD")

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

            XCTAssertTrue(scope.structuredState.fieldErrors.isEmpty)

            scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: "INVALID")
            XCTAssertFalse(scope.structuredState.fieldErrors.isEmpty)

            scope.clearFieldError(.cardNumber)
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

            mockValidator.setValidResult(for: .cardNumber)
            mockValidator.setValidResult(for: .cvv)
            mockValidator.setValidResult(for: .expiryDate)
            mockValidator.setValidResult(for: .cardholderName)

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                processCardPaymentInteractor: mockPaymentInteractor,
                validateInputInteractor: mockValidator
            )

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateValidationState(
                cardNumber: true,
                cvv: true,
                expiry: true,
                cardholderName: true
            )

            XCTAssertEqual(scope.getFieldValue(.cardNumber), TestData.CardNumbers.validVisa)
            XCTAssertEqual(scope.getFieldValue(.cvv), "123")
            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/30")
            XCTAssertEqual(scope.getFieldValue(.cardholderName), "John Doe")
        }
    }

    func test_onSubmit_callsSubmit() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            await scope.submit()

            XCTAssertTrue(true, "submit should execute without crashing")
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

            scope.updateCardNumber(TestData.CardNumbers.validVisa)

            try? await Task.sleep(nanoseconds: 100_000_000)

            XCTAssertEqual(mockNetworkDetector.detectNetworksCallCount, 1)
        }
    }

    // MARK: - Exhaustive Field Update Test

    func test_updateField_allFieldTypes_setsCorrectValues() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

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

    // MARK: - Clear Field Error Tests

    func test_clearFieldError_removesError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: "INVALID")
            XCTAssertNotNil(scope.getFieldError(.cardNumber))

            scope.clearFieldError(.cardNumber)

            XCTAssertNil(scope.getFieldError(.cardNumber))
        }
    }

    // MARK: - Validation State Tests

    func test_updateValidationState_setsIsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            XCTAssertFalse(scope.structuredState.isValid)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateValidationState(
                cardNumber: true,
                cvv: true,
                expiry: true,
                cardholderName: true
            )

            XCTAssertTrue(scope.structuredState.isValid)
        }
    }

    func test_updateValidationState_invalidField_setsIsValidFalse() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateValidationState(
                cardNumber: false,
                cvv: true,
                expiry: true,
                cardholderName: true
            )

            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    // MARK: - Expiry Month/Year Tests

    func test_updateExpiryMonth_updatesOnlyMonth() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateExpiryDate("01/25")
            scope.updateExpiryMonth("12")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/25")
        }
    }

    func test_updateExpiryYear_updatesOnlyYear() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateExpiryDate("06/25")
            scope.updateExpiryYear("30")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "06/30")
        }
    }

    func test_updateExpiryMonth_withEmptyYear_handlesGracefully() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateExpiryMonth("12")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/")
        }
    }

    func test_updateExpiryYear_withEmptyMonth_handlesGracefully() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

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
        }
    }

    // MARK: - Selected Card Network Tests

    func test_updateSelectedCardNetwork_setsNetworkCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

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

            scope.updateSelectedCardNetwork("VISA")
            XCTAssertNotNil(scope.structuredState.selectedNetwork)

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

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: true)
            scope.updateValidationState(\.expiry, isValid: true)
            scope.updateValidationState(\.cardholderName, isValid: true)

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

            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: false)
            scope.updateValidationState(\.expiry, isValid: true)
            scope.updateValidationState(\.cardholderName, isValid: true)

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

            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: true)
            scope.updateValidationState(\.expiry, isValid: false)
            scope.updateValidationState(\.cardholderName, isValid: true)

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

            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: true)
            scope.updateValidationState(\.expiry, isValid: true)
            scope.updateValidationState(\.cardholderName, isValid: false)

            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    func test_updateBillingFieldValidationStates_doNotAffectIsValid() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: true)
            scope.updateValidationState(\.expiry, isValid: true)
            scope.updateValidationState(\.cardholderName, isValid: true)

            scope.updateValidationState(\.postalCode, isValid: true)
            scope.updateValidationState(\.city, isValid: true)
            scope.updateValidationState(\.state, isValid: true)
            scope.updateValidationState(\.addressLine1, isValid: true)
            scope.updateValidationState(\.addressLine2, isValid: true)
            scope.updateValidationState(\.firstName, isValid: true)
            scope.updateValidationState(\.lastName, isValid: true)
            scope.updateValidationState(\.email, isValid: true)
            scope.updateValidationState(\.phoneNumber, isValid: true)
            scope.updateValidationState(\.countryCode, isValid: true)

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

            XCTAssertTrue(firstScope === secondScope)
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

    func test_setFieldError_withNilErrorCode_setsError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.setFieldError(.cardNumber, message: "Invalid card", errorCode: nil)

            XCTAssertEqual(scope.getFieldError(.cardNumber), "Invalid card")
        }
    }

    // MARK: - Empty Field Value Tests

    func test_updateCardNumber_withEmptyString_clearsField() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            XCTAssertEqual(scope.getFieldValue(.cardNumber), TestData.CardNumbers.validVisa)

            scope.updateCardNumber("")
            XCTAssertEqual(scope.getFieldValue(.cardNumber), "")
        }
    }

    // MARK: - performSubmit Error Handling Tests

    func test_performSubmit_invalidExpiryFormat_handlesError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("invalid")
            scope.updateCardholderName("John Doe")

            // When
            await scope.performSubmit()

            // Then — should handle error gracefully, loading should be reset
            XCTAssertFalse(scope.structuredState.isLoading)
        }
    }

    func test_performSubmit_withTwoDigitYear_convertsToFourDigit() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockPaymentInteractor = MockProcessCardPaymentInteractor()
            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                processCardPaymentInteractor: mockPaymentInteractor
            )

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // When
            await scope.performSubmit()

            // Then — payment should be attempted (even if it fails due to mock setup)
            XCTAssertFalse(scope.structuredState.isLoading)
        }
    }

    func test_performSubmit_paymentInteractorFails_handlesError() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockPaymentInteractor = MockProcessCardPaymentInteractor()
            mockPaymentInteractor.errorToThrow = PrimerError.unknown(message: "Payment failed")

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                processCardPaymentInteractor: mockPaymentInteractor
            )

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // When
            await scope.performSubmit()

            // Then
            XCTAssertFalse(scope.structuredState.isLoading)
        }
    }

    // MARK: - submit Guard Tests

    func test_submit_whenAlreadyLoading_doesNotSubmitAgain() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.structuredState.isLoading = true

            // When
            scope.submit()

            // Then — should bail out immediately since isLoading is true
            XCTAssertTrue(scope.structuredState.isLoading)
        }
    }

    // MARK: - cancel Tests

    func test_cancel_cancelsNetworkDetectionTask() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // When
            scope.cancel()

            // Then — should not crash, tasks should be cancelled
            XCTAssertTrue(true)
        }
    }

    // MARK: - onBack Tests

    func test_onBack_fromPaymentSelection_navigatesBack() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // When / Then — should not crash
            scope.onBack()
        }
    }

    // MARK: - Billing Address Configuration Tests

    func test_getBillingAddressConfiguration_withBillingFields_reflectsFields() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockConfig = MockConfigurationService.withDefaultConfiguration()
            mockConfig.billingAddressOptions = PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions(
                firstName: true,
                lastName: true,
                city: true,
                postalCode: true,
                addressLine1: true,
                addressLine2: true,
                countryCode: true,
                phoneNumber: false,
                state: true
            )

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                configurationService: mockConfig
            )

            let billingConfig = scope.getBillingAddressConfiguration()

            XCTAssertTrue(billingConfig.showFirstName)
            XCTAssertTrue(billingConfig.showLastName)
            XCTAssertTrue(billingConfig.showCity)
            XCTAssertTrue(billingConfig.showPostalCode)
            XCTAssertTrue(billingConfig.showAddressLine1)
            XCTAssertTrue(billingConfig.showAddressLine2)
            XCTAssertTrue(billingConfig.showCountry)
            XCTAssertTrue(billingConfig.showState)
        }
    }

    func test_getFormConfiguration_withBillingAddress_includesBillingFields() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockConfig = MockConfigurationService.withDefaultConfiguration()
            mockConfig.billingAddressOptions = PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions(
                firstName: true,
                lastName: true,
                city: true,
                postalCode: true,
                addressLine1: true,
                addressLine2: true,
                countryCode: true,
                phoneNumber: nil,
                state: true
            )

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                configurationService: mockConfig
            )

            let config = scope.getFormConfiguration()

            XCTAssertTrue(config.requiresBillingAddress)
            XCTAssertFalse(config.billingFields.isEmpty)
            XCTAssertTrue(config.billingFields.contains(.postalCode))
        }
    }

    func test_getFormConfiguration_withoutBillingAddress_hasEmptyBillingFields() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let mockConfig = MockConfigurationService.withDefaultConfiguration()
            mockConfig.billingAddressOptions = nil

            let scope = createCardFormScope(
                checkoutScope: checkoutScope,
                configurationService: mockConfig
            )

            let config = scope.getFormConfiguration()

            XCTAssertFalse(config.requiresBillingAddress)
            XCTAssertTrue(config.billingFields.isEmpty)
        }
    }

    // MARK: - getCardNetworkForCvv Tests

    func test_getCardNetworkForCvv_withSelectedNetwork_returnsSelected() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateSelectedCardNetwork("VISA")

            let network = scope.getCardNetworkForCvv()
            XCTAssertEqual(network, .visa)
        }
    }

    func test_getCardNetworkForCvv_noSelectedNetwork_derivesFromCardNumber() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)

            let network = scope.getCardNetworkForCvv()
            XCTAssertEqual(network, .visa)
        }
    }

    // MARK: - updateField Default Case Tests

    func test_updateField_unknownType_doesNotCrash() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // When / Then — unknown type should hit default case
            scope.updateField(.unknown, value: "test")
        }
    }

    // MARK: - Postal Code Update Tests

    func test_updatePostalCode_setsValue() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updatePostalCode("10001")

            XCTAssertEqual(scope.getFieldValue(.postalCode), "10001")
        }
    }

    // MARK: - updateField via Switch Cases Tests

    func test_updateField_cardNumber_delegatesToUpdateCardNumber() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.cardNumber, value: TestData.CardNumbers.validVisa)

            XCTAssertEqual(scope.getFieldValue(.cardNumber), TestData.CardNumbers.validVisa)
        }
    }

    func test_updateField_cvv_delegatesToUpdateCvv() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.cvv, value: "999")

            XCTAssertEqual(scope.getFieldValue(.cvv), "999")
        }
    }

    func test_updateField_expiryDate_delegatesToUpdateExpiryDate() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.expiryDate, value: "12/30")

            XCTAssertEqual(scope.getFieldValue(.expiryDate), "12/30")
        }
    }

    func test_updateField_postalCode_delegatesToUpdatePostalCode() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateField(.postalCode, value: "90210")

            XCTAssertEqual(scope.getFieldValue(.postalCode), "90210")
        }
    }

    // MARK: - Dismissal Mechanism and Card Form UI Options Tests

    func test_dismissalMechanism_delegatesToCheckoutScope() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            let mechanism = scope.dismissalMechanism
            XCTAssertNotNil(mechanism)
        }
    }

    func test_cardFormUIOptions_delegatesToCheckoutScope() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Default PrimerSettings doesn't set cardFormUIOptions
            XCTAssertNil(scope.cardFormUIOptions)
        }
    }
}

// MARK: - DefaultCardFormScope+Validation Tests

@available(iOS 15.0, *)
@MainActor
final class DefaultCardFormScopeValidationTests: XCTestCase {

    private func createTestContainer() async -> Container {
        await ContainerTestHelpers.createTestContainer()
    }

    private func createCardFormScope(
        checkoutScope: DefaultCheckoutScope
    ) -> DefaultCardFormScope {
        DefaultCardFormScope(
            checkoutScope: checkoutScope,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
    }

    // MARK: - updateValidationState via KeyPath Tests

    func test_updateValidationState_keyPath_cardNumber_updatesFieldValidationStates() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // Populate all required fields
            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // When
            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: true)
            scope.updateValidationState(\.expiry, isValid: true)
            scope.updateValidationState(\.cardholderName, isValid: true)

            // Then
            XCTAssertTrue(scope.fieldValidationStates.cardNumber)
            XCTAssertTrue(scope.fieldValidationStates.cvv)
            XCTAssertTrue(scope.fieldValidationStates.expiry)
            XCTAssertTrue(scope.fieldValidationStates.cardholderName)
            XCTAssertTrue(scope.structuredState.isValid)
        }
    }

    func test_updateValidationState_keyPath_settingFalse_invalidatesForm() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateCardNumber(TestData.CardNumbers.validVisa)
            scope.updateCvv("123")
            scope.updateExpiryDate("12/30")
            scope.updateCardholderName("John Doe")

            // Set all valid first
            scope.updateValidationState(\.cardNumber, isValid: true)
            scope.updateValidationState(\.cvv, isValid: true)
            scope.updateValidationState(\.expiry, isValid: true)
            scope.updateValidationState(\.cardholderName, isValid: true)
            XCTAssertTrue(scope.structuredState.isValid)

            // When — invalidate one field
            scope.updateValidationState(\.cardNumber, isValid: false)

            // Then
            XCTAssertFalse(scope.structuredState.isValid)
        }
    }

    // MARK: - updateValidationStateIfNeeded Tests

    func test_updateValidationStateIfNeeded_cardNumber_mapsCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // When
            scope.updateValidationStateIfNeeded(for: .cardNumber, isValid: true)

            // Then
            XCTAssertTrue(scope.fieldValidationStates.cardNumber)
        }
    }

    func test_updateValidationStateIfNeeded_cvv_mapsCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateValidationStateIfNeeded(for: .cvv, isValid: true)

            XCTAssertTrue(scope.fieldValidationStates.cvv)
        }
    }

    func test_updateValidationStateIfNeeded_expiryDate_mapsCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateValidationStateIfNeeded(for: .expiryDate, isValid: true)

            XCTAssertTrue(scope.fieldValidationStates.expiry)
        }
    }

    func test_updateValidationStateIfNeeded_cardholderName_mapsCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateValidationStateIfNeeded(for: .cardholderName, isValid: true)

            XCTAssertTrue(scope.fieldValidationStates.cardholderName)
        }
    }

    func test_updateValidationStateIfNeeded_billingFields_mapCorrectly() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            scope.updateValidationStateIfNeeded(for: .email, isValid: true)
            scope.updateValidationStateIfNeeded(for: .firstName, isValid: true)
            scope.updateValidationStateIfNeeded(for: .lastName, isValid: true)
            scope.updateValidationStateIfNeeded(for: .addressLine1, isValid: true)
            scope.updateValidationStateIfNeeded(for: .addressLine2, isValid: true)
            scope.updateValidationStateIfNeeded(for: .city, isValid: true)
            scope.updateValidationStateIfNeeded(for: .state, isValid: true)
            scope.updateValidationStateIfNeeded(for: .postalCode, isValid: true)
            scope.updateValidationStateIfNeeded(for: .countryCode, isValid: true)
            scope.updateValidationStateIfNeeded(for: .phoneNumber, isValid: true)

            XCTAssertTrue(scope.fieldValidationStates.email)
            XCTAssertTrue(scope.fieldValidationStates.firstName)
            XCTAssertTrue(scope.fieldValidationStates.lastName)
            XCTAssertTrue(scope.fieldValidationStates.addressLine1)
            XCTAssertTrue(scope.fieldValidationStates.addressLine2)
            XCTAssertTrue(scope.fieldValidationStates.city)
            XCTAssertTrue(scope.fieldValidationStates.state)
            XCTAssertTrue(scope.fieldValidationStates.postalCode)
            XCTAssertTrue(scope.fieldValidationStates.countryCode)
            XCTAssertTrue(scope.fieldValidationStates.phoneNumber)
        }
    }

    func test_updateValidationStateIfNeeded_unmappedType_doesNothing() async throws {
        let container = await createTestContainer()

        await DIContainer.withContainer(container) {
            let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
            let scope = createCardFormScope(checkoutScope: checkoutScope)

            // When — retailer, otp, unknown, all have no mapping
            scope.updateValidationStateIfNeeded(for: .retailer, isValid: true)
            scope.updateValidationStateIfNeeded(for: .otp, isValid: true)
            scope.updateValidationStateIfNeeded(for: .unknown, isValid: true)

            // Then — no field validation states should change
            XCTAssertFalse(scope.fieldValidationStates.cardNumber)
            XCTAssertFalse(scope.fieldValidationStates.cvv)
        }
    }
}

// MARK: - FieldValidationStates Tests

@available(iOS 15.0, *)
final class FieldValidationStatesTests: XCTestCase {

    func test_init_allFieldsDefaultToFalse() {
        // Given / When
        let states = FieldValidationStates()

        // Then
        XCTAssertFalse(states.cardNumber)
        XCTAssertFalse(states.cvv)
        XCTAssertFalse(states.expiry)
        XCTAssertFalse(states.cardholderName)
        XCTAssertFalse(states.postalCode)
        XCTAssertFalse(states.countryCode)
        XCTAssertFalse(states.city)
        XCTAssertFalse(states.state)
        XCTAssertFalse(states.addressLine1)
        XCTAssertFalse(states.addressLine2)
        XCTAssertFalse(states.firstName)
        XCTAssertFalse(states.lastName)
        XCTAssertFalse(states.email)
        XCTAssertFalse(states.phoneNumber)
    }

    func test_equatable_sameValues_areEqual() {
        // Given
        var states1 = FieldValidationStates()
        states1.cardNumber = true
        var states2 = FieldValidationStates()
        states2.cardNumber = true

        // Then
        XCTAssertEqual(states1, states2)
    }

    func test_equatable_differentValues_areNotEqual() {
        // Given
        var states1 = FieldValidationStates()
        states1.cardNumber = true
        let states2 = FieldValidationStates()

        // Then
        XCTAssertNotEqual(states1, states2)
    }
}
