//
//  NolPayUnlinkCardComponentTest.swift
//  Debug App Tests
//
//  Created by Boris on 10.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

final class NolPayUnlinkCardComponentTest: XCTestCase {
    var sut: NolPayUnlinkCardComponent!
    var mockErrorDelegate: MockErrorDelegate!
    var mockValidationDelegate: MockValidationDelegate!
    var mockStepDelegate: MockStepDelegate!
    var mockPhoneMetadataService: MockPhoneMetadataService!
    var mockNolPayTokenizationViewModel: MockNolPayTokenizationViewModel!
    var mockNolPay: MockPrimerNolPay!

    let mobileNumber = "+111123123123123"
    let countryCode = "+1"
    let otpCode = "123456"
    let cardNumber = "1234567890123456"
    let unlinkToken = "UNLINK_TOKEN"
    let expiredTime = "EXPIRED_TIME"

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

        sut = NolPayUnlinkCardComponent(phoneMetadataService: mockPhoneMetadataService)
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

    func test_UpdateCollectedData_CardAndPhoneData__WithValidData_ShouldUpdateProperties() {
        // When
        sut.updateCollectedData(collectableData: .cardAndPhoneData(
            nolPaymentCard: .init(cardNumber: cardNumber, expiredTime: expiredTime),
            mobileNumber: mobileNumber
        ))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertNil(sut.otpCode)
        XCTAssertEqual(sut.cardNumber, cardNumber)
        XCTAssertNil(sut.unlinkToken)
    }

    func test_UpdateCollectedData_OtpData__WithValidOtp_ShouldUpdateProperties() {
        // When
        sut.updateCollectedData(collectableData: .otpData(otpCode: otpCode))

        // Then
        XCTAssertNil(sut.mobileNumber)
        XCTAssertNil(sut.countryCode)
        XCTAssertEqual(sut.otpCode, otpCode)
        XCTAssertNil(sut.cardNumber)
        XCTAssertNil(sut.unlinkToken)
    }

    func test_UpdateCollectedData_CardAndPhoneData__WithInvalidCardNumberAndValidPhoneNumber_ShouldReturnCardNumberError() {
        // Given
        let expectedError = PrimerValidationError.invalidCardnumber(
            message: "Card number is not valid.",
            userInfo: nil,
            diagnosticsId: ""
        )
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: .cardAndPhoneData(
            nolPaymentCard: .init(cardNumber: "", expiredTime: ""),
            mobileNumber: mobileNumber
        ))

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

    func test_UpdateCollectedData_CardAndPhoneData__WithInvalidCardNumberAndPhoneNumber_ShouldReturnBothErrors() {
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
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: .init(cardNumber: "", expiredTime: ""), mobileNumber: ""))

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

    func test_UpdateCollectedData_CardAndPhoneData__WhenPhoneMetadataServiceFails_ShouldReturnError() {
        // Given
        let expectedErrorKey = "INVALID_DATA"
        let expectedError = PrimerError.invalidValue(key: expectedErrorKey, value: nil, userInfo: nil, diagnosticsId: "")
        mockPhoneMetadataService.resultToReturn = .failure(expectedError)

        // When
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: .init(cardNumber: "", expiredTime: ""), mobileNumber: ""))

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

    func test_UpdateCollectedData_CardAndPhoneData__WithValidCardAndPhoneData_ShouldReturnValidStatus() {
        // Given
        mockPhoneMetadataService.resultToReturn = .success((.valid, countryCode, mobileNumber))

        // When
        sut.updateCollectedData(collectableData: .cardAndPhoneData(
            nolPaymentCard: .init(cardNumber: cardNumber, expiredTime: expiredTime),
            mobileNumber: mobileNumber
        ))

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
        XCTAssertNil(sut.unlinkToken)
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
        XCTAssertNil(sut.unlinkToken)
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
        if case .valid = mockValidationDelegate.validationsReceived {
            // Validation status is valid, no further assertions needed
        } else {
            XCTFail(
                "Expected validation status to be .valid, but got \(String(describing: mockValidationDelegate.validationsReceived))"
            )
        }
    }

    func test_Submit_CollectCardAndPhoneData__WithMissingMobileNumber_ShouldReturnError() {
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
            XCTAssertTrue(key == "mobileNumber")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_CollectCardAndPhoneData__WithMissingCountryCode_ShouldReturnError() {
        // Given
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

    func test_Submit_CollectCardAndPhoneData__WithMissingCardNumber_ShouldReturnError() {
        // Given
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

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "cardNumber")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_CollectCardAndPhoneData__WithUninitializedSDK_ShouldReturnError() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.cardNumber = cardNumber
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

    func test_Submit_CollectCardAndPhoneData__WhenSendUnlinkOTPRequestFailsWithError_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.cardNumber = cardNumber
        sut.nextDataStep = .collectCardAndPhoneData

        mockNolPay.sendUnlinkOTPResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
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

    func test_Submit_CollectCardAndPhoneData__WhenSendUnlinkOTPSucceeds_ShouldProceedToNextStep() {
        // Given
        sut.mobileNumber = mobileNumber
        sut.countryCode = countryCode
        sut.cardNumber = cardNumber
        sut.nextDataStep = .collectCardAndPhoneData

        mockNolPay.sendUnlinkOTPResult = .success((cardNumber, unlinkToken))
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        XCTAssertNil(mockErrorDelegate.errorReceived)
        let expectedStep = String(describing: NolPayUnlinkDataStep.collectOtpData)
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep)
    }

    func test_Submit_CollectOtpData__WithNoOtpCode_ShouldReturnError() {
        // Given
        sut.nextDataStep = .collectOtpData

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

    func test_Submit_CollectOtpData__WithNoLinkToken_ShouldReturnError() {
        // Given
        sut.otpCode = otpCode
        sut.nextDataStep = .collectOtpData

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        switch primerError {
        case .invalidValue(let key, _, _, _):
            XCTAssertTrue(key == "unlinkToken")
        default:
            XCTFail("primerError should be of type invalidSetting")
        }
    }

    func test_Submit_CollectOtpData__WithNoCardNumber_ShouldReturnError() {
        // Given
        sut.otpCode = otpCode
        sut.unlinkToken = unlinkToken
        sut.nextDataStep = .collectOtpData

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

    func test_Submit_CollectOtpData__WhenUnlinkCardRequestFailsWithError_ShouldReturnExpectedError() {
        // Given
        let expectedErrorDescription = "ERROR_DESCRIPTION"
        sut.otpCode = otpCode
        sut.unlinkToken = unlinkToken
        sut.cardNumber = cardNumber
        sut.nextDataStep = .collectOtpData

        // When
        sut.submit()

        mockNolPay.unlinkCardResult = .failure(PrimerNolPayError(description: expectedErrorDescription))
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

    func test_Submit_CollectOtpData__WhenUnlinkCardRequestFails_ShouldReturnUnknownError() {
        // Given
        sut.otpCode = otpCode
        sut.unlinkToken = unlinkToken
        sut.cardNumber = cardNumber
        sut.nextDataStep = .collectOtpData

        mockNolPay.unlinkCardResult = .success(false)
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
            XCTAssertTrue(message == "Unlinking failed from unknown reason")
        default:
            XCTFail("primerError should be of type nolError")
        }
    }

    func test_Submit_CollectOtpData__WhenUnlinkCardSucceeds_ShouldProceedToNextStep() {
        // Given
        sut.otpCode = otpCode
        sut.unlinkToken = unlinkToken
        sut.cardNumber = cardNumber
        sut.nextDataStep = .collectOtpData

        mockNolPay.unlinkCardResult = .success(true)
        sut.nolPay = mockNolPay

        // When
        sut.submit()

        // Then
        XCTAssertNil(mockErrorDelegate.errorReceived)
        let expectedStep = String(describing: NolPayUnlinkDataStep.cardUnlinked)
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep)
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
