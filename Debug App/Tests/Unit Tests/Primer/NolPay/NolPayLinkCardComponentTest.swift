//
//  NolPayLinkCardComponentTest.swift
//  Debug App Tests
//
//  Created by Boris on 9.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
@testable import PrimerSDK
import PrimerNolPaySDK

final class NolPayLinkCardComponentTest: XCTestCase {
    
    var sut: NolPayLinkCardComponent!
    
    override func setUp() {
        super.setUp()
        sut = NolPayLinkCardComponent(isDebug: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    
    func testUpdateCollectedData_PhoneData_Success() {
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        XCTAssertEqual(sut.mobileNumber, "1234567890")
        XCTAssertEqual(sut.phoneCountryDiallingCode, "+1")
    }
    
    func testUpdateCollectedData_OTPData_Success() {
        sut.updateCollectedData(collectableData: .otpData(otpCode: "1234"))
        XCTAssertEqual(sut.otpCode, "1234")
    }
    
    func testValidateData_ValidPhoneData() {
        let validations = sut.validateData(for: .phoneData(mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        XCTAssertTrue(validations.isEmpty)
    }
    
    func testValidateData_ValidOTPData() {
        let validations = sut.validateData(for: .otpData(otpCode: "123456"))
        XCTAssertTrue(validations.isEmpty)
    }
    
    func testValidateData_InvalidPhoneNumber() {
        let validations = sut.validateData(for: .phoneData(mobileNumber: "abc", phoneCountryDiallingCode: "+1"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidPhoneNumber = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidPhoneNumber error")
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
            
    func testValidateData_InvalidPhoneData() {
        let result = sut.validateData(for: .phoneData(mobileNumber: "invalidNumber", phoneCountryDiallingCode: "invalidCode"))
        
        // Check for the specific error type and description
        let invalidPhoneNumberError = result.first { (error) -> Bool in
            if case .invalidPhoneNumber(let message, _, _) = error, message == "Phone number is not valid." {
                return true
            }
            return false
        }
        XCTAssertNotNil(invalidPhoneNumberError)
        
        let invalidPhoneNumberCountryCodeError = result.first { (error) -> Bool in
            if case .invalidPhoneNumberCountryCode(let message, _, _) = error, message == "Country code is not valid." {
                return true
            }
            return false
        }
        XCTAssertNotNil(invalidPhoneNumberCountryCodeError)
    }
    
    func testValidateData_InvalidOtpData() {
        let result = sut.validateData(for: .otpData(otpCode: "invalidOTP"))
        
        // Check for the specific error type and description
        let invalidOTPError = result.first { (error) -> Bool in
            if case .invalidOTPCode(let message, _, _) = error, message == "OTP is not valid." {
                return true
            }
            return false
        }
        XCTAssertNotNil(invalidOTPError)
    }
    
    
    func testValidateData_InvalidCountryCode() {
        let validations = sut.validateData(for: .phoneData(mobileNumber: "1234567890", phoneCountryDiallingCode: "1234"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidPhoneNumberCountryCode = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidPhoneNumberCountryCode error")
        }
    }


    func testUpdateCollectedData_ValidationDelegateCalled() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: "abc", phoneCountryDiallingCode: "+1"))
        XCTAssertTrue(mockValidationDelegate.wasValidatedCalled)
    }

    func testValidateData_EmptyPhoneNumber() {
        let validations = sut.validateData(for: .phoneData(mobileNumber: "", phoneCountryDiallingCode: "+1"))
        XCTAssertEqual(validations.count, 1)
        if case .invalidPhoneNumber = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidPhoneNumber error")
        }
    }

    func testValidateData_EmptyOTP() {
        let validations = sut.validateData(for: .otpData(otpCode: ""))
        XCTAssertEqual(validations.count, 1)
        if case .invalidOTPCode = validations.first! {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected invalidOTPCode error")
        }
    }
    
    func testSubmit_CollectPhoneData_MobileNumberNil() {
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }

    func testSubmit_CollectPhoneData_CountryCodeNil() {
        sut.mobileNumber = "1234567890"
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }

    func testSubmit_CollectOtpData_OtpCodeNil() {
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.submit()
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }

    func testStart_InvalidAppID() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.start()
        XCTAssertNotNil(mockErrorDelegate.errorReceived)
    }
    
    func testUpdateCollectedData_InvalidPhoneData() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: "invalidPhoneNumber", phoneCountryDiallingCode: "invalidCountryCode"))
        XCTAssertEqual(mockValidationDelegate.validationsReceived?.count, 2)
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-phone-number" }) == true)
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-phone-number-country-code" }) == true)
    }

    func testUpdateCollectedData_InvalidOTPCode() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        sut.updateCollectedData(collectableData: .otpData(otpCode: "invalidOTP"))
        XCTAssertEqual(mockValidationDelegate.validationsReceived?.count, 1)
        XCTAssertTrue(mockValidationDelegate.validationsReceived?.contains(where: { $0.errorId == "invalid-otp-code" }) == true)
    }

    func testUpdateCollectedData_ValidPhoneData() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        // Assuming "1234567890" and "+1" are valid for phone number and country code respectively.
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: "1234567890", phoneCountryDiallingCode: "+1"))
        XCTAssert(mockValidationDelegate.validationsReceived?.isEmpty == true)
    }

    func testUpdateCollectedData_ValidOTPCode() {
        let mockValidationDelegate = MockValidationDelegate()
        sut.validationDelegate = mockValidationDelegate
        // Assuming "123456" is a valid OTP code.
        sut.updateCollectedData(collectableData: .otpData(otpCode: "123456"))
        XCTAssert(mockValidationDelegate.validationsReceived?.isEmpty == true)
    }
    
    func testSubmit_CollectPhoneData_NoMobileNumber() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")
        sut.phoneCountryDiallingCode = "+1"
        sut.submit()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }

    func testSubmit_CollectPhoneData_NoCountryCode() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.nextDataStep = .collectPhoneData(cardNumber: "1234")
        sut.mobileNumber = "1234567890"
        sut.submit()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }

    func testSubmit_CollectOtpData_NoOTP() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.linkToken = "linkToken123"
        sut.submit()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }

    func testSubmit_CollectOtpData_NoLinkToken() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.nextDataStep = .collectOtpData(phoneNumber: "")
        sut.otpCode = "123456"
        sut.submit()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }

    func testStart_NoNolAppID() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        // Assuming PrimerAPIConfiguration.current?.paymentMethods? does not contain valid Nol AppID
        sut.start()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }

    func testStart_NoClientToken() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        // Assuming PrimerAPIConfigurationModule.decodedJWTToken is nil
        sut.start()
        XCTAssertTrue(mockErrorDelegate.errorReceived is PrimerError)
    }
}
#endif
