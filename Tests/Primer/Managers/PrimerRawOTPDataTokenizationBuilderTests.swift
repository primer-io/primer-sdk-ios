//
//  PrimerRawOTPDataTokenizationBuilderTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class PrimerRawOTPDataTokenizationBuilderTests: XCTestCase {

    var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp()
        mockApiClient = MockPrimerAPIClient()
    }

    override func tearDown() {
        resetPrimerConfiguration()
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - Test 'configure(withRawDataManager:)'

    func test_configure_withRawDataManager_setsRawDataManager() {
        // Given
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        XCTAssertNil(tokenizationBuilder.rawDataManager, "rawDataManager should initially be nil")

        prepareConfigurations(paymentMethodType: "ADYEN_BLIK")

        var mockRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
        do {
            mockRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "ADYEN_BLIK")
        } catch {
            XCTFail("Failed to initialize RawDataManager: \(error)")
            return
        }

        // When
        tokenizationBuilder.configure(withRawDataManager: mockRawDataManager!)

        // Then
        XCTAssertNotNil(tokenizationBuilder.rawDataManager, "rawDataManager should be set after configure")
        XCTAssertTrue(tokenizationBuilder.rawDataManager === mockRawDataManager, "rawDataManager should be the same instance passed to configure")
    }

    // MARK: - Test 'validateRawData' with invalid OTP

    func test_validateRawData_withEmptyOTP_shouldFail() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "")
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawOTPData)
            XCTFail("OTP data should not pass validation when OTP is empty")
        } catch {
            // Expected to throw an error for invalid data
        }
    }

    func test_validateRawData_withNonNumericOTP_shouldFail() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "abc123")
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawOTPData)
            XCTFail("OTP data should not pass validation when OTP contains letters")
        } catch {
            // Expected to throw an error for invalid data
        }
    }

    func test_validateRawData_withTooShortOTP_shouldFail() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "12345") // 5 digits
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawOTPData)
            XCTFail("OTP data should not pass validation when OTP is too short")
        } catch {
            // Expected to throw an error for invalid data
        }
    }

    func test_validateRawData_withTooLongOTP_shouldFail() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "1234567") // 7 digits
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawOTPData)
            XCTFail("OTP data should not pass validation when OTP is too long")
        } catch {
            // Expected to throw an error for invalid data
        }
    }

    func test_validateRawData_withInvalidDataType_shouldFail() async throws {
        // Given
        let invalidRawData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "12/2030",
            cvv: "123",
            cardholderName: "John Doe"
        )
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(invalidRawData)
            XCTFail("Expected validation to fail with invalid raw data type")
        } catch {
            XCTAssert(error is PrimerValidationError)
        }
    }

    // MARK: - Test 'validateRawData' with valid OTP

    func test_validateRawData_withValidOTP_shouldSucceed() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "123456") // 6 digits
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawOTPData)
            // Success, no error expected
        } catch {
            XCTFail("OTP data should pass validation but failed with error: \(error)")
        }
    }

    // MARK: - Test 'makeRequestBodyWithRawData'

    func test_makeRequestBodyWithRawData_withInvalidPaymentMethodType_shouldFail() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "123456")
        let invalidPaymentMethodType = "INVALID_PAYMENT_METHOD"
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: invalidPaymentMethodType)

        // When & Then
        do {
            try await tokenizationBuilder.makeRequestBodyWithRawData(rawOTPData)
            XCTFail("Should not have succeeded with invalid payment method type")
        } catch {
            // Expected to throw an error for invalid payment method
        }
    }

    func test_makeRequestBodyWithRawData_withInvalidDataType_shouldFail() async throws {
        // Given
        let invalidRawData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "12/2030",
            cvv: "123",
            cardholderName: "John Doe"
        )
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            try await tokenizationBuilder.makeRequestBodyWithRawData(invalidRawData)
            XCTFail("Expected failure when raw data is invalid")
        } catch {
            XCTAssert(error is PrimerError)
        }
    }

    func test_makeRequestBodyWithRawData_withValidData_shouldSucceed() async throws {
        // Given
        let rawOTPData = PrimerOTPData(otp: "123456")
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        prepareConfigurations(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        do {
            let requestBody = try await tokenizationBuilder.makeRequestBodyWithRawData(rawOTPData)
            
            // Then - Assert that requestBody is correct
            XCTAssertNotNil(requestBody.paymentInstrument)
            if let paymentInstrument = requestBody.paymentInstrument as? OffSessionPaymentInstrument {
                XCTAssertEqual(paymentInstrument.paymentMethodConfigId, "payment_method_id")
                XCTAssertEqual(paymentInstrument.paymentMethodType, "ADYEN_BLIK")
                if let sessionInfo = paymentInstrument.sessionInfo as? BlikSessionInfo {
                    XCTAssertEqual(sessionInfo.blikCode, "123456")
                } else {
                    XCTFail("Expected sessionInfo to be BlikSessionInfo")
                }
            } else {
                XCTFail("Expected paymentInstrument to be OffSessionPaymentInstrument")
            }
        } catch {
            XCTFail("Expected success but got error: \(error)")
        }
    }

    // MARK: - Test 'requiredInputElementTypes'

    func test_requiredInputElementTypes_shouldReturnOTPType() {
        // Given
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")

        // When & Then
        XCTAssertEqual(tokenizationBuilder.requiredInputElementTypes, [.otp])
    }

    // MARK: - Helper Methods

    private func prepareConfigurations(paymentMethodType: String) {
        mockApiClient = MockPrimerAPIClient()
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        let paymentMethod = PrimerPaymentMethod(
            id: "payment_method_id",
            implementationType: .nativeSdk,
            type: paymentMethodType,
            name: "Adyen Blik",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )

        let mockAPIConfiguration = createMockAPIConfiguration(paymentMethods: [paymentMethod])
        setupPrimerConfiguration(apiConfiguration: mockAPIConfiguration)
    }

    private func createMockAPIConfiguration(paymentMethods: [PrimerPaymentMethod]) -> PrimerAPIConfiguration {
        let mockAPIConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://core.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://primer.io/bindata",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: nil,
            paymentMethods: paymentMethods,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil)
        return mockAPIConfiguration
    }

    private func setupPrimerConfiguration(apiConfiguration: PrimerAPIConfiguration) {
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)

        AppState.current.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
    }

    private func resetPrimerConfiguration() {
        mockApiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
    }
}
