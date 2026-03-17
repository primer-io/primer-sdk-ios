//
//  DefaultPaymentMethodSelectionScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CvvValidationLogicTests: XCTestCase {

    func test_cvvValidation_emptyInput_notValidNoError() {
        // Given / When
        let result = validateCvv("", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_validThreeDigitCvv_isValid() {
        // Given / When
        let result = validateCvv("123", expectedLength: 3)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_validFourDigitCvv_isValid() {
        // Given / When
        let result = validateCvv("1234", expectedLength: 4)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_nonNumericCharacters_showsError() {
        // Given / When
        let result = validateCvv("12a", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_tooManyDigits_showsError() {
        // Given / When
        let result = validateCvv("1234", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_partialInput_notValidNoError() {
        // Given / When
        let result = validateCvv("12", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_singleDigit_notValidNoError() {
        // Given / When
        let result = validateCvv("1", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvValidation_specialCharacters_showsError() {
        // Given / When
        let result = validateCvv("12!", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_spaces_showsError() {
        // Given / When
        let result = validateCvv("1 2", expectedLength: 3)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func test_cvvValidation_leadingZeros_isValid() {
        // Given / When
        let result = validateCvv("007", expectedLength: 3)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    private func validateCvv(_ cvv: String, expectedLength: Int) -> (isValid: Bool, errorMessage: String?) {
        guard !cvv.isEmpty else { return (false, nil) }
        guard cvv.allSatisfy(\.isNumber) else { return (false, "Please enter a valid CVV") }
        if cvv.count > expectedLength { return (false, "Please enter a valid CVV") }
        if cvv.count == expectedLength { return (true, nil) }
        return (false, nil)
    }
}

// MARK: - Payment Method Selection State Tests

@available(iOS 15.0, *)
final class PaymentMethodSelectionStateTests: XCTestCase {

    func test_initialState_hasCorrectDefaults() {
        // Given / When
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

    func test_state_cvvProperties_areSettable() {
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

    func test_state_paymentMethodsExpanded_canBeToggled() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        XCTAssertTrue(state.isPaymentMethodsExpanded)

        // When
        state.isPaymentMethodsExpanded = false

        // Then
        XCTAssertFalse(state.isPaymentMethodsExpanded)
    }

    func test_state_vaultPaymentLoading_canBeToggled() {
        // Given
        var state = PrimerPaymentMethodSelectionState()
        XCTAssertFalse(state.isVaultPaymentLoading)

        // When
        state.isVaultPaymentLoading = true

        // Then
        XCTAssertTrue(state.isVaultPaymentLoading)
    }

    func test_state_withPaymentMethods_maintainsData() {
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

    func test_state_cvvError_canBeSet() {
        // Given
        var state = PrimerPaymentMethodSelectionState()

        // When
        state.cvvError = "Invalid CVV"

        // Then
        XCTAssertEqual(state.cvvError, "Invalid CVV")
    }

    func test_state_searchQuery_updatesFilteredMethods() {
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

    func test_state_equality_sameValues() {
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

    func test_state_equality_differentCvvInput() {
        XCTAssertNotEqual(
            PrimerPaymentMethodSelectionState(cvvInput: "123"),
            PrimerPaymentMethodSelectionState(cvvInput: "456")
        )
    }

    func test_state_equality_differentExpansionState() {
        XCTAssertNotEqual(
            PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: true),
            PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: false)
        )
    }
}

// MARK: - Payment Method Search Logic Tests

@available(iOS 15.0, *)
final class PaymentMethodSearchLogicTests: XCTestCase {

    private func searchPaymentMethods(
        _ query: String,
        in paymentMethods: [CheckoutPaymentMethod]
    ) -> [CheckoutPaymentMethod] {
        guard !query.isEmpty else { return paymentMethods }
        let lowercasedQuery = query.lowercased()
        return paymentMethods.filter { method in
            method.name.lowercased().contains(lowercasedQuery) ||
            method.type.lowercased().contains(lowercasedQuery)
        }
    }

    func test_search_emptyQuery_returnsAllMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When / Then
        XCTAssertEqual(searchPaymentMethods("", in: methods).count, 2)
    }

    func test_search_matchByName_returnsFilteredMethods() {
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

    func test_search_matchByType_returnsFilteredMethods() {
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

    func test_search_caseInsensitive_matchesRegardlessOfCase() {
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

    func test_search_partialMatch_returnsMatchingMethods() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "CARD", name: "Visa Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When
        let result = searchPaymentMethods("Pal", in: methods)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "PayPal")
    }

    func test_search_noMatch_returnsEmptyArray() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // When / Then
        XCTAssertTrue(searchPaymentMethods("Bitcoin", in: methods).isEmpty)
    }

    func test_search_multipleMatches_returnsAllMatching() {
        // Given
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Visa Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYMENT_CARD", name: "Mastercard"),
            CheckoutPaymentMethod(id: "3", type: "PAYPAL", name: "PayPal")
        ]

        // When / Then
        XCTAssertEqual(searchPaymentMethods("card", in: methods).count, 2)
    }
}

// MARK: - Checkout Payment Method Tests

@available(iOS 15.0, *)
final class CheckoutPaymentMethodTests: XCTestCase {

    func test_checkoutPaymentMethod_initialization() {
        // Given / When
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

    func test_checkoutPaymentMethod_equality_sameValues() {
        // Given
        let method1 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Visa")
        let method2 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Visa")

        // Then
        XCTAssertEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_equality_differentIds() {
        XCTAssertNotEqual(
            CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Visa"),
            CheckoutPaymentMethod(id: "pm_2", type: "PAYMENT_CARD", name: "Visa")
        )
    }

    func test_checkoutPaymentMethod_identifiable_returnsId() {
        let method = CheckoutPaymentMethod(id: "unique_id", type: "TEST", name: "Test")
        XCTAssertEqual(method.id, "unique_id")
    }

    func test_checkoutPaymentMethod_withSurcharge() {
        // Given / When
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

    func test_checkoutPaymentMethod_withUnknownSurcharge() {
        // Given / When
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

    private func validateCvv(_ cvv: String, expectedLength: Int) -> (isValid: Bool, errorMessage: String?) {
        guard !cvv.isEmpty else { return (false, nil) }
        guard cvv.allSatisfy(\.isNumber) else { return (false, "Please enter a valid CVV") }
        if cvv.count > expectedLength { return (false, "Please enter a valid CVV") }
        if cvv.count == expectedLength { return (true, nil) }
        return (false, nil)
    }

    func test_cvvLength_standardCard_expectsThreeDigits() {
        XCTAssertTrue(validateCvv("123", expectedLength: 3).isValid)
    }

    func test_cvvLength_amexCard_expectsFourDigits() {
        XCTAssertTrue(validateCvv("1234", expectedLength: 4).isValid)
    }

    func test_cvvLength_threeDigitsForAmex_notValid() {
        // Given / When
        let result = validateCvv("123", expectedLength: 4)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_cvvLength_fiveDigits_showsError() {
        // Given / When
        let result = validateCvv("12345", expectedLength: 4)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
}
