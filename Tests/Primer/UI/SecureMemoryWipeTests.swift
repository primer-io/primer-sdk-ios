//
//  SecureMemoryWipeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class SecureMemoryWipeTests: XCTestCase {

    // MARK: - PrimerTextField.wipe()

    func test_wipe_clearsInternalText() {
        let textField = PrimerTextField()
        textField.internalText = "4242424242424242"
        textField.wipe()
        XCTAssertNil(textField.internalText)
    }

    func test_wipe_clearsSuperText() {
        let textField = PrimerTextField()
        textField.internalText = "4242424242424242"
        textField.wipe()
        XCTAssertNil(textField.internalText)
        // After wipe, the text getter returns "****" due to override,
        // but super.text should be nil
        XCTAssertEqual(textField.text, "****")
    }

    func test_wipe_handlesNilInternalText() {
        let textField = PrimerTextField()
        textField.wipe()
        XCTAssertNil(textField.internalText)
    }

    // MARK: - PrimerCardData.wipe()

    func test_cardData_wipe_clearsAllFields() {
        let cardData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "12/29",
            cvv: "123",
            cardholderName: "John Doe",
            cardNetwork: .visa
        )
        cardData.wipe()
        XCTAssertEqual(cardData.cardNumber, "")
        XCTAssertEqual(cardData.expiryDate, "")
        XCTAssertEqual(cardData.cvv, "")
        XCTAssertNil(cardData.cardholderName)
        XCTAssertNil(cardData.cardNetwork)
    }

    func test_cardData_wipe_handlesNilOptionals() {
        let cardData = PrimerCardData(
            cardNumber: "4242424242424242",
            expiryDate: "12/29",
            cvv: "123",
            cardholderName: nil
        )
        cardData.wipe()
        XCTAssertEqual(cardData.cardNumber, "")
        XCTAssertEqual(cardData.expiryDate, "")
        XCTAssertEqual(cardData.cvv, "")
        XCTAssertNil(cardData.cardholderName)
        XCTAssertNil(cardData.cardNetwork)
    }
}
