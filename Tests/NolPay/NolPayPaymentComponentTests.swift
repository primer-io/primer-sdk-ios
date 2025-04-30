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

    let mobileNumber = "+111123123123123"
    let countryCode = "+1"
    let cardNumber = "1234567890123456"

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

    func test_UpdateCollectedData_PaymentData__WithValidData_ShouldUpdateSuccessfully() {
        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.cardNumber, cardNumber)
    }

    func test_UpdateCollectedData_PaymentData__WithInvalidCardNumberAndValidPhoneNumber_ShouldReturnCardNumberError() {
        // Given
        let expectedError = PrimerValidationError.invalidCardnumber(
            message: "Card number is not valid.",
            userInfo: nil,
            diagnosticsId: ""
        )
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.cardNumber, "")
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

    func test_UpdateCollectedData_PaymentData__WithInvalidCardNumberAndPhoneNumber_ShouldReturnBothErrors() {
        // Given
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

        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: ""))

        // Then
        XCTAssertEqual(sut.mobileNumber, "")
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.cardNumber, "")
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

    func test_UpdateCollectedData_PaymentData__WhenPhoneMetadataServiceFails_ShouldReturnError() {
        // Given
        let expectedErrorKey = "INVALID_DATA"
        let expectedError = PrimerError.invalidValue(key: expectedErrorKey, value: nil, userInfo: nil, diagnosticsId: "")
        mockPhoneMetadataService.resultToReturn = .failure(expectedError)

        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: "", mobileNumber: ""))

        // Then
        XCTAssertEqual(sut.mobileNumber, "")
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.cardNumber, "")
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

    func test_UpdateCollectedData_PaymentData__WithValidData_ShouldReturnValidStatus() {
        // Given
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: .paymentData(cardNumber: cardNumber, mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertEqual(sut.countryCode, countryCode)
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .valid = mockValidationDelegate.validationsReceived {
            // Validation status is valid, no further assertions needed
        } else {
            XCTFail(
                "Expected validation status to be .valid, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_Submit_CollectCardAndPhoneData__WithMissingCardNumber_ShouldReturnCardNumberError() {
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

    func test_Submit_CollectCardAndPhoneData__WithMissingMobileNumber_ShouldReturnMobileNumberError() {
        // Given
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

    func test_Submit_CollectCardAndPhoneData__WithMissingCountryCode_ShouldReturnCountryCodeError() {
        // Given
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

    func test_Submit_CollectCardAndPhoneData__WithUninitializedSDK_ShouldReturnNolSdkInitError() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
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

    func test_Submit_CollectCardAndPhoneData__WhenPaymentRequestFails_ShouldReturnUnknownError() {
        // Given
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

    func test_Submit_CollectCardAndPhoneData__WhenPaymentRequestFailsWithError_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
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

    func test_Submit_CollectCardAndPhoneData__WhenPaymentRequestSucceeds_ShouldReturnSuccess() {
        // Given
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

    func test_Start__WithInvalidAppID_ShouldReturnError() {
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

    func test_Start__WithNoClientToken_ShouldReturnError() {
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

    func test_Start__ShouldInitializeSuccessfully() {
        // When
        sut.start()
    }
}
#endif
