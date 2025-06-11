//
//  CardPaymentLocalizable.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import Foundation

@available(iOS 15.0, *)
internal enum CardPaymentLocalizable {
    // MARK: - Headers
    static let payWithCardTitle = NSLocalizedString(
        "card_payment.title.pay_with_card",
        value: "Pay with card",
        comment: "Title for card payment form"
    )
    
    static let backButton = NSLocalizedString(
        "card_payment.button.back",
        value: "Back",
        comment: "Back button text"
    )
    
    static let cancelButton = NSLocalizedString(
        "card_payment.button.cancel",
        value: "Cancel",
        comment: "Cancel button text"
    )
    
    // MARK: - Field Labels
    static let cardNumberLabel = NSLocalizedString(
        "card_payment.field.card_number",
        value: "Card number",
        comment: "Label for card number field"
    )
    
    static let expiryDateLabel = NSLocalizedString(
        "card_payment.field.expiry_date",
        value: "Expiry (MM/YY)",
        comment: "Label for expiry date field"
    )
    
    static let cvvLabel = NSLocalizedString(
        "card_payment.field.cvv",
        value: "CVV",
        comment: "Label for CVV field"
    )
    
    static let nameOnCardLabel = NSLocalizedString(
        "card_payment.field.name_on_card",
        value: "Name on card",
        comment: "Label for cardholder name field"
    )
    
    // MARK: - Placeholders
    static let cardNumberPlaceholder = NSLocalizedString(
        "card_payment.placeholder.card_number",
        value: "1234 1234 1234 1234",
        comment: "Placeholder for card number field"
    )
    
    static let expiryDatePlaceholder = NSLocalizedString(
        "card_payment.placeholder.expiry_date",
        value: "12/23",
        comment: "Placeholder for expiry date field"
    )
    
    static let cvvPlaceholder = NSLocalizedString(
        "card_payment.placeholder.cvv",
        value: "123",
        comment: "Placeholder for CVV field"
    )
    
    static let nameOnCardPlaceholder = NSLocalizedString(
        "card_payment.placeholder.name_on_card",
        value: "Full name",
        comment: "Placeholder for cardholder name field"
    )
    
    // MARK: - Buttons
    static let payButton = NSLocalizedString(
        "card_payment.button.pay",
        value: "Pay",
        comment: "Pay button text"
    )
    
    // MARK: - Accessibility Labels
    static let cardNetworkIconsDescription = NSLocalizedString(
        "card_payment.accessibility.card_networks",
        value: "Accepted payment methods",
        comment: "Accessibility description for card network icons"
    )
    
    static let cardNumberFieldDescription = NSLocalizedString(
        "card_payment.accessibility.card_number_field",
        value: "Enter your card number",
        comment: "Accessibility description for card number field"
    )
    
    static let expiryDateFieldDescription = NSLocalizedString(
        "card_payment.accessibility.expiry_date_field",
        value: "Enter card expiry date in MM/YY format",
        comment: "Accessibility description for expiry date field"
    )
    
    static let cvvFieldDescription = NSLocalizedString(
        "card_payment.accessibility.cvv_field",
        value: "Enter card security code",
        comment: "Accessibility description for CVV field"
    )
    
    static let nameOnCardFieldDescription = NSLocalizedString(
        "card_payment.accessibility.name_on_card_field",
        value: "Enter cardholder name as shown on card",
        comment: "Accessibility description for name on card field"
    )
    
    // MARK: - Accessibility Hints
    static let payButtonHintEnabled = NSLocalizedString(
        "card_payment.accessibility.pay_button_hint_enabled",
        value: "Double tap to process payment",
        comment: "Accessibility hint for enabled pay button"
    )
    
    static let payButtonHintDisabled = NSLocalizedString(
        "card_payment.accessibility.pay_button_hint_disabled",
        value: "Complete all fields to enable payment",
        comment: "Accessibility hint for disabled pay button"
    )
    
    static let backButtonHint = NSLocalizedString(
        "card_payment.accessibility.back_button_hint",
        value: "Double tap to return to payment methods",
        comment: "Accessibility hint for back button"
    )
    
    static let cancelButtonHint = NSLocalizedString(
        "card_payment.accessibility.cancel_button_hint",
        value: "Double tap to cancel payment",
        comment: "Accessibility hint for cancel button"
    )
    
    // MARK: - Error Messages (for accessibility announcements)
    static let formHasErrorsAnnouncement = NSLocalizedString(
        "card_payment.accessibility.form_has_errors",
        value: "Form contains errors. Please review and correct.",
        comment: "Accessibility announcement when form has validation errors"
    )
    
    static let paymentProcessingAnnouncement = NSLocalizedString(
        "card_payment.accessibility.payment_processing",
        value: "Processing payment, please wait",
        comment: "Accessibility announcement when payment is being processed"
    )
    
    // MARK: - State Descriptions
    static let fieldRequiredDescription = NSLocalizedString(
        "card_payment.accessibility.field_required",
        value: "Required field",
        comment: "Accessibility description for required fields"
    )
    
    static let fieldOptionalDescription = NSLocalizedString(
        "card_payment.accessibility.field_optional",
        value: "Optional field",
        comment: "Accessibility description for optional fields"
    )
    
    static let fieldErrorDescription = NSLocalizedString(
        "card_payment.accessibility.field_error",
        value: "Field has error",
        comment: "Accessibility description for fields with errors"
    )
    
    static let fieldValidDescription = NSLocalizedString(
        "card_payment.accessibility.field_valid",
        value: "Field is valid",
        comment: "Accessibility description for valid fields"
    )
    
    // MARK: - Card Network Names (for accessibility)
    static let visaCardName = NSLocalizedString(
        "card_payment.card_network.visa",
        value: "Visa",
        comment: "Visa card network name"
    )
    
    static let mastercardName = NSLocalizedString(
        "card_payment.card_network.mastercard",
        value: "Mastercard",
        comment: "Mastercard network name"
    )
    
    static let amexName = NSLocalizedString(
        "card_payment.card_network.amex",
        value: "American Express",
        comment: "American Express card network name"
    )
    
    static let discoverName = NSLocalizedString(
        "card_payment.card_network.discover",
        value: "Discover",
        comment: "Discover card network name"
    )
    
    static let dinersName = NSLocalizedString(
        "card_payment.card_network.diners",
        value: "Diners Club",
        comment: "Diners Club card network name"
    )
    
    static let cbName = NSLocalizedString(
        "card_payment.card_network.cb",
        value: "CB",
        comment: "CB card network name"
    )
    
    static let unknownCardName = NSLocalizedString(
        "card_payment.card_network.unknown",
        value: "Unknown card",
        comment: "Unknown card network name"
    )
    
    // MARK: - Helper Functions for Dynamic Content
    static func fieldErrorAnnouncement(fieldName: String, error: String) -> String {
        let template = NSLocalizedString(
            "card_payment.accessibility.field_error_announcement",
            value: "%@ has error: %@",
            comment: "Accessibility announcement for field errors. First %@ is field name, second %@ is error message"
        )
        return String(format: template, fieldName, error)
    }
    
    static func payButtonTextWithAmount(_ amount: String?) -> String {
        guard let amount = amount else {
            return payButton
        }
        
        let template = NSLocalizedString(
            "card_payment.button.pay_with_amount",
            value: "Pay %@",
            comment: "Pay button text with amount. %@ is the payment amount"
        )
        return String(format: template, amount)
    }
    
    static func cardNetworkDetectedAnnouncement(_ networkName: String) -> String {
        let template = NSLocalizedString(
            "card_payment.accessibility.card_network_detected",
            value: "%@ card detected",
            comment: "Accessibility announcement when card network is detected. %@ is the card network name"
        )
        return String(format: template, networkName)
    }
}