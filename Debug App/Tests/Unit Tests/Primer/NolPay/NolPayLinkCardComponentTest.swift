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
        sut = NolPayLinkCardComponent()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    
    func testUpdateCollectedData_PhoneData_Success() {
        sut.updateCollectedData(collectableData: .phoneData(mobileNumber: "+111123123123123"))
        XCTAssertEqual(sut.mobileNumber, "+111123123123123")
    }
    
    func testUpdateCollectedData_OTPData_Success() {
        sut.updateCollectedData(collectableData: .otpData(otpCode: "123456"))
        XCTAssertEqual(sut.otpCode, "123456")
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
        
    func testSubmit_CollectPhoneData_NoMobileNumber() {
        let mockErrorDelegate = MockErrorDelegate()
        sut.errorDelegate = mockErrorDelegate
        sut.nextDataStep = .collectPhoneData(cardNumber: "12341234")
        sut.countryCode = "+111"
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
