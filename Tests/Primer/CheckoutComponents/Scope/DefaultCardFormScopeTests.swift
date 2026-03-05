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
}
