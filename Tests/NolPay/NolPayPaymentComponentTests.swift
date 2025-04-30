//
//  NolPayPaymentComponentTests.swift
//  Debug App Tests
//
//  Created by Boris on 10.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

class NolPayPaymentComponentTests: XCTestCase {
    var sut: NolPayPaymentComponent!
    var mockErrorDelegate: MockErrorDelegate!
    var mockValidationDelegate: MockValidationDelegate!
    var mockStepDelegate: MockStepDelegate!
    var mockPhoneMetadataService: MockPhoneMetadataService!
    var mockNolPayTokenizationViewModel: MockNolPayTokenizationViewModel!
    var mockNolPay: MockPrimerNolPay!

    override func setUp() {
        super.setUp()
        PrimerInternal.shared.intent = .checkout

        let paymentMethod = Mocks.PaymentMethods.nolPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        mockErrorDelegate = MockErrorDelegate()
        mockValidationDelegate = MockValidationDelegate()
        mockStepDelegate = MockStepDelegate()
        mockPhoneMetadataService = MockPhoneMetadataService()
        mockNolPayTokenizationViewModel = MockNolPayTokenizationViewModel(config: paymentMethod)
        mockNolPay = MockPrimerNolPay(appId: "123", isDebug: true, isSandbox: true, appSecretHandler: { _, _ in
            "appSecret"
        })

        sut = NolPayPaymentComponent(
            tokenizationViewModel: mockNolPayTokenizationViewModel,
            phoneMetadataService: mockPhoneMetadataService
        )
        sut.errorDelegate = mockErrorDelegate
        sut.validationDelegate = mockValidationDelegate
        sut.stepDelegate = mockStepDelegate
    }

    override func tearDown() {
        sut = nil
        mockErrorDelegate = nil
        mockValidationDelegate = nil
        mockStepDelegate = nil
        mockPhoneMetadataService = nil
        mockNolPay = nil
        mockNolPayTokenizationViewModel = nil

        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - Tests

    func test_UpdateCollectedData_WhenDataIsValid_ShouldUpdateSuccessfully() {
        // Given
        let mobileNumber = "+1231231231231"
        let cardNumber = "1234567812345678"
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber)

        // When
        sut.updateCollectedData(collectableData: data)

        // Then
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
    }

    func test_UpdateCollectedData_WhenCardNumberIsInvalidAndPhoneNumberIsValid_ShouldReturnCardNumberError() {
        // Given
        let mobileNumber = "+1231231231231"
        let countryCode = "+123"
        let cardNumber = ""
        let expectedError = PrimerValidationError.invalidCardnumber(
            message: "Card number is not valid.",
            userInfo: [:],
            diagnosticsId: ""
        )
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber)
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: data)

        // Then
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .invalid(let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertEqual(errors.count, 1)
            guard let primerValidationError = errors.first else {
                XCTFail("Expected error to be of type PrimerValidationError, but got \(String(describing: errors.first))")
                return
            }

            XCTAssertEqual(primerValidationError.errorId, expectedError.errorId)
        } else {
            XCTFail(
                "Expected validation status to be .invalid with errors, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_UpdateCollectedData_WhenCardNumberAndPhoneNumberAreInvalid_ShouldReturnBothErrors() {
        // Given
        let mobileNumber = ""
        let cardNumber = ""
        let expectedCardError = PrimerValidationError.invalidCardnumber(
            message: "Card number is not valid.",
            userInfo: [:],
            diagnosticsId: ""
        )
        let expectedPhoneError = PrimerValidationError.invalidPhoneNumber(
            message: "Phone number is not valid.",
            userInfo: [:],
            diagnosticsId: ""
        )
        mockPhoneMetadataService.resultToReturn = .success((.invalid(errors: [expectedPhoneError]), nil, nil))
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber)

        // When
        sut.updateCollectedData(collectableData: data)

        // Then
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .invalid(let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertEqual(errors.count, 2)

            // Validate the first error
            let primerValidationError0 = errors[0]
            XCTAssertEqual(primerValidationError0.errorId, expectedCardError.errorId)

            // Validate the second error
            let primerValidationError1 = errors[1]
            XCTAssertEqual(primerValidationError1.errorId, expectedPhoneError.errorId)
        } else {
            XCTFail(
                "Expected validation status to be .invalid with errors, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_UpdateCollectedData_WhenPhoneMetadataServiceFails_ShouldReturnError() {
        // Given
        let mobileNumber = ""
        let cardNumber = ""
        let expectedErrorKey = "INVALID_DATA"
        let expectedError = PrimerError.invalidValue(key: expectedErrorKey, value: nil, userInfo: nil, diagnosticsId: "")
        mockPhoneMetadataService.resultToReturn = .failure(expectedError)
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber)

        // When
        sut.updateCollectedData(collectableData: data)

        // Then
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .error(let error) = mockValidationDelegate.validationsReceived {
            if case PrimerError.invalidValue(let key, _, _, _) = error {
                XCTAssertEqual(key, expectedErrorKey)
            } else {
                XCTFail("Expected invalidValue error")
            }
        } else {
            XCTFail(
                "Expected validation status to be .error with errors, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_UpdateCollectedData_WhenDataIsValid_ShouldReturnValidStatus() {
        // Given
        let mobileNumber = "+1231231231231"
        let countryCode = "+123"
        let cardNumber = "1234567812345678"
        let data = NolPayPaymentCollectableData.paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber)
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: data)

        // Then
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertEqual(sut.countryCode, countryCode)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .valid = mockValidationDelegate.validationsReceived {
            // Validation status is valid, no further assertions needed
        } else {
            XCTFail(
                "Expected validation status to be .valid, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_Submit_WhenCardNumberIsNotProvided_ThenCardNumberErrorIsReturned() {
        // Given
        sut.nextDataStep = .collectCardAndPhoneData

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "cardNumber")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_WhenMobileNumberIsNotProvided_ThenMobileNumberErrorIsReturned() {
        // Given
        let cardNumber = "1234567812345678"
        sut.cardNumber = cardNumber
        sut.nextDataStep = .collectCardAndPhoneData

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "mobileNumber")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_WhenCountryCodeIsNotProvided_ThenCountryCodeErrorIsReturned() {
        // Given
        let cardNumber = "1234567812345678"
        let mobileNumber = "+1231231231231"
        sut.cardNumber = cardNumber
        sut.mobileNumber = mobileNumber
        sut.nextDataStep = .collectCardAndPhoneData

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "countryCode")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_WhenSdkIsNotInitialized_ThenNolSdkInitErrorIsReturned() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        let cardNumber = "1234567812345678"
        let mobileNumber = "+1231231231231"
        let countryCode = "+123"
        sut.cardNumber = cardNumber
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.nextDataStep = .collectCardAndPhoneData

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        XCTAssertEqual(primerError.errorId, expectedError.errorId)
    }

    func test_Submit_WhenPaymentRequestFails_ShouldReturnError() {
        // Given
        let cardNumber = "1234567812345678"
        let mobileNumber = "+1231231231231"
        let countryCode = "+123"
        sut.cardNumber = cardNumber
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.nextDataStep = .collectCardAndPhoneData

        mockNolPay.requestPaymentResult = .success(false)
        sut.nolPay = mockNolPay

        let expectation = self.expectation(description: "Async payment request should fail")

        mockNolPayTokenizationViewModel.onStartCalled = { [weak self] in
            guard let self else { return }
            mockNolPayTokenizationViewModel.triggerAsyncAction("") { result in
                switch result {
                case .success:
                    XCTFail("Expected payment request to fail, but it succeeded")
                case .failure(let error):
                    XCTAssertNotNil(error, "Expected an error, but got nil")

                    guard let primerError = error as? PrimerError else {
                        XCTFail("Error should be of type PrimerError")
                        return
                    }

                    switch primerError {
                    case .nolError(let code, let message, _, _):
                        XCTAssertTrue(code == "unknown")
                        XCTAssertTrue(message == "Payment failed from unknown reason")
                    default:
                        XCTFail("primerError should be of type nolError")
                    }

                    expectation.fulfill()
                }
            }
        }

        // When
        sut.submit()

        // Then
        waitForExpectations(timeout: 5) // Adjust timeout as needed
        XCTAssertEqual(mockNolPayTokenizationViewModel.nolPayCardNumber, cardNumber)
        XCTAssertEqual(mockNolPayTokenizationViewModel.mobileNumber, mobileNumber)
        XCTAssertEqual(mockNolPayTokenizationViewModel.mobileCountryCode, countryCode)
    }

    func test_Submit_WhenPaymentRequestFailsWithError_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        let cardNumber = "1234567812345678"
        let mobileNumber = "+1231231231231"
        let countryCode = "+123"
        sut.cardNumber = cardNumber
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.nextDataStep = .collectCardAndPhoneData

        mockNolPay.requestPaymentResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
        sut.nolPay = mockNolPay

        let expectation = self.expectation(description: "Async payment request should fail")

        mockNolPayTokenizationViewModel.onStartCalled = { [weak self] in
            guard let self else { return }
            mockNolPayTokenizationViewModel.triggerAsyncAction("") { result in
                switch result {
                case .success:
                    XCTFail("Expected payment request to fail, but it succeeded")
                case .failure(let error):
                    XCTAssertNotNil(error, "Expected an error, but got nil")
                    guard let primerError = error as? PrimerError else {
                        XCTFail("Error should be of type PrimerError")
                        return
                    }

                    switch primerError {
                    case .nolError(_, let message, _, _):
                        XCTAssertTrue(message == expectedErrorDescription)
                    default:
                        XCTFail("primerError should be of type nolError")
                    }

                    expectation.fulfill()
                }
            }
        }

        // When
        sut.submit()

        // Then
        waitForExpectations(timeout: 5) // Adjust timeout as needed
        XCTAssertEqual(mockNolPayTokenizationViewModel.nolPayCardNumber, cardNumber)
        XCTAssertEqual(mockNolPayTokenizationViewModel.mobileNumber, mobileNumber)
        XCTAssertEqual(mockNolPayTokenizationViewModel.mobileCountryCode, countryCode)
    }

    func test_Submit_WhenPaymentRequestSucceeds_ShouldReturnSuccess() {
        // Given
        let cardNumber = "1234567812345678"
        let mobileNumber = "+1231231231231"
        let countryCode = "+123"
        sut.cardNumber = cardNumber
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.nextDataStep = .collectCardAndPhoneData

        mockNolPay.requestPaymentResult = .success(true)
        sut.nolPay = mockNolPay

        let expectation = self.expectation(description: "Async payment request should succeed")

        mockNolPayTokenizationViewModel.onStartCalled = { [weak self] in
            guard let self else { return }
            mockNolPayTokenizationViewModel.triggerAsyncAction("") { result in
                switch result {
                case .success:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected payment request to succeed, but it failed with error: \(error)")
                }
            }
        }

        // When
        sut.submit()

        // Then
        waitForExpectations(timeout: 5) // Adjust timeout as needed
        XCTAssertEqual(mockNolPayTokenizationViewModel.nolPayCardNumber, cardNumber)
        XCTAssertEqual(mockNolPayTokenizationViewModel.mobileNumber, mobileNumber)
        XCTAssertEqual(mockNolPayTokenizationViewModel.mobileCountryCode, countryCode)
    }

    func test_Start_WhenAppIDIsInvalid_ThenErrorIsReturned() {
        // Given
        SDKSessionHelper.tearDown()

        // When
        sut.start()

        // Then
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

    func test_Start_WhenNoClientToken_ThenErrorIsReturned() {
        // Given
        AppState.current.clientToken = nil

        // When
        sut.start()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }
        XCTAssertEqual(primerError.errorId, "invalid-client-token")
    }
}
#endif
