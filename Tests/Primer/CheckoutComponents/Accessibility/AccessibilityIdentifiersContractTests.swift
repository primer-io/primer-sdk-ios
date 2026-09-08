//
//  AccessibilityIdentifiersContractTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Pins every identifier string in the registry. The identifiers are a cross-repo contract:
/// the E2E page objects in the e2e-tests repo select on them, so a rename that looks free in
/// this repo breaks another one. A failure here means the CC identifier convention doc and the
/// E2E page objects must change together with the code.
@available(iOS 15.0, *)
final class AccessibilityIdentifiersContractTests: XCTestCase {

    private typealias Ids = AccessibilityIdentifiers

    private static let pinnedConstants: [(actual: String, expected: String)] = [
        // CardForm
        (Ids.CardForm.cardNumberField, "primer_checkout_components_card_form_card_number_field"),
        (Ids.CardForm.expiryField, "primer_checkout_components_card_form_expiry_field"),
        (Ids.CardForm.cvcField, "primer_checkout_components_card_form_cvc_field"),
        (Ids.CardForm.cardholderNameField, "primer_checkout_components_card_form_cardholder_name_field"),
        (Ids.CardForm.submitButton, "primer_checkout_components_card_form_submit_button"),
        (Ids.CardForm.billingCityField, "primer_checkout_components_card_form_billing_city_field"),
        (Ids.CardForm.billingPostalCodeField, "primer_checkout_components_card_form_billing_postal_code_field"),
        (Ids.CardForm.billingStateField, "primer_checkout_components_card_form_billing_state_field"),
        (Ids.CardForm.billingEmailField, "primer_checkout_components_card_form_billing_email_field"),
        (Ids.CardForm.inlineNetworkSelectorContainer, "primer_checkout_components_card_form_inline_network_selector"),
        (Ids.CardForm.dropdownNetworkSelectorButton, "primer_checkout_components_card_form_dropdown_network_selector_button"),
        // PaymentSelection
        (Ids.PaymentSelection.header, "primer_checkout_components_payment_selection_header"),
        (Ids.PaymentSelection.showAllButton, "primer_checkout_components_payment_selection_show_all_button"),
        (Ids.PaymentSelection.showOtherWaysButton, "primer_checkout_components_payment_selection_show_other_ways_button"),
        // Vault
        (Ids.Vault.cvvField, "primer_checkout_components_vault_cvv_field"),
        (Ids.Vault.cvvSecurityLabel, "primer_checkout_components_vault_cvv_security_label"),
        (Ids.Vault.payButton, "primer_checkout_components_vault_pay_button"),
        // Common
        (Ids.Common.closeButton, "primer_checkout_components_close_button"),
        (Ids.Common.backButton, "primer_checkout_components_back_button"),
        (Ids.Common.editButton, "primer_checkout_components_edit_button"),
        (Ids.Common.doneButton, "primer_checkout_components_done_button"),
        (Ids.Common.deleteButton, "primer_checkout_components_delete_button"),
        (Ids.Common.cancelButton, "primer_checkout_components_cancel_button"),
        (Ids.Common.loadingIndicator, "primer_checkout_components_loading_indicator"),
        // Error
        (Ids.Error.icon, "primer_checkout_components_error_icon"),
        (Ids.Error.title, "primer_checkout_components_error_title"),
        (Ids.Error.description, "primer_checkout_components_error_description"),
        (Ids.Error.retryButton, "primer_checkout_components_error_retry_button"),
        (Ids.Error.otherPaymentMethodButton, "primer_checkout_components_error_other_payment_method_button"),
        // Success
        (Ids.Success.container, "primer_checkout_components_success_container"),
        (Ids.Success.icon, "primer_checkout_components_success_icon"),
        (Ids.Success.title, "primer_checkout_components_success_title"),
        (Ids.Success.description, "primer_checkout_components_success_description"),
        // AdyenKlarna
        (Ids.AdyenKlarna.container, "primer_checkout_components_adyen_klarna_container"),
        (Ids.AdyenKlarna.logo, "primer_checkout_components_adyen_klarna_logo"),
        (Ids.AdyenKlarna.title, "primer_checkout_components_adyen_klarna_title"),
        (Ids.AdyenKlarna.optionList, "primer_checkout_components_adyen_klarna_option_list"),
        (Ids.AdyenKlarna.backButton, "primer_checkout_components_adyen_klarna_back_button"),
        (Ids.AdyenKlarna.cancelButton, "primer_checkout_components_adyen_klarna_cancel_button"),
        // Klarna
        (Ids.Klarna.container, "primer_checkout_components_klarna_container"),
        (Ids.Klarna.logo, "primer_checkout_components_klarna_logo"),
        (Ids.Klarna.authorizeButton, "primer_checkout_components_klarna_authorize_button"),
        (Ids.Klarna.finalizeButton, "primer_checkout_components_klarna_finalize_button"),
        (Ids.Klarna.paymentViewContainer, "primer_checkout_components_klarna_payment_view_container"),
        (Ids.Klarna.categoriesContainer, "primer_checkout_components_klarna_categories_container"),
        (Ids.Klarna.loadingIndicator, "primer_checkout_components_klarna_loading_indicator"),
        // QRCode
        (Ids.QRCode.container, "primer_checkout_components_qr_code_container"),
        (Ids.QRCode.amountLabel, "primer_checkout_components_qr_code_amount_label"),
        (Ids.QRCode.instructionTitle, "primer_checkout_components_qr_code_instruction_title"),
        (Ids.QRCode.instructionSubtitle, "primer_checkout_components_qr_code_instruction_subtitle"),
        (Ids.QRCode.qrCodeImage, "primer_checkout_components_qr_code_image"),
        (Ids.QRCode.successIcon, "primer_checkout_components_qr_code_success_icon"),
        (Ids.QRCode.failureIcon, "primer_checkout_components_qr_code_failure_icon"),
        (Ids.QRCode.loadingIndicator, "primer_checkout_components_qr_code_loading_indicator"),
        // Ach
        (Ids.Ach.container, "primer_checkout_components_ach_container"),
        (Ids.Ach.loadingIndicator, "primer_checkout_components_ach_loading_indicator"),
        (Ids.Ach.userDetailsContainer, "primer_checkout_components_ach_user_details_container"),
        (Ids.Ach.userDetailsTitle, "primer_checkout_components_ach_user_details_title"),
        (Ids.Ach.firstNameField, "primer_checkout_components_ach_user_details_first_name_field"),
        (Ids.Ach.lastNameField, "primer_checkout_components_ach_user_details_last_name_field"),
        (Ids.Ach.emailField, "primer_checkout_components_ach_user_details_email_field"),
        (Ids.Ach.emailDisclaimer, "primer_checkout_components_ach_user_details_email_disclaimer"),
        (Ids.Ach.submitButton, "primer_checkout_components_ach_submit_button"),
        (Ids.Ach.bankCollectorContainer, "primer_checkout_components_ach_bank_collector_container"),
        (Ids.Ach.mandateContainer, "primer_checkout_components_ach_mandate_container"),
        (Ids.Ach.mandateTitle, "primer_checkout_components_ach_mandate_title"),
        (Ids.Ach.mandateTextContainer, "primer_checkout_components_ach_mandate_text_container"),
        (Ids.Ach.mandateAcceptButton, "primer_checkout_components_ach_mandate_accept_button"),
        (Ids.Ach.mandateDeclineButton, "primer_checkout_components_ach_mandate_decline_button"),
        // SelectCountry
        (Ids.SelectCountry.cancelButton, "primer_checkout_components_select_country_cancel_button"),
        (Ids.SelectCountry.searchField, "primer_checkout_components_select_country_search_field"),
        // BillingAddressRedirect
        (Ids.BillingAddressRedirect.screen, "primer_checkout_components_billing_address_redirect_screen"),
        (Ids.BillingAddressRedirect.countryCodeField, "primer_checkout_components_billing_address_redirect_country_code_field"),
        (Ids.BillingAddressRedirect.addressLine1Field, "primer_checkout_components_billing_address_redirect_address_line1_field"),
        (Ids.BillingAddressRedirect.addressLine2Field, "primer_checkout_components_billing_address_redirect_address_line2_field"),
        (Ids.BillingAddressRedirect.postalCodeField, "primer_checkout_components_billing_address_redirect_postal_code_field"),
        (Ids.BillingAddressRedirect.cityField, "primer_checkout_components_billing_address_redirect_city_field"),
        (Ids.BillingAddressRedirect.stateField, "primer_checkout_components_billing_address_redirect_state_field"),
        (Ids.BillingAddressRedirect.submitButton, "primer_checkout_components_billing_address_redirect_submit_button"),
        (Ids.BillingAddressRedirect.backButton, "primer_checkout_components_billing_address_redirect_back_button"),
        // FormRedirect
        (Ids.FormRedirect.screen, "primer_checkout_components_form_redirect_screen"),
        (Ids.FormRedirect.otpField, "primer_checkout_components_form_redirect_otp_field"),
        (Ids.FormRedirect.phoneField, "primer_checkout_components_form_redirect_phone_field"),
        (Ids.FormRedirect.phonePrefix, "primer_checkout_components_form_redirect_phone_prefix"),
        (Ids.FormRedirect.submitButton, "primer_checkout_components_form_redirect_submit_button"),
        (Ids.FormRedirect.cancelButton, "primer_checkout_components_form_redirect_cancel_button"),
        (Ids.FormRedirect.pendingScreen, "primer_checkout_components_form_redirect_pending_screen"),
        (Ids.FormRedirect.pendingMessage, "primer_checkout_components_form_redirect_pending_message"),
        (Ids.FormRedirect.loadingIndicator, "primer_checkout_components_form_redirect_loading_indicator"),
        // ApplePay
        (Ids.ApplePay.title, "primer_checkout_components_apple_pay_title"),
        (Ids.ApplePay.processingIndicator, "primer_checkout_components_apple_pay_processing_indicator"),
        (Ids.ApplePay.processingLabel, "primer_checkout_components_apple_pay_processing_label"),
        (Ids.ApplePay.unavailableIcon, "primer_checkout_components_apple_pay_unavailable_icon"),
        (Ids.ApplePay.unavailableTitle, "primer_checkout_components_apple_pay_unavailable_title"),
        (Ids.ApplePay.unavailableDescription, "primer_checkout_components_apple_pay_unavailable_description"),
        (Ids.ApplePay.chooseOtherButton, "primer_checkout_components_apple_pay_choose_other_button")
    ]

    func test_constants_matchThePinnedContract() {
        for (actual, expected) in Self.pinnedConstants {
            XCTAssertEqual(actual, expected)
        }
    }

    func test_builders_produceThePinnedShapes() {
        XCTAssertEqual(
            Ids.PaymentSelection.paymentMethodItem("ADYEN_IDEAL"),
            "primer_checkout_components_payment_selection_ADYEN_IDEAL_item"
        )
        XCTAssertEqual(
            Ids.PaymentSelection.vaultedPaymentMethodItem("token_123"),
            "primer_checkout_components_vaulted_payment_method_token_123_item"
        )
        XCTAssertEqual(
            Ids.PaymentSelection.deletePaymentMethodButton("token_123"),
            "primer_checkout_components_vaulted_payment_method_token_123_delete_button"
        )
        XCTAssertEqual(
            Ids.CardForm.billingAddressField("postal_code"),
            "primer_checkout_components_card_form_billing_postal_code_field"
        )
        XCTAssertEqual(
            Ids.CardForm.inlineNetworkSelectorButton(forNetwork: "VISA"),
            "primer_checkout_components_card_form_inline_network_selector_visa_button"
        )
        XCTAssertEqual(
            Ids.SelectCountry.countryItem("NL"),
            "primer_checkout_components_select_country_nl_item"
        )
        XCTAssertEqual(
            Ids.AdyenKlarna.optionButton("PAY_LATER"),
            "primer_checkout_components_adyen_klarna_option_pay_later_button"
        )
        XCTAssertEqual(
            Ids.Klarna.categoryButton("PAY_NOW"),
            "primer_checkout_components_klarna_category_pay_now_button"
        )
        XCTAssertEqual(
            Ids.inputField(within: Ids.CardForm.cardNumberField),
            "primer_checkout_components_card_form_card_number_field_input"
        )
    }

    func test_billingAddressSegments_matchTheSiblingSpellings() {
        let cases: [(PrimerInputElementType, String)] = [
            (.firstName, "first_name"),
            (.lastName, "last_name"),
            (.phoneNumber, "phone_number"),
            (.addressLine1, "address_line1"),
            (.addressLine2, "address_line2")
        ]
        for (inputType, segment) in cases {
            XCTAssertEqual(
                Ids.CardForm.billingAddressInput(for: inputType, fallback: "unused"),
                "primer_checkout_components_card_form_billing_\(segment)_field_input"
            )
        }
        // An input type the wrapper does not name falls back to the wrapper's own segment.
        XCTAssertEqual(
            Ids.CardForm.billingAddressInput(for: .cardNumber, fallback: "name"),
            "primer_checkout_components_card_form_billing_name_field_input"
        )
    }

    /// The naming contract: prefix plus lowercase snake_case. Dynamic segments may carry
    /// uppercase (the raw backend payment-method type), so only static constants are checked.
    func test_constants_followTheNamingShape() {
        let shape = #"^primer_checkout_components(_[a-z0-9]+)+$"#
        for (actual, _) in Self.pinnedConstants {
            XCTAssertNotNil(
                actual.range(of: shape, options: .regularExpression),
                "identifier does not match the naming shape: \(actual)"
            )
        }
    }
}
