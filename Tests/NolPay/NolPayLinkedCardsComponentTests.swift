//
//  NolPayLinkedCardsComponentTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

class NolPayLinkedCardsComponentTests: XCTestCase {
    var sut: NolPayLinkedCardsComponent!
    var mockApiClient: MockPrimerAPIClient!
    var mockErrorDelegate: MockErrorDelegate!
    var mockValidationDelegate: MockValidationDelegate!
    var mockStepDelegate: MockStepDelegate!
    var mockPhoneMetadataService: MockPhoneMetadataService!
    var mockNolPayTokenizationViewModel: MockNolPayTokenizationViewModel!
    var mockNolPay: MockPrimerNolPay!

    let mobileNumber = "+111123123123123"
    let countryCode = "+111"
    //    let otpCode = "123456"
    let cardNumber = "1234567890123456"
    //    let linkToken = "LINK_TOKEN"

    override func setUp() {
        super.setUp()
        PrimerInternal.shared.intent = .checkout

        let paymentMethod = Mocks.PaymentMethods.nolPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        mockApiClient = MockPrimerAPIClient()
        mockErrorDelegate = MockErrorDelegate()
        mockValidationDelegate = MockValidationDelegate()
        mockStepDelegate = MockStepDelegate()
        mockPhoneMetadataService = MockPhoneMetadataService()
        mockNolPayTokenizationViewModel = MockNolPayTokenizationViewModel(config: paymentMethod)
        mockNolPay = MockPrimerNolPay(appId: "123", isDebug: true, isSandbox: true, appSecretHandler: { _, _ in
            "appSecret"
        })

        sut = NolPayLinkedCardsComponent(apiClient: mockApiClient, phoneMetadataService: mockPhoneMetadataService)
        sut.errorDelegate = mockErrorDelegate
        sut.validationDelegate = mockValidationDelegate
        //        sut.stepDelegate = mockStepDelegate
    }

    override func tearDown() {
        sut = nil
        mockApiClient = nil
        mockErrorDelegate = nil
        mockValidationDelegate = nil
        mockStepDelegate = nil
        mockPhoneMetadataService = nil
        mockNolPay = nil
        mockNolPayTokenizationViewModel = nil

        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    func test_Start_WhenSDKSessionNotSetUp_ShouldReturnInvalidValueError() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        SDKSessionHelper.tearDown()

        // When
        sut.start { _ in
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "nolPayAppId")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Start_WhenClientTokenIsNil_ShouldReturnInvalidClientTokenError() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        AppState.current.clientToken = nil

        // When
        sut.start { _ in
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }
        XCTAssertEqual(primerError.errorId, "invalid-client-token")
    }

    func test_Start_WhenSDKStartsSuccessfully_ShouldCompleteSuccessfully() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        sut.nolPay = mockNolPay

        // When
        sut.start { result in
            switch result {
            case .success:
                XCTAssertTrue(true) // Expecting success
            case .failure(let error):
                XCTFail("Expected success, but got error: \(error)")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
        XCTAssertNil(mockErrorDelegate.errorReceived, "No error should be received")
    }

    func test_Start_WhenSDKFailsWithError_ShouldReturnUnderlyingErrors() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        let expectedErrorCode = "EXPECTED_ERROR_CODE"
        mockApiClient.fetchNolSdkSecretResult = {
            .failure(PrimerError.nolError(code: expectedErrorCode, message: ""))
        }

        // When
        sut.start { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let primerError):
                switch primerError {
                case .underlyingErrors(let errors, _):
                    guard let firstPrimerError = errors.first as? PrimerError else {
                        XCTFail("Error should be of type PrimerError")
                        return
                    }

                    switch firstPrimerError {
                    case .nolError(let code, _, _):
                        XCTAssertEqual(code, expectedErrorCode)
                    default:
                        XCTFail("Error should be of type .nolError")
                    }
                default:
                    XCTFail("Error should be of type .underlyingErrors")
                }
            }

            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_Start_WhenSDKStartsWithValidSecret_ShouldCompleteSuccessfully() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        mockApiClient.fetchNolSdkSecretResult = {
            .success(Response.Body.NolPay.NolPaySecretDataResponse(sdkSecret: ""))
        }

        // When
        sut.start { result in
            switch result {
            case .success:
                XCTAssertTrue(true) // Expecting success
            case .failure(let error):
                XCTFail("Expected success, but got error: \(error)")
            }

            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenSDKInitializationFails_ShouldReturnNolSdkInitError() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        let expectedError = PrimerError.nolSdkInitError()

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success(let cards):
                XCTFail("Expected failure but got success with cards: \(cards)")
            case .failure(let primerError):
                XCTAssertEqual(primerError.errorId, expectedError.errorId)
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenPhoneMetadataServiceFails_ShouldReturnInvalidValueError() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        let expectedErrorKey = "INVALID_DATA"
        let expectedError = PrimerError.invalidValue(key: expectedErrorKey)
        mockPhoneMetadataService.resultToReturn = .failure(expectedError)

        sut.nolPay = mockNolPay

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success(let cards):
                XCTFail("Expected failure but got success with cards: \(cards)")
            case .failure(let error):
                if case .invalidValue(let key, _, _, _) = error {
                    XCTAssertEqual(key, expectedErrorKey)
                } else {
                    XCTFail("Expected error to be of type .invalidValue")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenPhoneNumberIsInvalid_ShouldReturnInvalidPhoneNumberError() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        let expectedErrorMessage = "EXPECTED_ERROR_MESSAGE"
        let expectedError = PrimerValidationError.invalidPhoneNumber(message: expectedErrorMessage)
        mockPhoneMetadataService.resultToReturn = .success((.invalid(errors: [expectedError]), nil, nil))

        sut.nolPay = mockNolPay

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let primerError):
                switch primerError {
                case .underlyingErrors(let errors, _):
                    guard let firstPrimerValidationError = errors.first as? PrimerValidationError else {
                        XCTFail("Error should be of type PrimerError")
                        return
                    }

                    switch firstPrimerValidationError {
                    case .invalidPhoneNumber(let message, _):
                        XCTAssertEqual(expectedErrorMessage, message)
                    default:
                        XCTFail("Error should be of type .nolError")
                    }
                default:
                    XCTFail("Error should be of type .underlyingErrors")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenMobileNumberIsInvalid_ShouldReturnInvalidValueError() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        mockPhoneMetadataService.resultToReturn = .success((.valid, nil, nil))
        sut.nolPay = mockNolPay

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let primerError):
                switch primerError {
                case .invalidValue(let key, _, _, _):
                    XCTAssertEqual(key, "mobileNumber")
                default:
                    XCTFail("Error should be of type .invalidValue")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenCountryCodeIsInvalid_ShouldReturnInvalidValueError() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        mockPhoneMetadataService.resultToReturn = .success((.valid, nil, mobileNumber))
        sut.nolPay = mockNolPay

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let primerError):
                switch primerError {
                case .invalidValue(let key, _, _, _):
                    XCTAssertEqual(key, "countryCode")
                default:
                    XCTFail("Error should be of type .underlyingErrors")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenNolPaySdkFails_ShouldReturnNolPaySdkError() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        let expectedErrorCode = "EXPECTED_ERROR_CODE"
        let expectedError = PrimerNolPayError.nolPaySdkError(code: expectedErrorCode, message: "")
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))
        sut.nolPay = mockNolPay
        mockNolPay.getAvailableCardsResult = .failure(expectedError)

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let primerError):
                switch primerError {
                case .nolError(let code, _, _):
                    XCTAssertEqual(code, expectedErrorCode)
                default:
                    XCTFail("Error should be of type .nolError")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_ContinueWithLinkedCardsFetch_WhenCardsAreFetchedSuccessfully_ShouldReturnNonEmptyCardList() {
        // Given
        let exp = expectation(description: "Wait for continueWithLinkedCardsFetch to complete")
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))
        sut.nolPay = mockNolPay
        mockNolPay.getAvailableCardsResult = .success([.init(cardNumber: cardNumber, expiredTime: "")])

        // When
        sut.continueWithLinkedCardsFetch(mobileNumber: mobileNumber) { result in
            switch result {
            case .success(let cards):
                XCTAssertFalse(cards.isEmpty, "Expected non-empty card list")
                XCTAssertEqual(cards.first?.cardNumber, self.cardNumber)
            case .failure(let primerError):
                XCTFail("Expected success, but got error: \(primerError)")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_GetLinkedCardsFor_WhenApiClientFails_ShouldReturnError() {
        // Given
        let exp = expectation(description: "Wait for getLinkedCardsFor to complete")
        let expectedErrorCode = "EXPECTED_ERROR_CODE"
        mockApiClient.fetchNolSdkSecretResult = {
            .failure(PrimerError.nolError(code: expectedErrorCode, message: ""))
        }

        // When
        sut.getLinkedCardsFor(mobileNumber: mobileNumber) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let primerError):
                switch primerError {
                case .underlyingErrors(let errors, _):
                    guard let firstPrimerError = errors.first as? PrimerError else {
                        XCTFail("Error should be of type PrimerError")
                        return
                    }

                    switch firstPrimerError {
                    case .nolError(let code, _, _):
                        XCTAssertEqual(code, expectedErrorCode)
                    default:
                        XCTFail("Error should be of type .nolError")
                    }
                default:
                    XCTFail("Error should be of type .underlyingErrors")
                }
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_GetLinkedCardsFor_WhenCardsAreFetchedSuccessfully_ShouldReturnNonEmptyCardList() {
        // Given
        let exp = expectation(description: "Wait for getLinkedCardsFor to complete")
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))
        sut.nolPay = mockNolPay
        mockNolPay.getAvailableCardsResult = .success([.init(cardNumber: cardNumber, expiredTime: "")])

        // When
        sut.getLinkedCardsFor(mobileNumber: mobileNumber) { result in
            switch result {
            case .success(let cards):
                XCTAssertFalse(cards.isEmpty, "Expected non-empty card list")
                XCTAssertEqual(cards.first?.cardNumber, self.cardNumber)
            case .failure(let primerError):
                XCTFail("Expected success, but got error: \(primerError)")
            }
            exp.fulfill()
        }

        // Then
        wait(for: [exp], timeout: 5.0)
    }
}
#endif
