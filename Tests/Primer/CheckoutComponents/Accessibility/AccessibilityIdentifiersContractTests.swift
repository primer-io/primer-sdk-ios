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
        (Ids.CardForm.cardNumberField, "checkout_components_card_form_card_number_field"),
        (Ids.CardForm.expiryField, "checkout_components_card_form_expiry_field"),
        (Ids.CardForm.cvcField, "checkout_components_card_form_cvc_field"),
        (Ids.CardForm.cardholderNameField, "checkout_components_card_form_cardholder_name_field"),
        (Ids.CardForm.submitButton, "checkout_components_card_form_submit_button"),
        (Ids.CardForm.inlineNetworkSelectorContainer, "checkout_components_card_form_inline_network_selector"),
        (Ids.CardForm.dropdownNetworkSelectorButton, "checkout_components_card_form_dropdown_network_selector_button"),
        // PaymentSelection
        (Ids.PaymentSelection.header, "checkout_components_payment_selection_header"),
        (Ids.PaymentSelection.showAllButton, "checkout_components_payment_selection_show_all_button"),
        (Ids.PaymentSelection.showOtherWaysButton, "checkout_components_payment_selection_show_other_ways_button"),
        // Vault
        (Ids.Vault.cvvField, "checkout_components_vault_cvv_field"),
        (Ids.Vault.cvvSecurityLabel, "checkout_components_vault_cvv_security_label"),
        (Ids.Vault.payButton, "checkout_components_vault_pay_button"),
        // Common
        (Ids.Common.closeButton, "checkout_components_close_button"),
        (Ids.Common.backButton, "checkout_components_back_button"),
        (Ids.Common.editButton, "checkout_components_edit_button"),
        (Ids.Common.doneButton, "checkout_components_done_button"),
        (Ids.Common.deleteButton, "checkout_components_delete_button"),
        (Ids.Common.cancelButton, "checkout_components_cancel_button"),
        (Ids.Common.loadingIndicator, "checkout_components_loading_indicator"),
        // Error
        (Ids.Error.icon, "checkout_components_error_icon"),
        (Ids.Error.title, "checkout_components_error_title"),
        (Ids.Error.description, "checkout_components_error_description"),
        (Ids.Error.retryButton, "checkout_components_error_retry_button"),
        (Ids.Error.otherPaymentMethodButton, "checkout_components_error_other_payment_method_button"),
        // Success
        (Ids.Success.container, "checkout_components_success_container"),
        (Ids.Success.icon, "checkout_components_success_icon"),
        (Ids.Success.title, "checkout_components_success_title"),
        (Ids.Success.description, "checkout_components_success_description"),
        // AdyenKlarna
        (Ids.AdyenKlarna.container, "checkout_components_adyen_klarna_container"),
        (Ids.AdyenKlarna.logo, "checkout_components_adyen_klarna_logo"),
        (Ids.AdyenKlarna.title, "checkout_components_adyen_klarna_title"),
        (Ids.AdyenKlarna.optionList, "checkout_components_adyen_klarna_option_list"),
        (Ids.AdyenKlarna.backButton, "checkout_components_adyen_klarna_back_button"),
        (Ids.AdyenKlarna.cancelButton, "checkout_components_adyen_klarna_cancel_button"),
        // Klarna
        (Ids.Klarna.container, "checkout_components_klarna_container"),
        (Ids.Klarna.logo, "checkout_components_klarna_logo"),
        (Ids.Klarna.authorizeButton, "checkout_components_klarna_authorize_button"),
        (Ids.Klarna.finalizeButton, "checkout_components_klarna_finalize_button"),
        (Ids.Klarna.paymentViewContainer, "checkout_components_klarna_payment_view_container"),
        (Ids.Klarna.categoriesContainer, "checkout_components_klarna_categories_container"),
        (Ids.Klarna.loadingIndicator, "checkout_components_klarna_loading_indicator"),
        // QRCode
        (Ids.QRCode.container, "checkout_components_qr_code_container"),
        (Ids.QRCode.amountLabel, "checkout_components_qr_code_amount_label"),
        (Ids.QRCode.instructionTitle, "checkout_components_qr_code_instruction_title"),
        (Ids.QRCode.instructionSubtitle, "checkout_components_qr_code_instruction_subtitle"),
        (Ids.QRCode.qrCodeImage, "checkout_components_qr_code_image"),
        (Ids.QRCode.successIcon, "checkout_components_qr_code_success_icon"),
        (Ids.QRCode.failureIcon, "checkout_components_qr_code_failure_icon"),
        (Ids.QRCode.loadingIndicator, "checkout_components_qr_code_loading_indicator"),
        // Ach
        (Ids.Ach.container, "checkout_components_ach_container"),
        (Ids.Ach.loadingIndicator, "checkout_components_ach_loading_indicator"),
        (Ids.Ach.userDetailsContainer, "checkout_components_ach_user_details_container"),
        (Ids.Ach.userDetailsTitle, "checkout_components_ach_user_details_title"),
        (Ids.Ach.firstNameField, "checkout_components_ach_user_details_first_name_field"),
        (Ids.Ach.lastNameField, "checkout_components_ach_user_details_last_name_field"),
        (Ids.Ach.emailField, "checkout_components_ach_user_details_email_field"),
        (Ids.Ach.emailDisclaimer, "checkout_components_ach_user_details_email_disclaimer"),
        (Ids.Ach.submitButton, "checkout_components_ach_submit_button"),
        (Ids.Ach.bankCollectorContainer, "checkout_components_ach_bank_collector_container"),
        (Ids.Ach.mandateContainer, "checkout_components_ach_mandate_container"),
        (Ids.Ach.mandateTitle, "checkout_components_ach_mandate_title"),
        (Ids.Ach.mandateTextContainer, "checkout_components_ach_mandate_text_container"),
        (Ids.Ach.mandateAcceptButton, "checkout_components_ach_mandate_accept_button"),
        (Ids.Ach.mandateDeclineButton, "checkout_components_ach_mandate_decline_button"),
        // SelectCountry
        (Ids.SelectCountry.cancelButton, "checkout_components_select_country_cancel_button"),
        (Ids.SelectCountry.searchField, "checkout_components_select_country_search_field"),
        // BillingAddressRedirect
        (Ids.BillingAddressRedirect.screen, "checkout_components_billing_address_redirect_screen"),
        (Ids.BillingAddressRedirect.countryCodeField, "checkout_components_billing_address_redirect_country_code_field"),
        (Ids.BillingAddressRedirect.addressLine1Field, "checkout_components_billing_address_redirect_address_line1_field"),
        (Ids.BillingAddressRedirect.addressLine2Field, "checkout_components_billing_address_redirect_address_line2_field"),
        (Ids.BillingAddressRedirect.postalCodeField, "checkout_components_billing_address_redirect_postal_code_field"),
        (Ids.BillingAddressRedirect.cityField, "checkout_components_billing_address_redirect_city_field"),
        (Ids.BillingAddressRedirect.stateField, "checkout_components_billing_address_redirect_state_field"),
        (Ids.BillingAddressRedirect.submitButton, "checkout_components_billing_address_redirect_submit_button"),
        (Ids.BillingAddressRedirect.backButton, "checkout_components_billing_address_redirect_back_button"),
        // FormRedirect
        (Ids.FormRedirect.screen, "checkout_components_form_redirect_screen"),
        (Ids.FormRedirect.otpField, "checkout_components_form_redirect_otp_field"),
        (Ids.FormRedirect.phoneField, "checkout_components_form_redirect_phone_field"),
        (Ids.FormRedirect.phonePrefix, "checkout_components_form_redirect_phone_prefix"),
        (Ids.FormRedirect.submitButton, "checkout_components_form_redirect_submit_button"),
        (Ids.FormRedirect.cancelButton, "checkout_components_form_redirect_cancel_button"),
        (Ids.FormRedirect.pendingScreen, "checkout_components_form_redirect_pending_screen"),
        (Ids.FormRedirect.pendingMessage, "checkout_components_form_redirect_pending_message"),
        (Ids.FormRedirect.loadingIndicator, "checkout_components_form_redirect_loading_indicator"),
        // ApplePay
        (Ids.ApplePay.title, "checkout_components_apple_pay_title"),
        (Ids.ApplePay.processingIndicator, "checkout_components_apple_pay_processing_indicator"),
        (Ids.ApplePay.processingLabel, "checkout_components_apple_pay_processing_label"),
        (Ids.ApplePay.unavailableIcon, "checkout_components_apple_pay_unavailable_icon"),
        (Ids.ApplePay.unavailableTitle, "checkout_components_apple_pay_unavailable_title"),
        (Ids.ApplePay.unavailableDescription, "checkout_components_apple_pay_unavailable_description"),
        (Ids.ApplePay.chooseOtherButton, "checkout_components_apple_pay_choose_other_button")
    ]

    func test_constants_matchThePinnedContract() {
        for (actual, expected) in Self.pinnedConstants {
            XCTAssertEqual(actual, expected)
        }
    }

    func test_builders_produceThePinnedShapes() {
        XCTAssertEqual(
            Ids.PaymentSelection.paymentMethodItem("ADYEN_IDEAL"),
            "checkout_components_payment_selection_ADYEN_IDEAL_item"
        )
        XCTAssertEqual(
            Ids.PaymentSelection.vaultedPaymentMethodItem("token_123"),
            "checkout_components_vaulted_payment_method_token_123_item"
        )
        XCTAssertEqual(
            Ids.PaymentSelection.deletePaymentMethodButton("token_123"),
            "checkout_components_vaulted_payment_method_token_123_delete_button"
        )
        XCTAssertEqual(
            Ids.CardForm.billingAddressField("postal_code"),
            "checkout_components_card_form_billing_postal_code_field"
        )
        XCTAssertEqual(
            Ids.CardForm.inlineNetworkSelectorButton(forNetwork: "VISA"),
            "checkout_components_card_form_inline_network_selector_visa_button"
        )
        XCTAssertEqual(
            Ids.SelectCountry.countryItem("NL"),
            "checkout_components_select_country_nl_item"
        )
        XCTAssertEqual(
            Ids.AdyenKlarna.optionButton("PAY_LATER"),
            "checkout_components_adyen_klarna_option_pay_later_button"
        )
        XCTAssertEqual(
            Ids.Klarna.categoryButton("PAY_NOW"),
            "checkout_components_klarna_category_pay_now_button"
        )
        XCTAssertEqual(
            Ids.inputField(within: Ids.CardForm.cardNumberField),
            "checkout_components_card_form_card_number_field_input"
        )
    }

    func test_billingAddressSegments_matchTheSiblingSpellings() {
        XCTAssertEqual(NameTextField.identifierSegment(for: .firstName), "first_name")
        XCTAssertEqual(NameTextField.identifierSegment(for: .lastName), "last_name")
        XCTAssertEqual(NameTextField.identifierSegment(for: .phoneNumber), "phone_number")
        XCTAssertEqual(AddressLineTextField.identifierSegment(for: .addressLine1), "address_line1")
        XCTAssertEqual(AddressLineTextField.identifierSegment(for: .addressLine2), "address_line2")
    }

    /// The naming contract: prefix plus lowercase snake_case. Dynamic segments may carry
    /// uppercase (the raw backend payment-method type), so only static constants are checked.
    func test_constants_followTheNamingShape() {
        let shape = #"^checkout_components(_[a-z0-9]+)+$"#
        for (actual, _) in Self.pinnedConstants {
            XCTAssertNotNil(
                actual.range(of: shape, options: .regularExpression),
                "identifier does not match the naming shape: \(actual)"
            )
        }
    }
}
