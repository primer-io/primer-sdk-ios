//
//  PrimerHeadlessValidationTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 21/08/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class PrimerInputElementTests: XCTestCase {

    func test_validate_cardholderName() throws {
        let sut = PrimerInputElementType.cardholderName

        XCTAssertTrue(sut.validate(value: "Joe Bloggs", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "JoeBloggs", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "Joe Bloggs Jr.", detectedValueType: nil))

        let allTheLetters = CharacterSet.letters.union(.whitespaces).characters().reduce("", { $0 + "\($1)"})
        XCTAssertTrue(sut.validate(value: allTheLetters, detectedValueType: nil))

        // Test strings with numerics. Logic states these should fail
        XCTAssertFalse(sut.validate(value: "123", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "Joe Bloggs the 3rd", detectedValueType: nil))

        // Test non-string entry
        XCTAssertFalse(sut.validate(value: 123, detectedValueType: nil))
    }

    func test_validate_cardNumber() throws {
        let cardNumbers = Constants.testCardNumbers.values.flatMap { $0 }
        let sut = PrimerInputElementType.cardNumber

        // Use existing test cards to test
        for cardNumber in cardNumbers {
            XCTAssertTrue(sut.validate(value: cardNumber, detectedValueType: nil))
        }

        // Failure cases
        XCTAssertFalse(sut.validate(value: "12", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "notanumber", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: 4242424242424242, detectedValueType: nil))
    }

    func test_validate_phoneNumber() {
        let sut = PrimerInputElementType.phoneNumber

        XCTAssertTrue(sut.validate(value: "1234567890", detectedValueType: nil))

        // Current logic states purely numeric phone number. This should fail
        XCTAssertFalse(sut.validate(value: "+1234567890", detectedValueType: nil))
    }

    func test_validate_postalCode() {
        let sut = PrimerInputElementType.postalCode

        XCTAssertTrue(sut.validate(value: "X82-RJ29", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "90210", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "SW1A 0RS", detectedValueType: nil))

        XCTAssertFalse(sut.validate(value: "Ké5", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "", detectedValueType: nil))
    }

    func test_validate_otp() throws {
        let sut = PrimerInputElementType.otp

        XCTAssertTrue(sut.validate(value: "123456", detectedValueType: nil))

        // Current logic states spaces or dashes are not allowed
        XCTAssertFalse(sut.validate(value: "123-456", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "123 456", detectedValueType: nil))
    }

    func test_validate_cvv() throws {
        // Testing without cardNetwork
        let sut = PrimerInputElementType.cvv

        XCTAssertTrue(sut.validate(value: "123", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "1234", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "12345", detectedValueType: nil))

        XCTAssertFalse(sut.validate(value: "12", detectedValueType: nil))
        XCTAssertFalse(sut.validate(value: "123456", detectedValueType: nil))

        // Test with CardNetwork
        for network in CardNetwork.allCases {
            for code in network.testCvvCodes {
                XCTAssertTrue(sut.validate(value: code, detectedValueType: network))
            }
        }
    }

    func test_validate_expiryDate() throws {
        let sut = PrimerInputElementType.expiryDate

        XCTAssertTrue(sut.validate(value: "12/24", detectedValueType: nil))
        XCTAssertTrue(sut.validate(value: "1224", detectedValueType: nil))

        // Current logic says the string stripped of "/" should be exactly 4 digits
        // note: this seems to be at odds with CardComponents validation
        XCTAssertFalse(sut.validate(value: "12/2024", detectedValueType: nil))
    }
}

private extension CardNetwork {
    var testCvvCodes: [String] {
        switch self {
        case .amex:
            return ["1234", "4567", "8901"]
        case .bancontact,
             .cartesBancaires,
             .diners,
             .discover,
             .elo,
             .hiper,
             .hipercard,
             .jcb,
             .maestro,
             .masterCard,
             .mir,
             .visa,
             .unionpay,
             .unknown:
            return ["123", "345", "456"]
        }
    }
}
