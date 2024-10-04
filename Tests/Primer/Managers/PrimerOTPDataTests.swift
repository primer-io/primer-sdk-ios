//
//  PrimerOTPDataTests.swift
//  PrimerSDK
//
//  Created by Boris on 1.10.24..
//

import XCTest
@testable import PrimerSDK

class PrimerOTPDataTests: XCTestCase {

    // Test initialization with OTP
    func test_initialization_with_otp() {
        let otp = "123456"
        let otpData = PrimerOTPData(otp: otp)
        XCTAssertEqual(otpData.otp, otp, "OTP should be initialized correctly")
    }

    // Test that onDataDidChange is called when OTP is changed
    func test_onDataDidChange_called_when_otp_changes() {
        let otpData = PrimerOTPData(otp: "123456")
        let exp = expectation(description: "onDataDidChange should be called")

        otpData.onDataDidChange = {
            exp.fulfill()
        }

        otpData.otp = "654321" // Change OTP to trigger onDataDidChange

        wait(for: [exp], timeout: 1.0)
    }

    // Test that onDataDidChange is not nil
    func test_onDataDidChange_is_not_nil_after_setting() {
        let otpData = PrimerOTPData(otp: "123456")
        otpData.onDataDidChange = {}

        XCTAssertNotNil(otpData.onDataDidChange, "onDataDidChange should not be nil after setting")
    }

    // Test that onDataDidChange is nil by default
    func test_onDataDidChange_is_nil_by_default() {
        let otpData = PrimerOTPData(otp: "123456")
        XCTAssertNil(otpData.onDataDidChange, "onDataDidChange should be nil by default")
    }
}
