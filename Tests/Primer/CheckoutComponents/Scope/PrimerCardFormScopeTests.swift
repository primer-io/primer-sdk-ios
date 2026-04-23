//
//  PrimerCardFormScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

// MARK: - PrimerCardFormScope Protocol Extension Tests

@available(iOS 15.0, *)
@MainActor
final class PrimerCardFormScopeTests: XCTestCase {

    // MARK: - Test Doubles

    private class MockCardFormScopeImpl: PrimerCardFormScope {
        typealias State = PrimerCardFormState

        var updatedFields: [PrimerInputElementType: String] = [:]

        var state: AsyncStream<PrimerCardFormState> {
            AsyncStream { continuation in
                continuation.yield(PrimerCardFormState())
                continuation.finish()
            }
        }

        var presentationContext: PresentationContext = .direct
        var cardFormUIOptions: PrimerCardFormUIOptions?
        var dismissalMechanism: [DismissalMechanism] = []
        var selectCountry: PrimerSelectCountryScope { fatalError("Not implemented for test") }

        var title: String?
        var screen: CardFormScreenComponent?
        var cobadgedCardsView: (([String], @escaping (String) -> Void) -> any View)?
        var errorScreen: ErrorComponent?
        var submitButtonText: String?
        var showSubmitLoadingIndicator: Bool = false

        var cardNumberConfig: InputFieldConfig?
        var expiryDateConfig: InputFieldConfig?
        var cvvConfig: InputFieldConfig?
        var cardholderNameConfig: InputFieldConfig?
        var postalCodeConfig: InputFieldConfig?
        var countryConfig: InputFieldConfig?
        var cityConfig: InputFieldConfig?
        var stateConfig: InputFieldConfig?
        var addressLine1Config: InputFieldConfig?
        var addressLine2Config: InputFieldConfig?
        var phoneNumberConfig: InputFieldConfig?
        var firstNameConfig: InputFieldConfig?
        var lastNameConfig: InputFieldConfig?
        var emailConfig: InputFieldConfig?
        var retailOutletConfig: InputFieldConfig?
        var otpCodeConfig: InputFieldConfig?

        var cardInputSection: Component?
        var billingAddressSection: Component?
        var submitButton: Component?

        func start() {}
        func submit() {}
        func onBack() {}
        func cancel() {}

        func updateCardNumber(_ cardNumber: String) {
            updatedFields[.cardNumber] = cardNumber
        }

        func updateCvv(_ cvv: String) {
            updatedFields[.cvv] = cvv
        }

        func updateExpiryDate(_ expiryDate: String) {
            updatedFields[.expiryDate] = expiryDate
        }

        func updateCardholderName(_ cardholderName: String) {
            updatedFields[.cardholderName] = cardholderName
        }

        func updatePostalCode(_ postalCode: String) {
            updatedFields[.postalCode] = postalCode
        }

        func updateCity(_ city: String) {
            updatedFields[.city] = city
        }

        func updateState(_ state: String) {
            updatedFields[.state] = state
        }

        func updateAddressLine1(_ addressLine1: String) {
            updatedFields[.addressLine1] = addressLine1
        }

        func updateAddressLine2(_ addressLine2: String) {
            updatedFields[.addressLine2] = addressLine2
        }

        func updatePhoneNumber(_ phoneNumber: String) {
            updatedFields[.phoneNumber] = phoneNumber
        }

        func updateFirstName(_ firstName: String) {
            updatedFields[.firstName] = firstName
        }

        func updateLastName(_ lastName: String) {
            updatedFields[.lastName] = lastName
        }

        func updateRetailOutlet(_ retailOutlet: String) {
            updatedFields[.retailer] = retailOutlet
        }

        func updateOtpCode(_ otpCode: String) {
            updatedFields[.otp] = otpCode
        }

        func updateEmail(_ email: String) {
            updatedFields[.email] = email
        }

        func updateExpiryMonth(_ month: String) {}
        func updateExpiryYear(_ year: String) {}
        func updateSelectedCardNetwork(_ network: String) {}
        func updateCountryCode(_ countryCode: String) {
            updatedFields[.countryCode] = countryCode
        }

        func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }

        func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView {
            AnyView(EmptyView())
        }
    }

    // MARK: - Exhaustive updateField Dispatch Tests

    func test_updateField_allCardFields_dispatchCorrectly() {
        let scope = MockCardFormScopeImpl()
        let testValue = "test_value"

        let cardFields: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
        ]

        for field in cardFields {
            scope.updateField(field, value: testValue)
            XCTAssertNotNil(scope.updatedFields[field], "Field \(field) should be updated")
        }
    }

    func test_updateField_allBillingFields_dispatchCorrectly() {
        let scope = MockCardFormScopeImpl()
        let testValue = "test_value"

        let billingFields: [PrimerInputElementType] = [
            .postalCode, .countryCode, .city, .state,
            .addressLine1, .addressLine2, .phoneNumber,
            .firstName, .lastName, .email,
        ]

        for field in billingFields {
            scope.updateField(field, value: testValue)
            XCTAssertNotNil(scope.updatedFields[field], "Field \(field) should be updated")
        }
    }

    func test_updateField_otherFields_dispatchCorrectly() {
        let scope = MockCardFormScopeImpl()
        let testValue = "test_value"

        scope.updateField(.retailer, value: testValue)
        XCTAssertNotNil(scope.updatedFields[.retailer])

        scope.updateField(.otp, value: testValue)
        XCTAssertNotNil(scope.updatedFields[.otp])
    }

    // MARK: - Boundary Cases

    func test_updateField_unknown_doesNotDispatch() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.unknown, value: "test")

        XCTAssertNil(scope.updatedFields[.unknown])
    }

    func test_updateField_all_doesNotDispatch() {
        let scope = MockCardFormScopeImpl()

        scope.updateField(.all, value: "test")

        XCTAssertNil(scope.updatedFields[.all])
    }

    // MARK: - Exhaustive Default Return Value Tests

    func test_getFieldValue_forAllFieldTypes_returnsEmptyString() {
        let scope = MockCardFormScopeImpl()

        let fieldTypes: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .postalCode, .city, .state, .addressLine1,
            .addressLine2, .phoneNumber, .firstName, .lastName,
            .email, .countryCode, .retailer, .otp,
        ]

        for fieldType in fieldTypes {
            let value = scope.getFieldValue(fieldType)
            XCTAssertEqual(value, "", "getFieldValue for \(fieldType) should return empty string")
        }
    }

    func test_getFieldError_forAllFieldTypes_returnsNil() {
        let scope = MockCardFormScopeImpl()

        let fieldTypes: [PrimerInputElementType] = [
            .cardNumber, .cvv, .expiryDate, .cardholderName,
            .postalCode, .city, .state, .addressLine1,
            .addressLine2, .phoneNumber, .firstName, .lastName,
        ]

        for fieldType in fieldTypes {
            let error = scope.getFieldError(fieldType)
            XCTAssertNil(error, "getFieldError for \(fieldType) should return nil")
        }
    }

    // MARK: - Contract Tests

    func test_getFormConfiguration_defaultImplementation_returnsDefault() {
        let scope = MockCardFormScopeImpl()

        let config = scope.getFormConfiguration()

        XCTAssertEqual(config, CardFormConfiguration.default)
    }

    // MARK: - Behavioral Tests

    func test_submit_callsSubmitOnScope() {
        var submitCalled = false

        final class TrackingScope: MockCardFormScopeImpl {
            var submitHandler: (() -> Void)?

            override func submit() {
                submitHandler?()
            }
        }

        let scope = TrackingScope()
        scope.submitHandler = { submitCalled = true }

        scope.submit()

        XCTAssertTrue(submitCalled)
    }

    func test_cancel_callsCancelOnScope() {
        var cancelCalled = false

        final class TrackingScope: MockCardFormScopeImpl {
            var cancelHandler: (() -> Void)?

            override func cancel() {
                cancelHandler?()
            }
        }

        let scope = TrackingScope()
        scope.cancelHandler = { cancelCalled = true }

        scope.cancel()

        XCTAssertTrue(cancelCalled)
    }
}
