//
//  NolPayLinkCardComponentTest.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

final class NolPayLinkCardComponentTest: XCTestCase {
    var sut: NolPayLinkCardComponent!
    var mockApiClient: MockPrimerAPIClient!
    var mockErrorDelegate: MockErrorDelegate!
    var mockValidationDelegate: MockValidationDelegate!
    var mockStepDelegate: MockStepDelegate!
    var mockPhoneMetadataService: MockPhoneMetadataService!
    var mockNolPayTokenizationViewModel: MockNolPayTokenizationViewModel!
    var mockNolPay: MockPrimerNolPay!

    let mobileNumber = "+111123123123123"
    let countryCode = "+111"
    let otpCode = "123456"
    let cardNumber = "1234567890123456"
    let linkToken = "LINK_TOKEN"

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

        sut = NolPayLinkCardComponent(apiClient: mockApiClient, phoneMetadataService: mockPhoneMetadataService)
        sut.errorDelegate = mockErrorDelegate
        sut.validationDelegate = mockValidationDelegate
        sut.stepDelegate = mockStepDelegate
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

    func test_UpdateCollectedData_PhoneData__WithValidPhoneData_ShouldUpdateMobileNumber() {
        // When
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertNil(sut.otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
    }

    func test_UpdateCollectedData_OtpData__WithValidOtp_ShouldUpdateOtpCode() {
        // When
        sut.updateCollectedData(collectableData: .otpData(otpCode: otpCode))

        // Then
        XCTAssertNil(sut.mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.otpCode, otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
    }

    func test_UpdateCollectedData_PhoneData__WithInvalidPhoneData_ShouldReturnValidationError() {
        // Given
        let expectedErrorKey = "INVALID_DATA"
        let expectedError = PrimerError.invalidValue(key: expectedErrorKey, value: nil, userInfo: nil, diagnosticsId: "")
        mockPhoneMetadataService.resultToReturn = .failure(expectedError)

        // When
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertNil(sut.otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
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

    func test_UpdateCollectedData_PhoneData__WithInvalidPhoneDataAndSpecificError_ShouldReturnExpectedValidationError() {
        // Given
        let expectedError = PrimerValidationError.invalidPhoneNumber(
            message: "EXPECTED_ERROR_MESSAGE",
            userInfo: [:],
            diagnosticsId: ""
        )
        mockPhoneMetadataService.resultToReturn = .success((.invalid(errors: [expectedError]), nil, nil))

        // When
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertNil(sut.otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
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

    func test_UpdateCollectedData_PhoneData__WithValidPhoneData_ShouldSucceedValidation() {
        // Given
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertEqual(sut.countryCode, countryCode)
        XCTAssertNil(sut.otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .valid = mockValidationDelegate.validationsReceived {
            // Validation status is valid, no further assertions needed
        } else {
            XCTFail(
                "Expected validation status to be .valid, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_UpdateCollectedData_OtpData__WithEmptyOtp_ShouldReturnValidationError() {
        // Given
        let expectedErrorMessage = "OTP is not valid."

        // When
        sut.updateCollectedData(collectableData: .otpData(otpCode: ""))

        // Then
        XCTAssertNil(sut.mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.otpCode, "")
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .invalid(let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertEqual(errors.count, 1)
            guard let primerValidationError = errors.first else {
                XCTFail("Expected error to be of type PrimerValidationError, but got \(String(describing: errors.first))")
                return
            }

            switch primerValidationError {
            case .invalidOTPCode(let message, _, _):
                XCTAssertEqual(message, expectedErrorMessage)
            default:
                XCTFail("primerError should be of type invalidOTPCode")
            }
        } else {
            XCTFail(
                "Expected validation status to be .invalid with errors, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_UpdateCollectedData_OtpData__WithValidOtp_ShouldSucceedValidation() {
        // When
        sut.updateCollectedData(collectableData: .otpData(otpCode: otpCode))

        // Then
        XCTAssertNil(sut.mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.otpCode, otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.linkToken)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .valid = mockValidationDelegate.validationsReceived {
            // Validation status is valid, no further assertions needed
        } else {
            XCTFail(
                "Expected validation status to be .valid, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_Submit_CollectPhoneData__WithMissingMobileNumber_ShouldReturnError() {
        // Given
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

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

    func test_Submit_CollectPhoneData__WithMissingCountryCode_ShouldReturnError() {
        // Given
        sut.mobileNumber = mobileNumber
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

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

    func test_Submit_CollectPhoneData__WithMissingLinkToken_ShouldReturnError() {
        // Given
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "linkToken")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_CollectPhoneData__WithUninitializedSDK_ShouldReturnError() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        XCTAssertEqual(primerError.errorId, expectedError.errorId)
    }

    func test_Submit_CollectPhoneData__WhenSendLinkOTPRequestFailsWithError_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

        mockNolPay.sendLinkOTPResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .nolError(_, let message, _, _):
            XCTAssertTrue(message == expectedErrorDescription)
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectPhoneData__WhenSendLinkOTPRequestFails_ShouldReturnUnknownError() {
        // Given
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

        mockNolPay.sendLinkOTPResult = .success(false)
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .nolError(let code, let message, _, _):
            XCTAssertTrue(code == "unknown")
            XCTAssertTrue(message == "Sending of OTP SMS failed from unknown reason")
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectPhoneData__WhenSendLinkOTPSucceeds_ShouldProceedToNextStep() {
        // Given
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectPhoneData(cardNumber: cardNumber)

        mockNolPay.sendLinkOTPResult = .success(true)
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        XCTAssertNil(mockErrorDelegate.errorReceived)
        let expectedStep = String(describing: NolPayLinkCardStep.collectOtpData(phoneNumber: "\(countryCode) \(mobileNumber)"))
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep)
    }

    func test_Submit_CollectOtpData__WithMissingOtpCode_ShouldReturnError() {
        // Given
        sut.nextDataStep = .collectOtpData(phoneNumber: mobileNumber)

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "otpCode")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_CollectOtpData__WithMissingLinkToken_ShouldReturnError() {
        // Given
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.otpCode = otpCode

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "linkToken")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_CollectOtpData__WithUninitializedSDK_ShouldReturnError() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.otpCode = otpCode
        sut.linkToken = linkToken

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        XCTAssertEqual(primerError.plainDescription, expectedError.plainDescription)
    }

    func test_Submit_CollectOtpData__WhenLinkCardRequestFailsWithError_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        sut.otpCode = otpCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectOtpData(phoneNumber: mobileNumber)

        mockNolPay.linkCardResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .nolError(_, let message, _, _):
            XCTAssertTrue(message == expectedErrorDescription)
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectOtpData__WhenLinkCardRequestFails_ShouldReturnUnknownError() {
        // Given
        sut.otpCode = otpCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectOtpData(phoneNumber: mobileNumber)

        mockNolPay.linkCardResult = .success(false)
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .nolError(let code, let message, _, _):
            XCTAssertTrue(code == "unknown")
            XCTAssertTrue(message == "Linking of the card failed failed from unknown reason")
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectOtpData__WhenLinkCardSucceeds_ShouldProceedToNextStep() {
        // Given
        sut.otpCode = otpCode
        sut.linkToken = linkToken
        sut.nextDataStep = .collectOtpData(phoneNumber: mobileNumber)

        mockNolPay.linkCardResult = .success(true)
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        XCTAssertNil(mockErrorDelegate.errorReceived)
        let expectedStep = String(describing: NolPayLinkCardStep.cardLinked)
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep)
    }

    func test_Submit_CollectTagData__WithUninitializedSDK_ShouldReturnError() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        sut.nextDataStep = .collectTagData

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        XCTAssertEqual(primerError.plainDescription, expectedError.plainDescription)
    }

    func test_Submit_CollectTagData__WhenScanNFCCardFails_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        sut.nextDataStep = .collectTagData

        mockNolPay.scanNFCCardResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .nolError(_, let message, _, _):
            XCTAssertTrue(message == expectedErrorDescription)
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectTagData__WhenMakeLinkingTokenFails_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        sut.nextDataStep = .collectTagData

        mockNolPay.scanNFCCardResult = .success(cardNumber)
        mockNolPay.makeLinkingTokenResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .nolError(_, let message, _, _):
            XCTAssertTrue(message == expectedErrorDescription)
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectTagData__WhenMakeLinkingTokenSucceeds_ShouldProceedToNextStep() {
        // Given
        sut.nextDataStep = .collectTagData

        mockNolPay.scanNFCCardResult = .success(cardNumber)
        mockNolPay.makeLinkingTokenResult = .success(linkToken)
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        XCTAssertNil(mockErrorDelegate.errorReceived)
        let expectedStep = String(describing: NolPayLinkCardStep.collectPhoneData(cardNumber: cardNumber))
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep)
        XCTAssertEqual(sut.cardNumber, cardNumber)
    }

    func test_UpdateCollectedData_PhoneData__WithValidPhoneData_ShouldSetNextStepToCollectPhoneData() {
        // Given
        let phoneData = NolPayLinkCollectableData.phoneData(mobileNumber: mobileNumber)

        // When
        sut.updateCollectedData(collectableData: phoneData)

        // Then
        let expectedStep = String(describing: NolPayLinkCardStep.collectPhoneData(cardNumber: ""))
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep, "The nextDataStep should be .collectPhoneData after updating with phoneData")
    }

    func test_UpdateCollectedData_OtpData__WithValidOtp_ShouldSetNextStepToCollectOtpData() {
        // Given
        let otpData = NolPayLinkCollectableData.otpData(otpCode: otpCode)

        // When
        sut.updateCollectedData(collectableData: otpData)

        // Then
        let expectedStep = String(describing: NolPayLinkCardStep.collectOtpData(phoneNumber: ""))
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep, "The nextDataStep should be .collectOtpData after updating with otpData")
    }

    func test_Start_WithInvalidAppID_ShouldReturnError() {
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

    func test_Start_WithNoClientToken_ShouldReturnError() {
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

    func test_Start_WhenSDKFailsWithError() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        let expectedErrorCode = "EXPECTED_ERROR_CODE"
        mockApiClient.fetchNolSdkSecretResult = {
            exp.fulfill()
            return .failure(PrimerError.nolError(code: expectedErrorCode, message: "", userInfo: nil, diagnosticsId: ""))
        }

        // When
        sut.start()

        // Then
        wait(for: [exp], timeout: 5.0)
    }

    func test_Start_WhenSDKStartsSuccessfully() {
        // Given
        let exp = expectation(description: "Wait for start to complete")
        mockApiClient.fetchNolSdkSecretResult = {
            exp.fulfill()
            return .success(Response.Body.NolPay.NolPaySecretDataResponse(sdkSecret: ""))
        }

        // When
        sut.start()

        // Then
        wait(for: [exp], timeout: 5.0)
    }
}
#endif
