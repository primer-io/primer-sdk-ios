//
//  NolPayLinkCardComponentTest.swift
//  Debug App Tests
//
//  Created by Boris on 9.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

final class NolPayLinkCardComponentTest: XCTestCase {
    var sut: NolPayLinkCardComponent!
    var mockErrorDelegate: MockErrorDelegate!
    var mockPhoneMetadataService: MockPhoneMetadataService!

    override func setUp() {
        super.setUp()

        mockPhoneMetadataService = MockPhoneMetadataService()
        sut = NolPayLinkCardComponent(phoneMetadataService: mockPhoneMetadataService)
        mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
    }

    override func tearDown() {
        sut = nil
        mockErrorDelegate = nil
        super.tearDown()
    }

    func test_UpdateCollectedData_WhenPhoneDataIsProvided_ThenMobileNumberIsUpdated() {
        // Given
        let mobileNumber = "+111123123123123"

        // When
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: mobileNumber))

        // Then
        XCTAssertEqual(sut.mobileNumber, mobileNumber)
    }

    func test_UpdateCollectedData_WhenOtpDataIsProvided_ThenOtpCodeIsUpdated() {
        // Given
        let otpCode = "123456"

        // When
        sut.updateCollectedData(collectableData: .otpData(otpCode: otpCode))

        // Then
        XCTAssertEqual(sut.otpCode, otpCode)
    }

    func test_Submit_WhenCollectPhoneDataAndMobileNumberIsNil_ThenErrorIsReturned() {
        // Given
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")

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

    func test_Submit_WhenCollectPhoneDataAndCountryCodeIsNil_ThenErrorIsReturned() {
        // Given
        sut.mobileNumber = "1234567890"
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")

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

    func test_Submit_WhenCollectPhoneDataAndNoMobileNumber_ThenErrorIsReturned() {
        // Given
        sut.countryCode = "+111"
        sut.nextDataStep = .collectPhoneData(cardNumber: "12341234")

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

    func test_Submit_WhenCollectPhoneDataAndNoLinkToken_ThenErrorIsReturned() {
        // Given
        sut.mobileNumber = "1234567890"
        sut.countryCode = "+111"
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")

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

    func test_Submit_WhenCollectPhoneDataAndSDKIsNotInitialized_ThenErrorIsReturned() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        sut.mobileNumber = "1234567890"
        sut.countryCode = "+111"
        sut.linkToken = "linkToken123"
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        XCTAssertEqual(primerError.errorId, expectedError.errorId)
    }

    func test_Submit_WhenCollectOtpDataAndOtpCodeIsNil_ThenErrorIsReturned() {
        // Given
        sut.nextDataStep = .collectOtpData(phoneNumber: "")

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

    func test_Submit_WhenCollectOtpDataAndNoOtpCode_ThenErrorIsReturned() {
        // Given
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.linkToken = "linkToken123"

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

    func test_Submit_WhenCollectOtpDataAndNoLinkToken_ThenErrorIsReturned() {
        // Given
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.otpCode = "123456"

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

    func test_Submit_WhenCollectOtpDataAndSDKIsNotInitialized_ThenErrorIsReturned() {
        // Given
        let expectedError = PrimerError.nolSdkInitError(userInfo: nil, diagnosticsId: "")
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.otpCode = "123456"
        sut.linkToken = "linkToken123"

        // When
        sut.submit()

        // Then
        guard let primerError = mockErrorDelegate.errorReceived as? PrimerError else {
            XCTFail("Error should be of type PrimerError")
            return
        }

        XCTAssertEqual(primerError.plainDescription, expectedError.plainDescription)
    }

    func test_Submit_WhenCollectTagDataAndSDKIsNotInitialized_ThenErrorIsReturned() {
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

    func test_UpdateCollectedData_WhenPhoneDataIsProvided_ThenNextStepIsCollectPhoneData() {
        // Given
        let phoneData = NolPayLinkCollectableData.phoneData(mobileNumber: "1234567890")

        // When
        sut.updateCollectedData(collectableData: phoneData)

        // Then
        let expectedStep = String(describing: NolPayLinkCardStep.collectPhoneData(cardNumber: ""))
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep, "The nextDataStep should be .collectPhoneData after updating with phoneData")
    }

    func test_UpdateCollectedData_WhenOtpDataIsProvided_ThenNextStepIsCollectOtpData() {
        // Given
        let otpData = NolPayLinkCollectableData.otpData(otpCode: "123456")

        // When
        sut.updateCollectedData(collectableData: otpData)

        // Then
        let expectedStep = String(describing: NolPayLinkCardStep.collectOtpData(phoneNumber: ""))
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep, "The nextDataStep should be .collectOtpData after updating with otpData")
    }

    func test_Start_WhenAppIDIsInvalid_ThenErrorIsReturned() {
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
        let paymentMethod = Mocks.PaymentMethods.nolPaymentMethod
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])
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
