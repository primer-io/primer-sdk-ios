//
//  NolPayUnlinkCardComponentTest.swift
//  Debug App Tests
//
//  Created by Boris on 10.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK

final class NolPayUnlinkCardComponentTest: XCTestCase {
    var sut: NolPayUnlinkCardComponent!
    
    override func setUp() {
        super.setUp()
        sut = NolPayUnlinkCardComponent(isDebug: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testValidationTriggeredWhenUpdatingData() {
        let sut = NolPayUnlinkCardComponent(isDebug: true)
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // Provide data to component
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: PrimerNolPaymentCard(cardNumber: "", expiredTime: ""), mobileNumber: "", phoneCountryDiallingCode: ""))
        
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled, "Validation was not triggered when updating collected data.")
    }
    
    func testInvalidPhoneNumberValidationErrorReceived() {
        let sut = NolPayUnlinkCardComponent(isDebug: true)
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // Provide data with invalid phone number to component
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: PrimerNolPaymentCard(cardNumber: "", expiredTime: ""), mobileNumber: "invalidNumber", phoneCountryDiallingCode: "..."))
        
        XCTAssertNotNil(mockValidationDelegate.validationsReceived, "No validations received.")
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-phone-number" }) == true, "Expected invalid phone number validation error.")
    }
    
    func testValidDataDoesNotTriggerValidationErrors() {
        let sut = NolPayUnlinkCardComponent(isDebug: true)
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        
        // Provide valid data to component
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: PrimerNolPaymentCard(cardNumber: "1234567890", expiredTime: "12/25"), mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        
        XCTAssertNotNil(mockValidationDelegate.validationsReceived, "No validations received.")
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.isEmpty == true, "Unexpected validation errors received.")
    }
    
    func testUpdateCollectedData_CardAndPhoneData_Success() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        XCTAssertEqual(sut.cardNumber, "1234567890123456")
        XCTAssertEqual(sut.mobileNumber, "1234567890")
        XCTAssertEqual(sut.phoneCountryDiallingCode, "+1")
    }
    
    func testUpdateCollectedData_OTPData_Success() {
        sut.updateCollectedData(collectableData: .otpData(otpCode: "1234"))
        XCTAssertEqual(sut.otpCode, "1234")
    }
    
    func testValidateData_ValidCardAndPhoneData() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890", expiredTime: "12/25")
        sut.cardNumber = dummyCard.cardNumber
        let validations = sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: "+111"))
        XCTAssertTrue(validations.isEmpty)
    }
    
    func testValidateData_ValidOTPData() {
        let validations = sut.validateData(for: .otpData(otpCode: "123456"))
        XCTAssertTrue(validations.isEmpty)
    }
    
    func testValidateData_InvalidCardNumber() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "abc", expiredTime: "12/25")
        let validations = sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidCardnumber = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidCardnumber error")
        }
    }
    
    func testValidateData_InvalidPhoneNumber() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        sut.cardNumber = dummyCard.cardNumber
        let validations = sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "abc", phoneCountryDiallingCode: "+1"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidPhoneNumber = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidPhoneNumber error")
        }
    }
    
    func testValidateData_InvalidCountryCode() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        sut.cardNumber = dummyCard.cardNumber
        let validations = sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: "abc"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidPhoneNumberCountryCode = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidPhoneNumberCountryCode error")
        }
    }
    
    func testValidateData_InvalidOTP() {
        let validations = sut.validateData(for: .otpData(otpCode: "abc"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidOTPCode = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidOTPCode error")
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
    func testStart_NoNolAppID() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.start()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }
    
    func testUpdateCollectedData_EmptyCardNumber() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "", expiredTime: "12/25")
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-card-number" }) == true, "Expected empty card number validation error.")
    }
    
    func testUpdateCollectedData_EmptyOTPCode() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .otpData(otpCode: ""))
        
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-otp-code" }) == true, "Expected empty OTP code validation error.")
    }
        
    func testSubmit_NoDataForOTP() {
        sut.nextDataStep = .collectOtpData
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.otpCode = nil
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when there's no data for OTP.")
    }
    
    func testUpdateCollectedData_EmptyPhoneNumber() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "", phoneCountryDiallingCode: "+1"))
        
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-phone-number" }) == true, "Expected empty phone number validation error.")
    }
    
    func testUpdateCollectedData_EmptyCountryDiallingCode() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "1234567890123456", expiredTime: "12/25")
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: ""))
        
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-phone-number-country-code" }) == true, "Expected empty country dialling code validation error.")
    }
        
    func testValidateData_EmptyCardNumber() {
        let dummyCard = PrimerNolPaymentCard(cardNumber: "", expiredTime: "12/25")
        let validations = sut.validateData(for: .cardAndPhoneData(nolPaymentCard: dummyCard, mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        
        if case .invalidCardnumber = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidCardnumber error")
        }
    }
    
    func testSubmit_CollectCardAndPhoneData_CardNumberNil() {
        sut.nextDataStep = .collectCardAndPhoneData
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        
        XCTAssertNotNil(mockErrorDelegate.errorReceived, "Expected an error when there's no card number.")
    }
}
#endif
