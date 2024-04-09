//
//  CVVRecaptureViewModelTests.swift
//  Debug App Tests
//
//  Created by Boris on 19.3.24..
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

// Mock Classes
struct MockCardButtonViewModel: CardButtonViewModelProtocol {
    var cardholder: String

    var last4: String

    var expiry: String

    var imageName: PrimerSDK.ImageName

    var paymentMethodType: PrimerSDK.PaymentInstrumentType

    var surCharge: Int?

    var network: String
}

// Unit Tests for CVVRecaptureViewModel
class CVVRecaptureViewModelTests: XCTestCase {

    var viewModel: CVVRecaptureViewModel!
    var mockCardButtonViewModel: MockCardButtonViewModel!

    override func setUp() {
        super.setUp()
        mockCardButtonViewModel = MockCardButtonViewModel(cardholder: "John Doe",
                                                          last4: "4444",
                                                          expiry: "13/05",
                                                          imageName: ImageName.genericCard,
                                                          paymentMethodType: PaymentInstrumentType.paymentCard,
                                                          network: "VISA")
        viewModel = CVVRecaptureViewModel()
        viewModel.cardButtonViewModel = mockCardButtonViewModel
    }

    override func tearDown() {
        viewModel = nil
        mockCardButtonViewModel = nil
        super.tearDown()
    }

    // Test for CVV Length Calculation
    func testCvvLengthForKnownNetwork() {
        // Setup for a known network with specific CVV length
        // e.g., mockCardButtonViewModel.network = "Visa"
        let expectedLength = 3 // Adjust based on expected CVV length for the mocked network
        XCTAssertEqual(viewModel.cvvLength, expectedLength, "CVV length should match the expected value for the given network")
    }

    // Test Continue Button State Change on isValidCvv Update
    func testContinueButtonStateChangeOnIsValidCvvUpdate() {
        let expectation = XCTestExpectation(description: "onContinueButtonStateChange closure is called")

        viewModel.onContinueButtonStateChange = { isEnabled in
            XCTAssertTrue(isEnabled, "Continue button should be enabled when isValidCvv is true")
            expectation.fulfill()
        }

        viewModel.isValidCvv = true

        wait(for: [expectation], timeout: 1.0)
    }

    // Test Continue Button Tapped Action with Valid CVV
    func testContinueButtonTappedWithValidCvv() {
        let cvv = "123"
        viewModel.isValidCvv = true

        let expectation = XCTestExpectation(description: "didSubmitCvv closure is called")

        viewModel.didSubmitCvv = { submittedCvv in
            XCTAssertEqual(submittedCvv, cvv, "Submitted CVV should match the input CVV")
            expectation.fulfill()
        }

        viewModel.continueButtonTapped(with: cvv)

        wait(for: [expectation], timeout: 1.0)
    }

    // Test Continue Button Tapped Action with Invalid CVV
    func testContinueButtonTappedWithInvalidCvv() {
        let cvv = "123"
        viewModel.isValidCvv = false // Simulate an invalid CVV

        var didCallSubmitCvv = false
        viewModel.didSubmitCvv = { _ in
            didCallSubmitCvv = true
        }

        viewModel.continueButtonTapped(with: cvv)

        XCTAssertFalse(didCallSubmitCvv, "didSubmitCvv should not be called when CVV is invalid")
    }

    // Test for invalid CVV inputs
    func testContinueButtonTappedWithInvalidCvvInputs() {
        let invalidCvvs = ["", "abc", "1234"] // Examples of invalid CVVs

        for cvv in invalidCvvs {
            var didCallSubmitCvv = false
            viewModel.didSubmitCvv = { _ in
                didCallSubmitCvv = true
            }

            viewModel.continueButtonTapped(with: cvv)

            // Check that didSubmitCvv was not called for invalid CVV inputs
            XCTAssertFalse(didCallSubmitCvv, "didSubmitCvv should not be called for invalid CVV input: \(cvv)")
        }
    }
}
