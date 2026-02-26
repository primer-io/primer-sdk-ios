//
//  AccessibilityIdentifiers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum AccessibilityIdentifiers {

  enum CardForm {
    static let container = "checkout_components_card_form_container"
    static let cardNumberField = "checkout_components_card_form_card_number_field"
    static let expiryField = "checkout_components_card_form_expiry_field"
    static let cvcField = "checkout_components_card_form_cvc_field"
    static let cardholderNameField = "checkout_components_card_form_cardholder_name_field"
    static let saveButton = "checkout_components_card_form_save_button"

    static func billingAddressField(_ field: String) -> String {
      "checkout_components_card_form_billing_\(field)_field"
    }

    static func cardNetworkBadge(_ network: String) -> String {
      "checkout_components_card_form_\(network.lowercased())_badge"
    }

    static let inlineNetworkSelectorContainer =
      "checkout_components_card_form_inline_network_selector"

    static func inlineNetworkSelectorButton(forNetwork network: String) -> String {
      "checkout_components_card_form_inline_network_selector_\(network.lowercased())_button"
    }

    static let dropdownNetworkSelectorButton =
      "checkout_components_card_form_dropdown_network_selector_button"
  }

  enum PaymentSelection {
    static let header = "checkout_components_payment_selection_header"
    static let showAllButton = "checkout_components_payment_selection_show_all_button"
    static let showOtherWaysButton = "checkout_components_payment_selection_show_other_ways_button"

    static func cardItem(_ lastFour: String) -> String {
      "checkout_components_payment_selection_card_\(lastFour)_item"
    }

    static func paymentMethodItem(_ type: String, uniqueId: String?) -> String {
      if let uniqueId {
        return "checkout_components_payment_selection_\(type)_\(uniqueId)_item"
      }
      return "checkout_components_payment_selection_\(type)_item"
    }

    static func vaultedPaymentMethodItem(_ id: String) -> String {
      "checkout_components_vaulted_payment_method_\(id)_item"
    }

    static func deletePaymentMethodButton(_ id: String) -> String {
      "checkout_components_vaulted_payment_method_\(id)_delete_button"
    }
  }

  enum Vault {
    static let cvvField = "checkout_components_vault_cvv_field"
    static let cvvSecurityLabel = "checkout_components_vault_cvv_security_label"
    static let payButton = "checkout_components_vault_pay_button"
  }

  enum Common {
    static let submitButton = "checkout_components_submit_button"
    static let closeButton = "checkout_components_close_button"
    static let backButton = "checkout_components_back_button"
    static let editButton = "checkout_components_edit_button"
    static let doneButton = "checkout_components_done_button"
    static let deleteButton = "checkout_components_delete_button"
    static let cancelButton = "checkout_components_cancel_button"
    static let loadingIndicator = "checkout_components_loading_indicator"
  }

  enum Error {
    static let messageContainer = "checkout_components_error_message_container"
    static let dismissButton = "checkout_components_error_dismiss_button"
  }

  enum PayPal {
    static let container = "checkout_components_paypal_container"
    static let logo = "checkout_components_paypal_logo"
    static let submitButton = "checkout_components_paypal_submit_button"
  }

  enum Klarna {
    static let container = "checkout_components_klarna_container"
    static let logo = "checkout_components_klarna_logo"
    static let authorizeButton = "checkout_components_klarna_authorize_button"
    static let finalizeButton = "checkout_components_klarna_finalize_button"
    static let paymentViewContainer = "checkout_components_klarna_payment_view_container"
    static let categoriesContainer = "checkout_components_klarna_categories_container"
    static let loadingIndicator = "checkout_components_klarna_loading_indicator"

    static func categoryButton(_ categoryId: String) -> String {
      "checkout_components_klarna_category_\(categoryId.lowercased())_button"
    }
  }

  enum QRCode {
    static let container = "checkout_components_qr_code_container"
    static let amountLabel = "checkout_components_qr_code_amount_label"
    static let instructionTitle = "checkout_components_qr_code_instruction_title"
    static let instructionSubtitle = "checkout_components_qr_code_instruction_subtitle"
    static let qrCodeImage = "checkout_components_qr_code_image"
    static let successIcon = "checkout_components_qr_code_success_icon"
    static let failureIcon = "checkout_components_qr_code_failure_icon"
    static let loadingIndicator = "checkout_components_qr_code_loading_indicator"
  }

  enum Ach {
    static let container = "checkout_components_ach_container"
    static let loadingIndicator = "checkout_components_ach_loading_indicator"

    // User Details
    static let userDetailsContainer = "checkout_components_ach_user_details_container"
    static let userDetailsTitle = "checkout_components_ach_user_details_title"
    static let firstNameField = "checkout_components_ach_user_details_first_name_field"
    static let lastNameField = "checkout_components_ach_user_details_last_name_field"
    static let emailField = "checkout_components_ach_user_details_email_field"
    static let emailDisclaimer = "checkout_components_ach_user_details_email_disclaimer"
    static let submitButton = "checkout_components_ach_submit_button"

    // Bank Collector
    static let bankCollectorContainer = "checkout_components_ach_bank_collector_container"

    // Mandate
    static let mandateContainer = "checkout_components_ach_mandate_container"
    static let mandateTitle = "checkout_components_ach_mandate_title"
    static let mandateTextContainer = "checkout_components_ach_mandate_text_container"
    static let mandateAcceptButton = "checkout_components_ach_mandate_accept_button"
    static let mandateDeclineButton = "checkout_components_ach_mandate_decline_button"
  }

  enum WebRedirect {
    static let container = "checkout_components_web_redirect_container"
    static let logo = "checkout_components_web_redirect_logo"
    static let title = "checkout_components_web_redirect_title"
    static let description = "checkout_components_web_redirect_description"
    static let surcharge = "checkout_components_web_redirect_surcharge"
    static let submitButton = "checkout_components_web_redirect_submit_button"
    static let backButton = "checkout_components_web_redirect_back_button"
    static let cancelButton = "checkout_components_web_redirect_cancel_button"
  }

  enum FormRedirect {
    static let screen = "checkout_components_form_redirect_screen"
    static let otpField = "checkout_components_form_redirect_otp_field"
    static let phoneField = "checkout_components_form_redirect_phone_field"
    static let phonePrefix = "checkout_components_form_redirect_phone_prefix"
    static let submitButton = "checkout_components_form_redirect_submit_button"

    static let cancelButton = "checkout_components_form_redirect_cancel_button"
    static let pendingScreen = "checkout_components_form_redirect_pending_screen"
    static let pendingMessage = "checkout_components_form_redirect_pending_message"
    static let loadingIndicator = "checkout_components_form_redirect_loading_indicator"
  }
}
