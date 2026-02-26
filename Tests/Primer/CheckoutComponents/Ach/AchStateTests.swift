//
//  AchStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AchStateTests: XCTestCase {

    // MARK: - Default Initialization Tests

    func test_defaultInit_stepIsLoading() {
        let state = PrimerAchState()
        XCTAssertEqual(state.step, .loading)
    }

    func test_defaultInit_userDetailsIsEmpty() {
        let state = PrimerAchState()
        XCTAssertEqual(state.userDetails.firstName, "")
        XCTAssertEqual(state.userDetails.lastName, "")
        XCTAssertEqual(state.userDetails.emailAddress, "")
    }

    func test_defaultInit_fieldValidationIsNil() {
        let state = PrimerAchState()
        XCTAssertNil(state.fieldValidation)
    }

    func test_defaultInit_mandateTextIsNil() {
        let state = PrimerAchState()
        XCTAssertNil(state.mandateText)
    }

    func test_defaultInit_isSubmitEnabledIsFalse() {
        let state = PrimerAchState()
        XCTAssertFalse(state.isSubmitEnabled)
    }

    // MARK: - Custom Initialization Tests

    func test_customInit_setsStep() {
        let state = PrimerAchState(step: .userDetailsCollection)
        XCTAssertEqual(state.step, .userDetailsCollection)
    }

    func test_customInit_setsUserDetails() {
        let userDetails = AchTestData.defaultUserDetailsState
        let state = PrimerAchState(userDetails: userDetails)
        XCTAssertEqual(state.userDetails, userDetails)
    }

    func test_customInit_setsFieldValidation() {
        let validation = PrimerAchState.FieldValidation(firstNameError: "Invalid")
        let state = PrimerAchState(fieldValidation: validation)
        XCTAssertEqual(state.fieldValidation, validation)
    }

    func test_customInit_setsMandateText() {
        let state = PrimerAchState(mandateText: AchTestData.Constants.mandateText)
        XCTAssertEqual(state.mandateText, AchTestData.Constants.mandateText)
    }

    func test_customInit_setsIsSubmitEnabled() {
        let state = PrimerAchState(isSubmitEnabled: true)
        XCTAssertTrue(state.isSubmitEnabled)
    }

    func test_customInit_allParameters() {
        let userDetails = AchTestData.defaultUserDetailsState
        let validation = PrimerAchState.FieldValidation(emailError: "Invalid email")
        let mandateText = AchTestData.Constants.mandateText

        let state = PrimerAchState(
            step: .mandateAcceptance,
            userDetails: userDetails,
            fieldValidation: validation,
            mandateText: mandateText,
            isSubmitEnabled: true
        )

        XCTAssertEqual(state.step, .mandateAcceptance)
        XCTAssertEqual(state.userDetails, userDetails)
        XCTAssertEqual(state.fieldValidation, validation)
        XCTAssertEqual(state.mandateText, mandateText)
        XCTAssertTrue(state.isSubmitEnabled)
    }

    // MARK: - Step Equatable Tests

    func test_step_loading_isEquatable() {
        XCTAssertEqual(PrimerAchState.Step.loading, PrimerAchState.Step.loading)
    }

    func test_step_userDetailsCollection_isEquatable() {
        XCTAssertEqual(PrimerAchState.Step.userDetailsCollection, PrimerAchState.Step.userDetailsCollection)
    }

    func test_step_bankAccountCollection_isEquatable() {
        XCTAssertEqual(PrimerAchState.Step.bankAccountCollection, PrimerAchState.Step.bankAccountCollection)
    }

    func test_step_mandateAcceptance_isEquatable() {
        XCTAssertEqual(PrimerAchState.Step.mandateAcceptance, PrimerAchState.Step.mandateAcceptance)
    }

    func test_step_processing_isEquatable() {
        XCTAssertEqual(PrimerAchState.Step.processing, PrimerAchState.Step.processing)
    }

    func test_step_differentSteps_areNotEqual() {
        XCTAssertNotEqual(PrimerAchState.Step.loading, PrimerAchState.Step.userDetailsCollection)
        XCTAssertNotEqual(PrimerAchState.Step.bankAccountCollection, PrimerAchState.Step.mandateAcceptance)
        XCTAssertNotEqual(PrimerAchState.Step.processing, PrimerAchState.Step.loading)
    }

    // MARK: - UserDetails Tests

    func test_userDetails_defaultInit_allFieldsEmpty() {
        let userDetails = PrimerAchState.UserDetails()
        XCTAssertEqual(userDetails.firstName, "")
        XCTAssertEqual(userDetails.lastName, "")
        XCTAssertEqual(userDetails.emailAddress, "")
    }

    func test_userDetails_customInit_setsAllFields() {
        let userDetails = PrimerAchState.UserDetails(
            firstName: AchTestData.Constants.firstName,
            lastName: AchTestData.Constants.lastName,
            emailAddress: AchTestData.Constants.emailAddress
        )
        XCTAssertEqual(userDetails.firstName, AchTestData.Constants.firstName)
        XCTAssertEqual(userDetails.lastName, AchTestData.Constants.lastName)
        XCTAssertEqual(userDetails.emailAddress, AchTestData.Constants.emailAddress)
    }

    func test_userDetails_equatable_equalValues() {
        let userDetails1 = PrimerAchState.UserDetails(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john@example.com"
        )
        let userDetails2 = PrimerAchState.UserDetails(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john@example.com"
        )
        XCTAssertEqual(userDetails1, userDetails2)
    }

    func test_userDetails_equatable_differentFirstName() {
        let userDetails1 = PrimerAchState.UserDetails(firstName: "John")
        let userDetails2 = PrimerAchState.UserDetails(firstName: "Jane")
        XCTAssertNotEqual(userDetails1, userDetails2)
    }

    func test_userDetails_equatable_differentLastName() {
        let userDetails1 = PrimerAchState.UserDetails(lastName: "Doe")
        let userDetails2 = PrimerAchState.UserDetails(lastName: "Smith")
        XCTAssertNotEqual(userDetails1, userDetails2)
    }

    func test_userDetails_equatable_differentEmail() {
        let userDetails1 = PrimerAchState.UserDetails(emailAddress: "john@example.com")
        let userDetails2 = PrimerAchState.UserDetails(emailAddress: "jane@example.com")
        XCTAssertNotEqual(userDetails1, userDetails2)
    }

    // MARK: - FieldValidation Tests

    func test_fieldValidation_defaultInit_allErrorsNil() {
        let validation = PrimerAchState.FieldValidation()
        XCTAssertNil(validation.firstNameError)
        XCTAssertNil(validation.lastNameError)
        XCTAssertNil(validation.emailError)
    }

    func test_fieldValidation_customInit_setsAllErrors() {
        let validation = PrimerAchState.FieldValidation(
            firstNameError: "First name error",
            lastNameError: "Last name error",
            emailError: "Email error"
        )
        XCTAssertEqual(validation.firstNameError, "First name error")
        XCTAssertEqual(validation.lastNameError, "Last name error")
        XCTAssertEqual(validation.emailError, "Email error")
    }

    func test_fieldValidation_hasErrors_noErrors_returnsFalse() {
        let validation = PrimerAchState.FieldValidation()
        XCTAssertFalse(validation.hasErrors)
    }

    func test_fieldValidation_hasErrors_withFirstNameError_returnsTrue() {
        let validation = PrimerAchState.FieldValidation(firstNameError: "Invalid")
        XCTAssertTrue(validation.hasErrors)
    }

    func test_fieldValidation_hasErrors_withLastNameError_returnsTrue() {
        let validation = PrimerAchState.FieldValidation(lastNameError: "Invalid")
        XCTAssertTrue(validation.hasErrors)
    }

    func test_fieldValidation_hasErrors_withEmailError_returnsTrue() {
        let validation = PrimerAchState.FieldValidation(emailError: "Invalid")
        XCTAssertTrue(validation.hasErrors)
    }

    func test_fieldValidation_hasErrors_withMultipleErrors_returnsTrue() {
        let validation = PrimerAchState.FieldValidation(
            firstNameError: "Invalid",
            lastNameError: "Invalid",
            emailError: "Invalid"
        )
        XCTAssertTrue(validation.hasErrors)
    }

    func test_fieldValidation_equatable_equalValues() {
        let validation1 = PrimerAchState.FieldValidation(firstNameError: "Error")
        let validation2 = PrimerAchState.FieldValidation(firstNameError: "Error")
        XCTAssertEqual(validation1, validation2)
    }

    func test_fieldValidation_equatable_differentValues() {
        let validation1 = PrimerAchState.FieldValidation(firstNameError: "Error1")
        let validation2 = PrimerAchState.FieldValidation(firstNameError: "Error2")
        XCTAssertNotEqual(validation1, validation2)
    }

    // MARK: - State Equatable Tests

    func test_state_equalStates_areEqual() {
        let userDetails = AchTestData.defaultUserDetailsState
        let state1 = PrimerAchState(
            step: .userDetailsCollection,
            userDetails: userDetails,
            mandateText: "mandate",
            isSubmitEnabled: true
        )
        let state2 = PrimerAchState(
            step: .userDetailsCollection,
            userDetails: userDetails,
            mandateText: "mandate",
            isSubmitEnabled: true
        )
        XCTAssertEqual(state1, state2)
    }

    func test_state_differentSteps_areNotEqual() {
        let state1 = PrimerAchState(step: .loading)
        let state2 = PrimerAchState(step: .userDetailsCollection)
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentUserDetails_areNotEqual() {
        let state1 = PrimerAchState(userDetails: PrimerAchState.UserDetails(firstName: "John"))
        let state2 = PrimerAchState(userDetails: PrimerAchState.UserDetails(firstName: "Jane"))
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentMandateText_areNotEqual() {
        let state1 = PrimerAchState(mandateText: "mandate1")
        let state2 = PrimerAchState(mandateText: "mandate2")
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentIsSubmitEnabled_areNotEqual() {
        let state1 = PrimerAchState(isSubmitEnabled: true)
        let state2 = PrimerAchState(isSubmitEnabled: false)
        XCTAssertNotEqual(state1, state2)
    }

    func test_state_differentFieldValidation_areNotEqual() {
        let state1 = PrimerAchState(fieldValidation: PrimerAchState.FieldValidation(firstNameError: "error"))
        let state2 = PrimerAchState(fieldValidation: nil)
        XCTAssertNotEqual(state1, state2)
    }
}
