//
//  AchMandateViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class AchMandateViewTests: XCTestCase {

    private var mockScope: MockPrimerAchScope!

    override func setUp() {
        super.setUp()
        mockScope = MockPrimerAchScope.withMandateState()
    }

    override func tearDown() {
        mockScope = nil
        super.tearDown()
    }

    func test_mandateText_fromFullMandateResult() {
        let mandateResult = AchTestData.fullMandateResult

        XCTAssertNotNil(mandateResult.fullMandateText)
        XCTAssertNil(mandateResult.templateMandateText)
        XCTAssertEqual(mandateResult.fullMandateText, AchTestData.Constants.mandateText)
    }

    func test_mandateText_fromTemplateMandateResult() {
        let mandateResult = AchTestData.templateMandateResult

        XCTAssertNil(mandateResult.fullMandateText)
        XCTAssertNotNil(mandateResult.templateMandateText)
        XCTAssertEqual(mandateResult.templateMandateText, AchTestData.Constants.merchantName)
    }

    func test_state_userDetails_arePreserved() {
        let userDetails = PrimerAchState.UserDetails(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john@example.com"
        )
        let achState = PrimerAchState(
            step: .mandateAcceptance,
            userDetails: userDetails,
            mandateText: "Test mandate",
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.userDetails.firstName, "John")
        XCTAssertEqual(achState.userDetails.lastName, "Doe")
        XCTAssertEqual(achState.userDetails.emailAddress, "john@example.com")
    }
}
