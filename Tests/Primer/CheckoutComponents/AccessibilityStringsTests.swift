//
//  AccessibilityStringsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AccessibilityStringsTests: XCTestCase {

    // MARK: - Card Form Field Strings (Grouped)

    func testCardFormFieldStrings_NotEmpty() {
        // Given: Card form field labels and hints
        let strings = [
            CheckoutComponentsStrings.a11yCardNumberLabel,
            CheckoutComponentsStrings.a11yCardNumberHint,
            CheckoutComponentsStrings.a11yExpiryLabel,
            CheckoutComponentsStrings.a11yExpiryHint,
            CheckoutComponentsStrings.a11yCVCLabel,
            CheckoutComponentsStrings.a11yCVCHint,
            CheckoutComponentsStrings.a11yCardholderNameLabel,
            CheckoutComponentsStrings.a11yCardholderNameHint
        ]

        // Then: All strings should be non-empty
        for string in strings {
            XCTAssertFalse(string.isEmpty, "Card form field string should not be empty")
        }
    }

    func testCardFormLabels_ContainRequiredIndicator() {
        // Given: Required field labels
        let requiredLabels = [
            CheckoutComponentsStrings.a11yCardNumberLabel,
            CheckoutComponentsStrings.a11yExpiryLabel,
            CheckoutComponentsStrings.a11yCVCLabel
        ]

        // Then: Labels should indicate required status for UX clarity
        for label in requiredLabels {
            XCTAssertTrue(
                label.lowercased().contains("required"),
                "Required field label '\(label)' should indicate required status"
            )
        }
    }

    // MARK: - Error Message Strings

    func testErrorMessages_NotEmpty() {
        // Given: Error messages
        let errorMessages = [
            CheckoutComponentsStrings.a11yCardNumberErrorInvalid,
            CheckoutComponentsStrings.a11yCardNumberErrorEmpty,
            CheckoutComponentsStrings.a11yExpiryErrorInvalid,
            CheckoutComponentsStrings.a11yCVCErrorInvalid,
            CheckoutComponentsStrings.a11yGenericError
        ]

        // Then: All error messages should be non-empty
        for message in errorMessages {
            XCTAssertFalse(message.isEmpty, "Error message should not be empty")
        }
    }

    // MARK: - Submit Button Strings

    func testSubmitButtonHint_MentionsDoubleTap() {
        // Given: Submit button hint
        let submitHint = CheckoutComponentsStrings.a11ySubmitButtonHint

        // Then: Hint should mention double-tap gesture for VoiceOver UX
        XCTAssertTrue(
            submitHint.lowercased().contains("double-tap") ||
            submitHint.lowercased().contains("double tap"),
            "Submit hint should mention double-tap gesture"
        )
    }

    func testSubmitButtonLoading_IndicatesWait() {
        // Given: Submit button loading state
        let submitLoading = CheckoutComponentsStrings.a11ySubmitButtonLoading

        // Then: Loading message should indicate wait state for UX clarity
        XCTAssertTrue(
            submitLoading.lowercased().contains("wait") ||
            submitLoading.lowercased().contains("processing"),
            "Loading message should indicate wait"
        )
    }

    // MARK: - Parameterized Strings (Tests Our Logic)

    func testSavedCardLabel_WithParameters() {
        // Given: Card type and expiry parameters
        let testCases = [
            (cardType: "Visa", expiry: "12/25"),
            (cardType: "Mastercard", expiry: "06/26"),
            (cardType: "Amex", expiry: "03/24")
        ]

        // When: Generating saved card labels
        for testCase in testCases {
            let label = CheckoutComponentsStrings.a11ySavedCardLabel(
                cardType: testCase.cardType,
                expiry: testCase.expiry
            )

            // Then: Label should contain both parameters
            XCTAssertFalse(label.isEmpty)
            XCTAssertTrue(label.contains(testCase.cardType), "Label should contain card type")
            XCTAssertTrue(label.contains(testCase.expiry), "Label should contain expiry")
        }
    }

    func testMultipleErrors_WithCount() {
        // Given: Different error counts
        let counts = [1, 3, 5, 10]

        // When: Generating multiple errors message
        for count in counts {
            let message = CheckoutComponentsStrings.a11yMultipleErrors(count)

            // Then: Message should contain error count
            XCTAssertFalse(message.isEmpty)
            XCTAssertTrue(
                message.contains(String(count)),
                "Message should contain count \(count)"
            )
        }
    }

    func testScreenPaymentMethod_WithParameter() {
        // Given: Payment method names
        let paymentMethods = ["Apple Pay", "PayPal", "Credit Card"]

        // When: Generating screen announcements
        for method in paymentMethods {
            let announcement = CheckoutComponentsStrings.a11yScreenPaymentMethod(method)

            // Then: Announcement should contain payment method name
            XCTAssertFalse(announcement.isEmpty)
            XCTAssertTrue(
                announcement.contains(method),
                "Announcement should contain payment method '\(method)'"
            )
        }
    }

    // MARK: - Payment Selection Strings

    func testPaymentSelectionStrings_NotEmpty() {
        // Given: Payment selection strings
        let strings = [
            CheckoutComponentsStrings.a11yPaymentSelectionHeader,
            CheckoutComponentsStrings.a11ySavedCardMasked,
            CheckoutComponentsStrings.a11yActionEdit,
            CheckoutComponentsStrings.a11yActionDelete,
            CheckoutComponentsStrings.a11yActionSetDefault
        ]

        // Then: All strings should be non-empty
        for string in strings {
            XCTAssertFalse(string.isEmpty, "Payment selection string should not be empty")
        }
    }

    // MARK: - Common Strings

    func testCommonStrings_NotEmpty() {
        // Given: Common accessibility strings
        let commonStrings = [
            CheckoutComponentsStrings.a11yRequired,
            CheckoutComponentsStrings.a11yOptional,
            CheckoutComponentsStrings.a11yLoading,
            CheckoutComponentsStrings.a11yClose,
            CheckoutComponentsStrings.a11yBack,
            CheckoutComponentsStrings.a11yDismiss
        ]

        // Then: All common strings should be non-empty
        for string in commonStrings {
            XCTAssertFalse(string.isEmpty, "Common string should not be empty")
        }
    }

    func testRequiredOptionalIndicators_Distinct() {
        // Given: Required and optional indicators
        let required = CheckoutComponentsStrings.a11yRequired
        let optional = CheckoutComponentsStrings.a11yOptional

        // Then: Indicators should be different (important for UX clarity)
        XCTAssertNotEqual(required, optional, "Required and optional indicators should be distinct")
    }

    // MARK: - Screen Announcements

    func testScreenAnnouncements_NotEmpty() {
        // Given: Screen announcement strings
        let announcements = [
            CheckoutComponentsStrings.a11yScreenSuccess,
            CheckoutComponentsStrings.a11yScreenError,
            CheckoutComponentsStrings.a11yScreenCountrySelection,
            CheckoutComponentsStrings.a11yScreenLoadingPaymentMethods
        ]

        // Then: All screen announcements should be non-empty
        for announcement in announcements {
            XCTAssertFalse(announcement.isEmpty, "Screen announcement should not be empty")
        }
    }
}
