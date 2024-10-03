//
//  PrimerRawOTPDataTokenizationBuilderTests.swift
//
//  Created by Boris on 26/9/24.
//

import XCTest
@testable import PrimerSDK

class PrimerRawOTPDataTokenizationBuilderTests: XCTestCase {
    
    static let validationTimeout = 3.0
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

    func test_configure_withRawDataManager_sets_rawDataManager() {
        // Arrange
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        XCTAssertNil(tokenizationBuilder.rawDataManager, "rawDataManager should initially be nil")

        prepareConfigurations(paymentMethodType: "ADYEN_BLIK")

        // Initialize a mock RawDataManager
        var mockRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
        do {
            mockRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "ADYEN_BLIK")
        } catch {
            XCTFail("Failed to initialize RawDataManager: \(error)")
            return
        }

        // Act
        tokenizationBuilder.configure(withRawDataManager: mockRawDataManager!)

        // Assert
        XCTAssertNotNil(tokenizationBuilder.rawDataManager, "rawDataManager should be set after configure")
        XCTAssertTrue(tokenizationBuilder.rawDataManager === mockRawDataManager, "rawDataManager should be the same instance passed to configure")
    }

    // Test invalid OTP: Empty string
    func test_invalid_otp_in_raw_otp_data_empty() throws {
        let exp = expectation(description: "Await validation")
        
        let rawOTPData = PrimerOTPData(otp: "")
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawOTPData)
        }
        .done {
            XCTAssert(false, "OTP data should not pass validation when OTP is empty")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // Test invalid OTP: Contains letters
    func test_invalid_otp_in_raw_otp_data_non_numeric() throws {
        let exp = expectation(description: "Await validation")
        
        let rawOTPData = PrimerOTPData(otp: "abc123")
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawOTPData)
        }
        .done {
            XCTAssert(false, "OTP data should not pass validation when OTP contains letters")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // Test invalid OTP: Too short
    func test_invalid_otp_in_raw_otp_data_too_short() throws {
        let exp = expectation(description: "Await validation")
        
        let rawOTPData = PrimerOTPData(otp: "12345") // 5 digits
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawOTPData)
        }
        .done {
            XCTAssert(false, "OTP data should not pass validation when OTP is too short")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // Test invalid OTP: Too long
    func test_invalid_otp_in_raw_otp_data_too_long() throws {
        let exp = expectation(description: "Await validation")
        
        let rawOTPData = PrimerOTPData(otp: "1234567") // 7 digits
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawOTPData)
        }
        .done {
            XCTAssert(false, "OTP data should not pass validation when OTP is too long")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // Test valid OTP
    func test_valid_otp_in_raw_otp_data() throws {
        let exp = expectation(description: "Await validation")
        
        let rawOTPData = PrimerOTPData(otp: "123456") // 6 digits
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawOTPData)
        }
        .done {
            exp.fulfill()
        }
        .catch { error in
            XCTAssert(false, "OTP data should pass validation but failed with error: \(error)")
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // Test making request body with invalid payment method type
    func test_make_request_body_with_raw_data_invalid_payment_method_type() throws {
        let exp = expectation(description: "Await making request body")
        
        let rawOTPData = PrimerOTPData(otp: "123456")
        let invalidPaymentMethodType = "INVALID_PAYMENT_METHOD"
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: invalidPaymentMethodType)
        
        firstly {
            tokenizationBuilder.makeRequestBodyWithRawData(rawOTPData)
        }
        .done { _ in
            XCTAssert(false, "Should not have succeeded with invalid payment method type")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // MARK: - Test 'requiredInputElementTypes'
    
    func test_requiredInputElementTypes() {
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        XCTAssertEqual(tokenizationBuilder.requiredInputElementTypes, [.otp])
    }
    
    // MARK: - Test 'makeRequestBodyWithRawData' with invalid rawData
    
    func test_makeRequestBodyWithRawData_with_invalid_data_type() {
        let exp = expectation(description: "Await making request body")
        
        // Using PrimerCardData instead of PrimerOTPData
        let invalidRawData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "12/2030",
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            tokenizationBuilder.makeRequestBodyWithRawData(invalidRawData)
        }
        .done { _ in
            XCTFail("Expected failure when raw data is invalid")
            exp.fulfill()
        }
        .catch { error in
            XCTAssert(error is PrimerError)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // MARK: - Test 'validateRawData' with invalid data type
    
    func test_validateRawData_with_invalid_data_type() {
        let exp = expectation(description: "Await validation")
        
        // Using PrimerCardData instead of PrimerOTPData
        let invalidRawData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "12/2030",
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            tokenizationBuilder.validateRawData(invalidRawData)
        }
        .done {
            XCTFail("Expected validation to fail with invalid raw data type")
            exp.fulfill()
        }
        .catch { error in
            XCTAssert(error is PrimerValidationError)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: Self.validationTimeout)
    }
    
    // MARK: - Test 'makeRequestBodyWithRawData' with valid rawData
    
    func test_makeRequestBodyWithRawData_with_valid_data() {
        let exp = expectation(description: "Await making request body")
        
        let rawOTPData = PrimerOTPData(otp: "123456")
        let tokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: "ADYEN_BLIK")
        
        // Prepare the client session with the payment method
        prepareConfigurations(paymentMethodType: "ADYEN_BLIK")
        
        firstly {
            tokenizationBuilder.makeRequestBodyWithRawData(rawOTPData)
        }
        .done { requestBody in
            // Assert that requestBody is correct
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
            exp.fulfill()
        }
        .catch { error in
            XCTFail("Expected success but got error: \(error)")
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: Self.validationTimeout)
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
        // Ensure that mockApiClient is of type MockPrimerAPIClient
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

