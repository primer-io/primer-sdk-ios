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
    var mockPhoneMetadataService: MockPhoneMetadataService!
    var mockValidationDelegate: MockValidationDelegate!

    override func setUp() {
        super.setUp()
        mockPhoneMetadataService = MockPhoneMetadataService()
        sut = NolPayUnlinkCardComponent(phoneMetadataService: mockPhoneMetadataService)

        mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testValidationTriggeredWhenUpdatingData() {
        // Provide data to component
        sut.updateCollectedData(collectableData: .cardAndPhoneData(
            nolPaymentCard: PrimerNolPaymentCard(cardNumber: "", expiredTime: ""),
            mobileNumber: ""
        ))

        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled, "Validation was not triggered when updating collected data.")
    }

    func testInvalidPhoneNumberValidationErrorReceived() {
        mockPhoneMetadataService.resultToReturn = .success((
            .invalid(errors: [PrimerValidationError.invalidPhoneNumber(message: "", userInfo: nil, diagnosticsId: "")]),
            nil,
            nil
        ))

        // Provide data with invalid phone number to component
        sut.updateCollectedData(collectableData: .cardAndPhoneData(
            nolPaymentCard: PrimerNolPaymentCard(cardNumber: "", expiredTime: ""),
            mobileNumber: "invalidNumber"
        ))

        XCTAssertNotNil(mockValidationDelegate.validationsReceived, "No validations received.")
        if case .invalid(errors: let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertTrue(errors.contains(where: { $0.errorId == "invalid-phone-number" }) == true, "Expected invalid phone number validation error.")
        } else {
            XCTFail("Expected validation error")
        }
    }

    func testValidDataDoesNotTriggerValidationErrors() {
        mockPhoneMetadataService.resultToReturn = .success((.valid, "", ""))

        // Provide valid data to component
        sut.updateCollectedData(collectableData: .cardAndPhoneData(
            nolPaymentCard: PrimerNolPaymentCard(cardNumber: "1234567890", expiredTime: "12/25"),
            mobileNumber: "+1121234567890"
        ))

        XCTAssertNotNil(mockValidationDelegate.validationsReceived, "No validations received.")
        if case .valid = mockValidationDelegate.validationsReceived {
            XCTAssert(true, "Validation result is valid")
        } else {
            XCTFail("Expected validation error")
        }
    }

    func testUpdateCollectedData_CardAndPhoneData_Success() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "+1234567890"))
        XCTAssertEqual(sut.cardNumber, "1234567890123456")
        XCTAssertEqual(sut.mobileNumber, "+1234567890")
    }

    func testUpdateCollectedData_OTPData_Success() {
        sut.updateCollectedData(collectableData: .otpData(otpCode: "1234"))
        XCTAssertEqual(sut.otpCode, "1234")
    }

    func testValidateData_ValidOTPData() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate

        sut.validateData(for: .otpData(otpCode: "123456"))
        if case .valid = mockValidationDelegate.validationsReceived {
            XCTAssertTrue(true, "OTP is valid")
        } else {
            XCTFail("OTP is invalid")
        }
    }

    func testValidateData_InvalidCardNumber() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "abc", expiredTime: "12/25")
        mockPhoneMetadataService.resultToReturn = .success((
            .invalid(errors: [PrimerValidationError.invalidCardnumber(message: "", userInfo: nil, diagnosticsId: "")]),
            "",
            ""
        ))

        sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "+1234567890"))

        if case .invalid(errors: let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertTrue(errors.contains(where: { $0.errorId == "invalid-card-number" }), "Unexpected validation errors received.")
        } else {
            XCTFail("Expected validation error")
        }
    }

    func testValidateData_InvalidPhoneNumber() {
        mockPhoneMetadataService.resultToReturn = .success((
            .invalid(errors: [PrimerValidationError.invalidPhoneNumber(message: "", userInfo: nil, diagnosticsId: "")]),
            "",
            ""
        ))

        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        sut.cardNumber = dummyCard.cardNumber
        sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "abc"))

        if case .invalid(errors: let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertTrue(errors.contains(where: { $0.errorId == "invalid-phone-number" }), "Unexpected validation errors received.")
        } else {
            XCTFail("Expected validation error")
        }
    }

    // MARK: - Tests for submit() function

    func testSubmit_CollectCardAndPhoneData_MobileNumberNil() {
        sut.nextDataStep = .collectCardAndPhoneData
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }

    func testSubmit_CollectOTPData_OtpCodeNil() {
        sut.nextDataStep = .collectOtpData
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }

    // MARK: - Tests for start() function

    func testUpdateCollectedData_EmptyOTPCode() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .otpData(otpCode: ""))

        if case .invalid(errors: let errors) = mockValidationDelegate.validationsReceived {
            XCTAssertTrue(errors.contains(where: { $0.errorId == "invalid-otp-code" }), "Expected empty OTP code validation error.")
        } else {
            XCTFail("Expected validation error")
        }
    }

    func testSubmit_NoDataForOTP() {
        sut.nextDataStep = .collectOtpData
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.otpCode = nil
        sut.submit()

        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when there's no data for OTP.")
    }

    func testSubmit_CollectCardAndPhoneData_CardNumberNil() {
        sut.nextDataStep = .collectCardAndPhoneData
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()

        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when there's no card number.")
    }

    func testUpdateCollectedDataWithCardAndPhoneData() {
        // Given
        let mockCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "") // Replace with the correct initializer
        let cardAndPhoneData = NolPayUnlinkCollectableData.cardAndPhoneData(nolPaymentCard: mockCard, mobileNumber: "+1234567890")

        // When
        sut.updateCollectedData(collectableData: cardAndPhoneData)

        // Then
        let expectedStep = String(describing: NolPayUnlinkDataStep.collectCardAndPhoneData)
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep, "The nextDataStep should be .collectCardAndPhoneData after updating with cardAndPhoneData")
    }

    func testUpdateCollectedDataWithOtpData() {
        // Given
        let otpData = NolPayUnlinkCollectableData.otpData(otpCode: "123456")

        // When
        sut.updateCollectedData(collectableData: otpData)

        // Then
        let expectedStep = String(describing: NolPayUnlinkDataStep.collectOtpData)
        let actualStep = String(describing: sut.nextDataStep)
        XCTAssertEqual(actualStep, expectedStep, "The nextDataStep should be .collectOtpData after updating with otpData")
    }
}
#endif
