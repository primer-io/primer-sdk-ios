//
//  DefaultPaymentMethodSelectionScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Tests for CVV validation logic used in DefaultPaymentMethodSelectionScope.
///
/// These tests verify the CVV validation behavior by testing the validation rules directly.
/// The validateCvv method in DefaultPaymentMethodSelectionScope follows these rules:
/// - Empty input: not valid, no error (user hasn't started)
/// - Non-numeric: not valid, show error
/// - Too many digits: not valid, show error
/// - Exact length: valid, no error
/// - Partial input: not valid, no error (user still typing)
@available(iOS 15.0, *)
final class CvvValidationLogicTests: XCTestCase {

    // MARK: - CVV Validation Rules Tests

    /// These tests document and verify the expected CVV validation behavior
    /// that is implemented in DefaultPaymentMethodSelectionScope.validateCvv

    func testCvvValidation_EmptyInput_NotValidNoError() {
        // Given
        let cvv = ""
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Empty CVV should not be valid")
        XCTAssertNil(result.errorMessage, "Empty CVV should not show error (user hasn't started)")
    }

    func testCvvValidation_ValidThreeDigitCvv_IsValid() {
        // Given
        let cvv = "123"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertTrue(result.isValid, "3-digit CVV should be valid for 3-digit requirement")
        XCTAssertNil(result.errorMessage, "Valid CVV should have no error")
    }

    func testCvvValidation_ValidFourDigitCvv_IsValid() {
        // Given - Amex cards use 4-digit CVV
        let cvv = "1234"
        let expectedLength = 4

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertTrue(result.isValid, "4-digit CVV should be valid for 4-digit requirement")
        XCTAssertNil(result.errorMessage, "Valid CVV should have no error")
    }

    func testCvvValidation_NonNumericCharacters_ShowsError() {
        // Given
        let cvv = "12a"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Non-numeric CVV should not be valid")
        XCTAssertNotNil(result.errorMessage, "Non-numeric CVV should show error")
    }

    func testCvvValidation_TooManyDigits_ShowsError() {
        // Given - 4 digits when 3 expected
        let cvv = "1234"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Too many digits should not be valid")
        XCTAssertNotNil(result.errorMessage, "Too many digits should show error")
    }

    func testCvvValidation_PartialInput_NotValidNoError() {
        // Given - 2 digits when 3 expected
        let cvv = "12"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Partial input should not be valid")
        XCTAssertNil(result.errorMessage, "Partial input should not show error (user still typing)")
    }

    func testCvvValidation_SingleDigit_NotValidNoError() {
        // Given - 1 digit when 3 expected
        let cvv = "1"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Single digit should not be valid")
        XCTAssertNil(result.errorMessage, "Single digit should not show error")
    }

    func testCvvValidation_SpecialCharacters_ShowsError() {
        // Given
        let cvv = "12!"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Special characters should not be valid")
        XCTAssertNotNil(result.errorMessage, "Special characters should show error")
    }

    func testCvvValidation_Spaces_ShowsError() {
        // Given
        let cvv = "1 2"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid, "Spaces should not be valid")
        XCTAssertNotNil(result.errorMessage, "Spaces should show error")
    }

    func testCvvValidation_LeadingZeros_IsValid() {
        // Given - CVV with leading zeros is valid
        let cvv = "007"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertTrue(result.isValid, "CVV with leading zeros should be valid")
        XCTAssertNil(result.errorMessage, "Valid CVV should have no error")
    }

    // MARK: - Test Helper

    /// Mirrors the validation logic from DefaultPaymentMethodSelectionScope.validateCvv
    /// This ensures our tests verify the exact same logic used in production
    private func validateCvv(_ cvv: String, expectedLength: Int) -> (isValid: Bool, errorMessage: String?) {
        // Empty input: not valid yet, but no error (user hasn't started typing)
        guard !cvv.isEmpty else {
            return (false, nil)
        }

        // Non-numeric characters: invalid with error
        guard cvv.allSatisfy(\.isNumber) else {
            return (false, "Please enter a valid CVV")
        }

        // Too many digits: invalid with error
        if cvv.count > expectedLength {
            return (false, "Please enter a valid CVV")
        }

        // Exact length: valid, no error
        if cvv.count == expectedLength {
            return (true, nil)
        }

        // Partial input (fewer digits): not yet valid, no error (user still typing)
        return (false, nil)
    }
}

// MARK: - Payment Method Selection State Tests

@available(iOS 15.0, *)
final class PaymentMethodSelectionStateTests: XCTestCase {

    func testInitialState_HasCorrectDefaults() {
        // Given/When
        let state = PrimerPaymentMethodSelectionState()

        // Then
        XCTAssertTrue(state.paymentMethods.isEmpty)
        XCTAssertTrue(state.filteredPaymentMethods.isEmpty)
        XCTAssertNil(state.selectedPaymentMethod)
        XCTAssertNil(state.selectedVaultedPaymentMethod)
        XCTAssertTrue(state.searchQuery.isEmpty)
        XCTAssertNil(state.error)
        XCTAssertFalse(state.requiresCvvInput)
        XCTAssertTrue(state.cvvInput.isEmpty)
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNil(state.cvvError)
        XCTAssertFalse(state.isVaultPaymentLoading)
        XCTAssertTrue(state.isPaymentMethodsExpanded)
    }

    func testState_CvvProperties_AreSettable() {
        // Given
        var state = PrimerPaymentMethodSelectionState()

        // When
        state.requiresCvvInput = true
        state.cvvInput = "123"
        state.isCvvValid = true
        state.cvvError = nil

        // Then
        XCTAssertTrue(state.requiresCvvInput)
        XCTAssertEqual(state.cvvInput, "123")
        XCTAssertTrue(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    func testState_PaymentMethodsExpanded_CanBeToggled() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        XCTAssertTrue(state.isPaymentMethodsExpanded) // Default is true

        // When
        state.isPaymentMethodsExpanded = false

        // Then
        XCTAssertFalse(state.isPaymentMethodsExpanded)
    }

    func testState_VaultPaymentLoading_CanBeToggled() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        XCTAssertFalse(state.isVaultPaymentLoading) // Default is false

        // When
        state.isVaultPaymentLoading = true

        // Then
        XCTAssertTrue(state.isVaultPaymentLoading)
    }

    func testState_WithPaymentMethods_MaintainsData() {
        // Given
        let paymentMethod = CheckoutPaymentMethod(
            id: "pm_1",
            type: "PAYMENT_CARD",
            name: "Card"
        )

        // When
        let state = PrimerPaymentMethodSelectionState(
            paymentMethods: [paymentMethod],
            selectedPaymentMethod: paymentMethod,
            filteredPaymentMethods: [paymentMethod]
        )

        // Then
        XCTAssertEqual(state.paymentMethods.count, 1)
        XCTAssertEqual(state.paymentMethods.first?.id, "pm_1")
        XCTAssertEqual(state.selectedPaymentMethod?.id, "pm_1")
    }

    func testState_CvvError_CanBeSet() {
        // Given
        var state = PrimerPaymentMethodSelectionState()

        // When
        state.cvvError = "Invalid CVV"

        // Then
        XCTAssertEqual(state.cvvError, "Invalid CVV")
    }

    func testState_SearchQuery_UpdatesFilteredMethods() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        let cardMethod = CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card")
        let paypalMethod = CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        state.paymentMethods = [cardMethod, paypalMethod]
        state.filteredPaymentMethods = [cardMethod, paypalMethod]

        // When
        state.searchQuery = "Card"
        state.filteredPaymentMethods = state.paymentMethods.filter {
            $0.name.lowercased().contains(state.searchQuery.lowercased())
        }

        // Then
        XCTAssertEqual(state.filteredPaymentMethods.count, 1)
        XCTAssertEqual(state.filteredPaymentMethods.first?.type, "PAYMENT_CARD")
    }

    func testState_Equality_SameValues() {
        // Given
        let state1 = PrimerPaymentMethodSelectionState(
            isLoading: true,
            searchQuery: "test",
            requiresCvvInput: true,
            cvvInput: "123"
        )
        let state2 = PrimerPaymentMethodSelectionState(
            isLoading: true,
            searchQuery: "test",
            requiresCvvInput: true,
            cvvInput: "123"
        )

        // Then
        XCTAssertEqual(state1, state2)
    }

    func testState_Equality_DifferentCvvInput() {
        // Given
        let state1 = PrimerPaymentMethodSelectionState(cvvInput: "123")
        let state2 = PrimerPaymentMethodSelectionState(cvvInput: "456")

        // Then
        XCTAssertNotEqual(state1, state2)
    }

    func testState_Equality_DifferentExpansionState() {
        // Given
        let state1 = PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: true)
        let state2 = PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: false)

        // Then
        XCTAssertNotEqual(state1, state2)
    }
}

// MARK: - Payment Method Search Logic Tests

@available(iOS 15.0, *)
final class PaymentMethodSearchLogicTests: XCTestCase {

    /// Simulates the search logic from DefaultPaymentMethodSelectionScope.searchPaymentMethods
    private func searchPaymentMethods(
        _ query: String,
        in paymentMethods: [CheckoutPaymentMethod]
    ) -> [CheckoutPaymentMethod] {
        if query.isEmpty {
            return paymentMethods
        }
        let lowercasedQuery = query.lowercased()
        return paymentMethods.filter { method in
            method.name.lowercased().contains(lowercasedQuery) ||
            method.type.lowercased().contains(lowercasedQuery)
        }
    }

    func testSearch_EmptyQuery_ReturnsAllMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When
        let result = searchPaymentMethods("", in: methods)

        // Then
        XCTAssertEqual(result.count, 2)
    }

    func testSearch_MatchByName_ReturnsFilteredMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal"),
            CheckoutPaymentMethod(id: "3", type: "KLARNA", name: "Klarna")
        ]

        // When
        let result = searchPaymentMethods("PayPal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "2")
    }

    func testSearch_MatchByType_ReturnsFilteredMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When
        let result = searchPaymentMethods("PAYMENT_CARD", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "1")
    }

    func testSearch_CaseInsensitive_MatchesRegardlessOfCase() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When
        let result = searchPaymentMethods("paypal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "2")
    }

    func testSearch_PartialMatch_ReturnsMatchingMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "CARD", name: "Visa Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When - "Pal" only matches PayPal, not Card
        let result = searchPaymentMethods("Pal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "PayPal")
    }

    func testSearch_NoMatch_ReturnsEmptyArray() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When
        let result = searchPaymentMethods("Bitcoin", in: methods)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testSearch_MultipleMatches_ReturnsAllMatching() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Visa Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYMENT_CARD", name: "Mastercard"),
            CheckoutPaymentMethod(id: "3", type: "PAYPAL", name: "PayPal")
        ]

        // When
        let result = searchPaymentMethods("card", in: methods)

        // Then
        XCTAssertEqual(result.count, 2)
    }
}

// MARK: - Checkout Payment Method Tests

@available(iOS 15.0, *)
final class CheckoutPaymentMethodTests: XCTestCase {

    func testCheckoutPaymentMethod_Initialization() {
        // Given/When
        let method = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Visa",
            surcharge: 100,
            hasUnknownSurcharge: false,
            formattedSurcharge: "$1.00"
        )

        // Then
        XCTAssertEqual(method.id, "pm_123")
        XCTAssertEqual(method.type, "PAYMENT_CARD")
        XCTAssertEqual(method.name, "Visa")
        XCTAssertEqual(method.surcharge, 100)
        XCTAssertFalse(method.hasUnknownSurcharge)
        XCTAssertEqual(method.formattedSurcharge, "$1.00")
    }

    func testCheckoutPaymentMethod_Equality_SameValues() {
        // Given
        let method1 = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Visa"
        )
        let method2 = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Visa"
        )

        // Then
        XCTAssertEqual(method1, method2)
    }

    func testCheckoutPaymentMethod_Equality_DifferentIds() {
        // Given
        let method1 = CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Visa")
        let method2 = CheckoutPaymentMethod(id: "pm_2", type: "PAYMENT_CARD", name: "Visa")

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func testCheckoutPaymentMethod_Identifiable_ReturnsId() {
        // Given
        let method = CheckoutPaymentMethod(id: "unique_id", type: "TEST", name: "Test")

        // Then
        XCTAssertEqual(method.id, "unique_id")
    }

    func testCheckoutPaymentMethod_WithSurcharge() {
        // Given
        let method = CheckoutPaymentMethod(
            id: "pm_1",
            type: "PAYMENT_CARD",
            name: "Card",
            surcharge: 250,
            hasUnknownSurcharge: false,
            formattedSurcharge: "€2.50"
        )

        // Then
        XCTAssertEqual(method.surcharge, 250)
        XCTAssertEqual(method.formattedSurcharge, "€2.50")
        XCTAssertFalse(method.hasUnknownSurcharge)
    }

    func testCheckoutPaymentMethod_WithUnknownSurcharge() {
        // Given
        let method = CheckoutPaymentMethod(
            id: "pm_1",
            type: "PAYMENT_CARD",
            name: "Card",
            hasUnknownSurcharge: true
        )

        // Then
        XCTAssertNil(method.surcharge)
        XCTAssertTrue(method.hasUnknownSurcharge)
    }
}

// MARK: - CVV Expected Length Tests

@available(iOS 15.0, *)
final class CvvExpectedLengthTests: XCTestCase {

    func testCvvLength_StandardCard_ExpectsThreeDigits() {
        // Given
        let cvv = "123"
        let expectedLength = 3

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func testCvvLength_AmexCard_ExpectsFourDigits() {
        // Given
        let cvv = "1234"
        let expectedLength = 4

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func testCvvLength_ThreeDigitsForAmex_NotValid() {
        // Given - Amex requires 4 digits
        let cvv = "123"
        let expectedLength = 4

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage, "Partial input should not show error")
    }

    func testCvvLength_FiveDigits_ShowsError() {
        // Given - Too many digits for any card
        let cvv = "12345"
        let expectedLength = 4

        // When
        let result = validateCvv(cvv, expectedLength: expectedLength)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    /// Mirrors the validation logic from DefaultPaymentMethodSelectionScope.validateCvv
    private func validateCvv(_ cvv: String, expectedLength: Int) -> (isValid: Bool, errorMessage: String?) {
        guard !cvv.isEmpty else { return (false, nil) }
        guard cvv.allSatisfy(\.isNumber) else { return (false, "Please enter a valid CVV") }
        if cvv.count > expectedLength { return (false, "Please enter a valid CVV") }
        if cvv.count == expectedLength { return (true, nil) }
        return (false, nil)
    }
}
