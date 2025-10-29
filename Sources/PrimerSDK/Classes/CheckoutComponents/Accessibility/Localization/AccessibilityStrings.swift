//
//  AccessibilityStrings.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import Foundation

/// Accessibility-specific localized strings for VoiceOver and screen readers
@available(iOS 15.0, *)
struct AccessibilityStrings {

    // MARK: - Card Form Accessibility Hints

    static let cardNumberHint = NSLocalizedString(
        "accessibility-hint-card-number",
        bundle: Bundle.primerResources,
        value: "Enter your card number",
        comment: "VoiceOver hint for card number input field"
    )

    static let expiryDateHint = NSLocalizedString(
        "accessibility-hint-expiry-date",
        bundle: Bundle.primerResources,
        value: "Enter card expiration date in month month year year format",
        comment: "VoiceOver hint for expiry date input field"
    )

    static let cvvHint = NSLocalizedString(
        "accessibility-hint-cvv",
        bundle: Bundle.primerResources,
        value: "Enter 3 or 4 digit security code from back of card",
        comment: "VoiceOver hint for CVV input field"
    )

    static let cardholderNameHint = NSLocalizedString(
        "accessibility-hint-cardholder-name",
        bundle: Bundle.primerResources,
        value: "Enter name as shown on card",
        comment: "VoiceOver hint for cardholder name input field"
    )

    // MARK: - Billing Address Accessibility Hints

    static let addressLine1Hint = NSLocalizedString(
        "accessibility-hint-address-line1",
        bundle: Bundle.primerResources,
        value: "Enter street address",
        comment: "VoiceOver hint for address line 1 field"
    )

    static let cityHint = NSLocalizedString(
        "accessibility-hint-city",
        bundle: Bundle.primerResources,
        value: "Enter city name",
        comment: "VoiceOver hint for city field"
    )

    static let postalCodeHint = NSLocalizedString(
        "accessibility-hint-postal-code",
        bundle: Bundle.primerResources,
        value: "Enter postal code or ZIP code",
        comment: "VoiceOver hint for postal code field"
    )

    static let countryHint = NSLocalizedString(
        "accessibility-hint-country",
        bundle: Bundle.primerResources,
        value: "Select country",
        comment: "VoiceOver hint for country selector"
    )

    // MARK: - Payment Method Selection Hints

    static let paymentMethodHint = NSLocalizedString(
        "accessibility-hint-payment-method",
        bundle: Bundle.primerResources,
        value: "Double tap to select this payment method",
        comment: "VoiceOver hint for payment method selection"
    )

    // MARK: - VoiceOver Announcements

    static let paymentProcessing = NSLocalizedString(
        "accessibility-announcement-payment-processing",
        bundle: Bundle.primerResources,
        value: "Processing payment, please wait",
        comment: "VoiceOver announcement when payment processing starts"
    )

    static let paymentSuccessful = NSLocalizedString(
        "accessibility-announcement-payment-successful",
        bundle: Bundle.primerResources,
        value: "Payment successful",
        comment: "VoiceOver announcement when payment completes successfully"
    )

    static let paymentFailed = NSLocalizedString(
        "accessibility-announcement-payment-failed",
        bundle: Bundle.primerResources,
        value: "Payment failed. Please try again",
        comment: "VoiceOver announcement when payment fails"
    )

    static func validationErrorsCount(_ count: Int) -> String {
        let format = NSLocalizedString(
            "accessibility-announcement-validation-errors-count",
            bundle: Bundle.primerResources,
            value: "%d errors found",
            comment: "VoiceOver announcement for multiple validation errors"
        )
        return String(format: format, count)
    }

    static func coBadgedCardDetected(_ networks: [String]) -> String {
        let networkList = ListFormatter.localizedString(byJoining: networks)
        let format = NSLocalizedString(
            "accessibility-announcement-cobadged-card",
            bundle: Bundle.primerResources,
            value: "Multiple card networks detected: %@",
            comment: "VoiceOver announcement for co-badged card detection"
        )
        return String(format: format, networkList)
    }

    // MARK: - Button Accessibility Labels

    static let submitButtonLabel = NSLocalizedString(
        "accessibility-label-submit-button",
        bundle: Bundle.primerResources,
        value: "Submit payment",
        comment: "Accessibility label for submit button"
    )

    static let cancelButtonLabel = NSLocalizedString(
        "accessibility-label-cancel-button",
        bundle: Bundle.primerResources,
        value: "Cancel checkout",
        comment: "Accessibility label for cancel button"
    )

    // MARK: - Container Accessibility Labels

    static let cardDetailsContainer = NSLocalizedString(
        "accessibility-label-card-details-container",
        bundle: Bundle.primerResources,
        value: "Card details",
        comment: "Accessibility label for card details form container"
    )

    static let billingAddressContainer = NSLocalizedString(
        "accessibility-label-billing-address-container",
        bundle: Bundle.primerResources,
        value: "Billing address",
        comment: "Accessibility label for billing address form container"
    )
}
