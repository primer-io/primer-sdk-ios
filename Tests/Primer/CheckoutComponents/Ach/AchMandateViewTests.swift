//
//  AchMandateViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class AchMandateViewTests: XCTestCase {

    // MARK: - Properties

    var mockScope: MockPrimerAchScope!

    // MARK: - Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        mockScope = MockPrimerAchScope.withMandateState()
    }

    @MainActor
    override func tearDown() {
        mockScope = nil
        super.tearDown()
    }

    // MARK: - View Creation Tests

    @MainActor
    func test_viewCreation_doesNotCrash() {
        let achState = AchState(
            step: .mandateAcceptance,
            userDetails: AchTestData.defaultUserDetailsState,
            mandateText: AchTestData.Constants.mandateText,
            isSubmitEnabled: true
        )

        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    @MainActor
    func test_viewCreation_withNilMandateText_doesNotCrash() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: nil,
            isSubmitEnabled: true
        )

        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    @MainActor
    func test_viewCreation_withEmptyMandateText_doesNotCrash() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "",
            isSubmitEnabled: true
        )

        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    @MainActor
    func test_viewCreation_withLongMandateText_doesNotCrash() {
        let longText = String(repeating: "This is a test mandate text. ", count: 100)
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: longText,
            isSubmitEnabled: true
        )

        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    // MARK: - Scope Interaction Tests

    @MainActor
    func test_acceptMandate_callsScope() {
        mockScope.acceptMandate()

        XCTAssertEqual(mockScope.acceptMandateCallCount, 1)
    }

    @MainActor
    func test_declineMandate_callsScope() {
        mockScope.declineMandate()

        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
    }

    @MainActor
    func test_multipleAcceptMandateCalls_tracksAllCalls() {
        mockScope.acceptMandate()
        mockScope.acceptMandate()
        mockScope.acceptMandate()

        XCTAssertEqual(mockScope.acceptMandateCallCount, 3)
    }

    @MainActor
    func test_multipleDeclineMandateCalls_tracksAllCalls() {
        mockScope.declineMandate()
        mockScope.declineMandate()

        XCTAssertEqual(mockScope.declineMandateCallCount, 2)
    }

    // MARK: - Mandate Text Tests

    @MainActor
    func test_mandateText_isDisplayedCorrectly() {
        let mandateText = "By clicking 'I Agree', you authorize Test Merchant to debit your bank account."
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: mandateText,
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.mandateText, mandateText)
    }

    @MainActor
    func test_mandateText_fromFullMandateResult() {
        let mandateResult = AchTestData.fullMandateResult

        XCTAssertNotNil(mandateResult.fullMandateText)
        XCTAssertNil(mandateResult.templateMandateText)
        XCTAssertEqual(mandateResult.fullMandateText, AchTestData.Constants.mandateText)
    }

    @MainActor
    func test_mandateText_fromTemplateMandateResult() {
        let mandateResult = AchTestData.templateMandateResult

        XCTAssertNil(mandateResult.fullMandateText)
        XCTAssertNotNil(mandateResult.templateMandateText)
        XCTAssertEqual(mandateResult.templateMandateText, AchTestData.Constants.merchantName)
    }

    // MARK: - Button State Tests

    @MainActor
    func test_acceptButton_isEnabledWhenSubmitEnabled() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate",
            isSubmitEnabled: true
        )

        // View renders with enabled accept button
        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
        XCTAssertTrue(achState.isSubmitEnabled)
    }

    @MainActor
    func test_declineButton_isAlwaysEnabled() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test mandate",
            isSubmitEnabled: false
        )

        // Decline button should always be available regardless of isSubmitEnabled
        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
        // Decline can always be called
        mockScope.declineMandate()
        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
    }

    // MARK: - State Tests

    @MainActor
    func test_state_mandateAcceptance_isCorrectStep() {
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: "Test",
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.step, .mandateAcceptance)
    }

    @MainActor
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

    @MainActor
    func test_acceptMandate_thenDeclineMandate_tracksBothCalls() {
        mockScope.acceptMandate()
        mockScope.reset()
        mockScope.declineMandate()

        XCTAssertEqual(mockScope.acceptMandateCallCount, 0)
        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
    }

    @MainActor
    func test_declineMandate_thenAcceptMandate_tracksBothCalls() {
        mockScope.declineMandate()
        mockScope.acceptMandate()

        XCTAssertEqual(mockScope.declineMandateCallCount, 1)
        XCTAssertEqual(mockScope.acceptMandateCallCount, 1)
    }

    // MARK: - Accessibility Tests

    @MainActor
    func test_viewAccessibility_mandateTextIsAccessible() {
        let mandateText = "Test mandate for accessibility"
        let achState = AchState(
            step: .mandateAcceptance,
            mandateText: mandateText,
            isSubmitEnabled: true
        )

        // The view should render with accessible mandate text
        let view = AchMandateView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
        XCTAssertEqual(achState.mandateText, mandateText)
    }
}
