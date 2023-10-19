//
//  NolPayPaymentComponentTests.swift
//  Debug App Tests
//
//  Created by Boris on 10.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK


class MockPrimerNolPay: PrimerNolPayProtocol {

    // Mock responses for the mock methods
    var mockCardNumber: String = "1234567890123456"
    var mockError: PrimerNolPayError = PrimerNolPayError(description: "Mock Error")
    var mockBoolResponse: Bool = true
    var mockOTPResponse: (String, String) = ("mockOTP", "mockToken")
    var mockCards: [PrimerNolPayCard] = [PrimerNolPayCard(cardNumber: "1234567890123456", expiredTime: "12/34")]

    required init(appId: String, isDebug: Bool, isSandbox: Bool, appSecretHandler: @escaping (String, String) async throws -> String) {
    }
    
    func scanNFCCard(completion: @escaping (Result<String, PrimerNolPayError>) -> Void) {
        completion(.success(mockCardNumber))
    }
    
    func makeLinkingToken(for cardNumber: String, completion: @escaping (Result<String, PrimerNolPayError>) -> Void) {
        completion(.success("mockLinkingToken"))
    }
    
    func sendLinkOTP(to mobileNumber: String, with countryCode: String, and token: String, completion: ((Result<Bool, PrimerNolPayError>) -> Void)?) {
        completion?(.success(mockBoolResponse))
    }
    
    func linkCard(for otp: String, and linkToken: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
        completion(.success(mockBoolResponse))
    }
    
    func sendUnlinkOTP(to mobileNumber: String, with countryCode: String, and cardNumber: String, completion: @escaping (Result<(String, String), PrimerNolPayError>) -> Void) {
        completion(.success(mockOTPResponse))
    }
    
    func unlinkCard(with cardNumber: String, otp: String, and unlinkToken: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
        completion(.success(mockBoolResponse))
    }
    
    func requestPayment(for cardNumber: String, and transactionNumber: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
        completion(.success(mockBoolResponse))
    }
    
    func getAvailableCards(for mobileNumber: String, with countryCode: String, completion: @escaping (Result<[PrimerNolPayCard], PrimerNolPayError>) -> Void) {
        completion(.success(mockCards))
    }
}

class MockValidationDelegate: PrimerHeadlessValidatableDelegate {
    var validationsReceived: [PrimerValidationError]?
    var wasValidatedCalled = false

    func didValidate(validations: [PrimerValidationError], for data: PrimerCollectableData) {
        validationsReceived = validations
        wasValidatedCalled = true
    }
}


class MockStepDelegate: PrimerHeadlessSteppableDelegate {
    var stepReceived: PrimerHeadlessStep?
    
    func didReceiveStep(step: PrimerHeadlessStep) {
        stepReceived = step
    }
}

class MockErrorDelegate: PrimerHeadlessErrorableDelegate {
    var errorReceived: Error?
    
    func didReceiveError(error: PrimerSDK.PrimerError) {
        errorReceived = error
    }
}

class MockNolPayTokenizationViewModel: NolPayTokenizationViewModel {
    
    // Mock response values
    var mockValidateError: Error?
    var mockTokenizationResult: Result<PrimerPaymentMethodTokenData, Error>?
    var mockAwaitUserInputResult: Result<Void, Error>?
    var mockPresentPaymentMethodUIResult: Result<Void, Error>?
    var mockHandleDecodedClientTokenResult: Result<String?, Error>?
    var mockPreTokenizationStepsResult: Result<Void, Error>?
    var mockTokenizationStepResult: Result<Void, Error>?
    var mockPostTokenizationStepsResult: Result<Void, Error>?
    var resultToReturn: Result<Bool, Error>?

    override func validate() throws {
        if let error = mockValidateError {
            throw error
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        switch resultToReturn {
        case .success:
            return .value(Response.Body.Tokenization(analyticsId: "1",
                                                     id: "1",
                                                     isVaulted: false,
                                                     isAlreadyVaulted: false,
                                                     paymentInstrumentType: PaymentInstrumentType.unknown,
                                                     paymentMethodType: "NOL_PAY",
                                                     paymentInstrumentData: nil,
                                                     threeDSecureAuthentication: nil,
                                                     token: "123qwe",
                                                     tokenType: nil,
                                                     vaultData: nil))
        case .failure(let error):
            return .init(error: error)
        default:
            return super.tokenize() // fallback to the real implementation
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        switch mockAwaitUserInputResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        switch mockPresentPaymentMethodUIResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        switch mockHandleDecodedClientTokenResult {
        case .success(let token):
            return .value(token)
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(nil) // Default stubbed value
        }
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        switch mockPreTokenizationStepsResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        switch mockTokenizationStepResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        switch mockPostTokenizationStepsResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }
    
    override func submitButtonTapped() {
        // No-op for mock
    }
}

class NolPayPaymentComponentTests: XCTestCase {
    
    var sut: NolPayPaymentComponent!
    
    override func setUp() {
        super.setUp()
        sut = NolPayPaymentComponent(isDebug: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testUpdateCollectedData_ValidData_ShouldUpdateInternalVariables() {
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: "1234567812345678", mobileNumber: "+1234567890", phoneCountryDiallingCode: "+1")
        sut.updateCollectedData(collectableData: data)
        
        XCTAssertEqual(sut.cardNumber, "1234567812345678")
        XCTAssertEqual(sut.mobileNumber, "+1234567890")
        XCTAssertEqual(sut.phoneCountryDiallingCode, "+1")
    }
    
    func testSubmit_MissingCardNumber_ShouldCallErrorDelegate() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }
    
    func testUpdateCollectedData_InvalidPhoneNumber_ShouldReturnPhoneValidationError() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: "1234567812345678", mobileNumber: "1234567890", phoneCountryDiallingCode: "+1")
        sut.updateCollectedData(collectableData: data)
        
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        XCTAssertNotNil(mockValidationDelegate.validationsReceived)
    }
    
    func testUpdateCollectedData_InvalidPhoneCountryCode_ShouldReturnCountryCodeValidationError() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: "1234567812345678", mobileNumber: "+1234567890", phoneCountryDiallingCode: "1234")
        sut.updateCollectedData(collectableData: data)
        
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        XCTAssertNotNil(mockValidationDelegate.validationsReceived)
    }
    
    func testValidationTriggeredWhenUpdatingPaymentData() {
        // Given
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: "", phoneCountryDiallingCode: ""))
        
        // Then
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled, "Validation was not triggered when updating payment data.")
    }
    
    func testInvalidPaymentDataValidationErrorReceived() {
        // Given
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: "", phoneCountryDiallingCode: ""))
        
        // Then
        XCTAssertNotNil(mockValidationDelegate.validationsReceived, "No validations received.")
    }

    func testValidateData_ValidData_ShouldNotReturnAnyError() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: "123456789", mobileNumber: "1234567890", phoneCountryDiallingCode: "+11")
        sut.updateCollectedData(collectableData: data)
        
        XCTAssertFalse(mockValidationDelegate.validationsReceived?.isEmpty == false)
    }
    
    func testSubmitWithNilCardNumber() {
        sut.cardNumber = nil
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when card number is nil.")
    }
    
    func testSubmitWithNilMobileNumber() {
        sut.cardNumber = "1234567890123456"
        sut.mobileNumber = nil
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when mobile number is nil.")
    }
    
    func testSubmitWithNilCountryDiallingCode() {
        sut.cardNumber = "1234567890123456"
        sut.mobileNumber = "1234567890"
        sut.phoneCountryDiallingCode = nil
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when country dialling code is nil.")
    }
        
    func testFailedPaymentRequest() {
        // Mock the payment request to always fail
        let mockPaymentMethod = MockNolPayTokenizationViewModel(config: PrimerPaymentMethod(id: "1", implementationType: PrimerPaymentMethod.ImplementationType.nativeSdk, type: "", name: "", processorConfigId: nil, surcharge: nil, options: nil, displayMetadata: nil))
        let expectedError = PrimerError.nolError(code: "unknown",
                                                 message: "Payment failed for test",
                                                 userInfo: nil,
                                                 diagnosticsId: UUID().uuidString)
        mockPaymentMethod.resultToReturn = .failure(expectedError)
        sut.tokenizationViewModel = mockPaymentMethod
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when payment fails.")
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError, "Expected error type to be PrimerError.")
    }
    
}
#endif
