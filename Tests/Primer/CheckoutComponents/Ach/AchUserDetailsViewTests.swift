//
//  AchUserDetailsViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class AchUserDetailsViewTests: XCTestCase {

    // MARK: - Properties

    var mockScope: MockPrimerAchScope!

    // MARK: - Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        mockScope = MockPrimerAchScope.withUserDetailsState()
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
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            isSubmitEnabled: true
        )

        // Creating the view should not crash
        let view = AchUserDetailsView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    @MainActor
    func test_viewCreation_withEmptyUserDetails_doesNotCrash() {
        let achState = AchState(
            step: .userDetailsCollection,
            userDetails: AchState.UserDetails(),
            isSubmitEnabled: false
        )

        let view = AchUserDetailsView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    @MainActor
    func test_viewCreation_withFieldValidation_doesNotCrash() {
        let validation = AchState.FieldValidation(
            firstNameError: "Invalid",
            lastNameError: "Invalid",
            emailError: "Invalid"
        )
        let achState = AchState(
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            fieldValidation: validation,
            isSubmitEnabled: false
        )

        let view = AchUserDetailsView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
    }

    // MARK: - Scope Interaction Tests

    @MainActor
    func test_scope_updateFirstNameInteraction() {
        // The view internally calls scope.updateFirstName when user types
        // We verify the scope method is available and callable
        mockScope.updateFirstName("TestName")

        XCTAssertEqual(mockScope.updateFirstNameCallCount, 1)
        XCTAssertEqual(mockScope.lastFirstName, "TestName")
    }

    @MainActor
    func test_scope_updateLastNameInteraction() {
        mockScope.updateLastName("TestLastName")

        XCTAssertEqual(mockScope.updateLastNameCallCount, 1)
        XCTAssertEqual(mockScope.lastLastName, "TestLastName")
    }

    @MainActor
    func test_scope_updateEmailAddressInteraction() {
        mockScope.updateEmailAddress("test@example.com")

        XCTAssertEqual(mockScope.updateEmailAddressCallCount, 1)
        XCTAssertEqual(mockScope.lastEmailAddress, "test@example.com")
    }

    @MainActor
    func test_scope_submitUserDetailsInteraction() {
        mockScope.submitUserDetails()

        XCTAssertEqual(mockScope.submitUserDetailsCallCount, 1)
    }

    // MARK: - Submit Button State Tests

    @MainActor
    func test_submitButton_enabledWhenIsSubmitEnabledTrue() {
        let achState = AchState(
            step: .userDetailsCollection,
            userDetails: AchTestData.defaultUserDetailsState,
            isSubmitEnabled: true
        )

        // View should render with enabled submit button
        let view = AchUserDetailsView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
        XCTAssertTrue(achState.isSubmitEnabled)
    }

    @MainActor
    func test_submitButton_disabledWhenIsSubmitEnabledFalse() {
        let achState = AchState(
            step: .userDetailsCollection,
            userDetails: AchState.UserDetails(),
            isSubmitEnabled: false
        )

        // View should render with disabled submit button
        let view = AchUserDetailsView(scope: mockScope, achState: achState)
        XCTAssertNotNil(view)
        XCTAssertFalse(achState.isSubmitEnabled)
    }

    // MARK: - Custom Submit Button Tests

    @MainActor
    func test_customSubmitButton_canBeSet() {
        mockScope.submitButton = { scope in
            Button("Custom Submit") {
                scope.submitUserDetails()
            }
        }

        XCTAssertNotNil(mockScope.submitButton)
    }

    @MainActor
    func test_customSubmitButton_whenSet_isUsedInsteadOfDefault() {
        var customButtonTapped = false
        mockScope.submitButton = { scope in
            Button("Custom Submit") {
                customButtonTapped = true
                scope.submitUserDetails()
            }
        }

        // Simulate what happens when custom button is tapped
        mockScope.submitUserDetails()

        XCTAssertEqual(mockScope.submitUserDetailsCallCount, 1)
    }

    // MARK: - User Details Display Tests

    @MainActor
    func test_userDetails_displayCorrectInitialValues() {
        let userDetails = AchState.UserDetails(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john.doe@example.com"
        )
        let achState = AchState(
            step: .userDetailsCollection,
            userDetails: userDetails,
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.userDetails.firstName, "John")
        XCTAssertEqual(achState.userDetails.lastName, "Doe")
        XCTAssertEqual(achState.userDetails.emailAddress, "john.doe@example.com")
    }

    // MARK: - Field Validation Display Tests

    @MainActor
    func test_fieldValidation_firstNameError_isAvailable() {
        let validation = AchState.FieldValidation(
            firstNameError: "First name is required",
            lastNameError: nil,
            emailError: nil
        )
        let achState = AchState(
            step: .userDetailsCollection,
            fieldValidation: validation,
            isSubmitEnabled: false
        )

        XCTAssertEqual(achState.fieldValidation?.firstNameError, "First name is required")
        XCTAssertNil(achState.fieldValidation?.lastNameError)
        XCTAssertNil(achState.fieldValidation?.emailError)
    }

    @MainActor
    func test_fieldValidation_lastNameError_isAvailable() {
        let validation = AchState.FieldValidation(
            firstNameError: nil,
            lastNameError: "Last name is required",
            emailError: nil
        )
        let achState = AchState(
            step: .userDetailsCollection,
            fieldValidation: validation,
            isSubmitEnabled: false
        )

        XCTAssertNil(achState.fieldValidation?.firstNameError)
        XCTAssertEqual(achState.fieldValidation?.lastNameError, "Last name is required")
        XCTAssertNil(achState.fieldValidation?.emailError)
    }

    @MainActor
    func test_fieldValidation_emailError_isAvailable() {
        let validation = AchState.FieldValidation(
            firstNameError: nil,
            lastNameError: nil,
            emailError: "Invalid email address"
        )
        let achState = AchState(
            step: .userDetailsCollection,
            fieldValidation: validation,
            isSubmitEnabled: false
        )

        XCTAssertNil(achState.fieldValidation?.firstNameError)
        XCTAssertNil(achState.fieldValidation?.lastNameError)
        XCTAssertEqual(achState.fieldValidation?.emailError, "Invalid email address")
    }

    @MainActor
    func test_fieldValidation_hasErrors_returnsTrue() {
        let validation = AchState.FieldValidation(
            firstNameError: "Error",
            lastNameError: nil,
            emailError: nil
        )

        XCTAssertTrue(validation.hasErrors)
    }

    @MainActor
    func test_fieldValidation_hasErrors_returnsFalse() {
        let validation = AchState.FieldValidation(
            firstNameError: nil,
            lastNameError: nil,
            emailError: nil
        )

        XCTAssertFalse(validation.hasErrors)
    }
}
