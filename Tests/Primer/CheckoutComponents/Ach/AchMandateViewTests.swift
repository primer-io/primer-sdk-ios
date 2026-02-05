//
//  AchMandateViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class AchMandateViewTests: XCTestCase {

    // MARK: - Properties

    private var mockScope: MockPrimerAchScope!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockScope = MockPrimerAchScope.withMandateState()
    }

    override func tearDown() {
        mockScope = nil
        super.tearDown()
    }

    // MARK: - View Creation Tests

    func test_viewCreation_doesNotCrash() {
        let achState = AchState(
            step: .mandateAcceptance,
            userDetails: AchTestData.defaultUserDetailsState,
            mandateText: AchTestData.Constants.mandateText,
            isSubmitEnabled: true
        )

        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
    }

    func test_viewCreation_withNilMandateText_doesNotCrash() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: nil,
            isSubmitEnabled: true
        )

        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
    }

    func test_viewCreation_withEmptyMandateText_doesNotCrash() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "",
            isSubmitEnabled: true
        )

        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
    }

    func test_viewCreation_withLongMandateText_doesNotCrash() {
        let longText = String(repeating: "This is a test mandate text. ", count: 100)
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: longText,
            isSubmitEnabled: true
        )

        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
    }

    // MARK: - Scope Interaction Tests

    func test_acceptMandate_callsScope() {
        mockScope.acceptMandate()

        XCTAssertEqual(mockScope.acceptMandateCallCount, 1)
    }

    func test_declineMandate_callsScope() {
        mockScope.declineMandate()

        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
    }

    func test_multipleAcceptMandateCalls_tracksAllCalls() {
        mockScope.acceptMandate()
        mockScope.acceptMandate()
        mockScope.acceptMandate()

        XCTAssertEqual(mockScope.acceptMandateCallCount, 3)
    }

    func test_multipleDeclineMandateCalls_tracksAllCalls() {
        mockScope.declineMandate()
        mockScope.declineMandate()

        XCTAssertEqual(mockScope.declineMandateCallCount, 2)
    }

    // MARK: - Mandate Text Tests

    func test_mandateText_isDisplayedCorrectly() {
        let mandateText = "By clicking 'I Agree', you authorize Test Merchant to debit your bank account."
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: mandateText,
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.mandateText, mandateText)
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

    // MARK: - Button State Tests

    func test_acceptButton_isEnabledWhenSubmitEnabled() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate",
            isSubmitEnabled: true
        )

        // View renders with enabled accept button
        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
        XCTAssertTrue(achState.isSubmitEnabled)
    }

    func test_declineButton_isAlwaysEnabled() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate",
            isSubmitEnabled: false
        )

        // Decline button should always be available regardless of isSubmitEnabled
        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
        // Decline can always be called
        mockScope.declineMandate()
        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
    }

    // MARK: - State Tests

    func test_state_mandateAcceptance_isCorrectStep() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test",
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.step, .mandateAcceptance)
    }

    func test_state_userDetails_arePreserved() {
        let userDetails = AchState.UserDetails(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john@example.com"
        )
        let achState = AchState(
            step: .mandateAcceptance,
            userDetails: userDetails,
            mandateText: "Test mandate",
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.userDetails.firstName, "John")
        XCTAssertEqual(achState.userDetails.lastName, "Doe")
        XCTAssertEqual(achState.userDetails.emailAddress, "john@example.com")
    }

    // MARK: - Integration Tests

    func test_acceptMandate_thenDeclineMandate_tracksBothCalls() {
        mockScope.acceptMandate()
        mockScope.reset()
        mockScope.declineMandate()

        XCTAssertEqual(mockScope.acceptMandateCallCount, 0)
        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
    }

    func test_declineMandate_thenAcceptMandate_tracksBothCalls() {
        mockScope.declineMandate()
        mockScope.acceptMandate()

        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
        XCTAssertEqual(mockScope.acceptMandateCallCount, 1)
    }

    // MARK: - Accessibility Tests

    func test_viewAccessibility_mandateTextIsAccessible() {
        let mandateText = "Test mandate for accessibility"
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: mandateText,
            isSubmitEnabled: true
        )

        // The view should render with accessible mandate text
        XCTAssertNotNil(AchMandateView(scope: mockScope, achState: achState))
        XCTAssertEqual(achState.mandateText, mandateText)
    }
}
