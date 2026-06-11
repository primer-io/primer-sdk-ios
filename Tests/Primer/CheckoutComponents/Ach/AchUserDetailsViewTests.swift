//
//  AchUserDetailsViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
final class AchUserDetailsViewTests: XCTestCase {

    private var mockScope: MockPrimerAchScope!

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

    // MARK: - User Details Display Tests

    @MainActor
    func test_userDetails_displayCorrectInitialValues() {
        let userDetails = PrimerAchState.UserDetails(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john.doe@example.com"
        )
        let achState = PrimerAchState(
            step: .userDetailsCollection,
            userDetails: userDetails,
            isSubmitEnabled: true
        )

        XCTAssertEqual(achState.userDetails.firstName, "John")
        XCTAssertEqual(achState.userDetails.lastName, "Doe")
        XCTAssertEqual(achState.userDetails.emailAddress, "john.doe@example.com")
    }

    @MainActor
    func test_fieldValidation_hasErrors_returnsTrue() {
        let validation = PrimerAchState.FieldValidation(
            firstNameError: "Error",
            lastNameError: nil,
            emailError: nil
        )

        XCTAssertTrue(validation.hasErrors)
    }

    @MainActor
    func test_fieldValidation_hasErrors_returnsFalse() {
        let validation = PrimerAchState.FieldValidation(
            firstNameError: nil,
            lastNameError: nil,
            emailError: nil
        )

        XCTAssertFalse(validation.hasErrors)
    }
}
