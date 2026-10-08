//
//  ExpiryDateInputFieldEditingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

/// Paste hands the delegate the whole string with the selection as the range.
@available(iOS 15.0, *)
@MainActor
final class ExpiryDateInputFieldEditingTests: XCTestCase {

    private var expiryDate = ""
    private var month = ""
    private var year = ""
    private var isValid = false
    private var errorMessage: String?
    private var isFocused = true

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_pasteOverTheWholeDate_replacesIt() async {
        expiryDate = "12/30"

        await type("0331", at: NSRange(location: 0, length: 5))

        XCTAssertEqual(expiryDate, "03/31")
    }

    /// Over the year the old code was right by luck, as the 4 digit cap cut the leftovers off the end.
    func test_pasteOverTheMonth_replacesOnlyTheMonth() async {
        expiryDate = "12/30"

        await type("05", at: NSRange(location: 0, length: 2))

        XCTAssertEqual(expiryDate, "05/30")
    }

    func test_pastedDateWithItsSeparator_keepsItsDigits() async {
        await type("12/31", at: NSRange(location: 0, length: 0))

        XCTAssertEqual(expiryDate, "12/31")
    }

    /// Password managers and Live Text hand over the year in full.
    func test_pastedDateWithAFourDigitYear_keepsItsYear() async {
        await type("12/2031", at: NSRange(location: 0, length: 0))

        XCTAssertEqual(expiryDate, "12/31")
    }

    func test_pastedDateWithAOneDigitMonth_keepsItsMonth() async {
        await type("1/31", at: NSRange(location: 0, length: 0))

        XCTAssertEqual(expiryDate, "01/31")
    }

    func test_pastedMonthAndFullYearWithoutSeparator_keepsBoth() async {
        await type("122031", at: NSRange(location: 0, length: 0))

        XCTAssertEqual(expiryDate, "12/31")
    }

    func test_pasteThatIsNotADate_changesNothing() async {
        expiryDate = "12/30"

        await type("12/3/2031", at: NSRange(location: 0, length: 5))

        XCTAssertEqual(expiryDate, "12/30")
    }

    func test_typingAfterTheSeparator_stillAppends() async {
        expiryDate = "12/3"

        await type("1", at: NSRange(location: 4, length: 0))

        XCTAssertEqual(expiryDate, "12/31")
    }

    private func type(_ string: String, at range: NSRange) async {
        let scope = DefaultCardFormScope(
            checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
        let coordinator = ExpiryDateTextField.Coordinator(
            validationService: DefaultValidationService(),
            expiryDate: Binding(get: { self.expiryDate }, set: { self.expiryDate = $0 }),
            month: Binding(get: { self.month }, set: { self.month = $0 }),
            year: Binding(get: { self.year }, set: { self.year = $0 }),
            isValid: Binding(get: { self.isValid }, set: { self.isValid = $0 }),
            errorMessage: Binding(get: { self.errorMessage }, set: { self.errorMessage = $0 }),
            isFocused: Binding(get: { self.isFocused }, set: { self.isFocused = $0 }),
            scope: scope
        )
        _ = coordinator.textField(UITextField(), shouldChangeCharactersIn: range, replacementString: string)
    }
}
