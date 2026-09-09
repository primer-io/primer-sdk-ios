//
//  AccessibilityIdentifiers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

enum AccessibilityIdentifiers {

  /// UIKit-level identifier for the editable control wrapped inside an identified field container,
  /// so UI tests can address the text field directly instead of the container element that carries
  /// the label and value.
  static func inputField(within containerIdentifier: String) -> String {
    "\(containerIdentifier)_input"
  }

  enum CardForm {
    static let cardNumberField = "primer_checkout_components_card_form_card_number_field"
    static let expiryField = "primer_checkout_components_card_form_expiry_field"
    static let cvcField = "primer_checkout_components_card_form_cvc_field"
    static let cardholderNameField = "primer_checkout_components_card_form_cardholder_name_field"
    static let submitButton = "primer_checkout_components_card_form_submit_button"

    static func billingAddressField(_ field: String) -> String {
      "primer_checkout_components_card_form_billing_\(field)_field"
    }

    // The billing fields that carry several input types read their segment here, so the
    // container view and its UIKit wrapper cannot drift apart. The segment is spelled out per
    // input type: string interpolation of the enum case produces camelCase and silently
    // changes the id when a case is renamed. `fallback` keeps each field's own default for an
    // input type it does not name.
    static func billingAddressField(for inputType: PrimerInputElementType, fallback: String) -> String {
      let segment = switch inputType {
      case .addressLine1: "address_line1"
      case .addressLine2: "address_line2"
      case .firstName: "first_name"
      case .lastName: "last_name"
      case .phoneNumber: "phone_number"
      default: fallback
      }
      return billingAddressField(segment)
    }

    static func billingAddressInput(for inputType: PrimerInputElementType, fallback: String) -> String {
      AccessibilityIdentifiers.inputField(within: billingAddressField(for: inputType, fallback: fallback))
    }

    // Fixed billing fields get constants so the container view and its UIKit wrapper cannot
    // drift apart; the fields with several input types keep the builder above.
    static let billingCityField = "primer_checkout_components_card_form_billing_city_field"
    static let billingPostalCodeField = "primer_checkout_components_card_form_billing_postal_code_field"
    static let billingStateField = "primer_checkout_components_card_form_billing_state_field"
    static let billingEmailField = "primer_checkout_components_card_form_billing_email_field"

    static let inlineNetworkSelectorContainer =
      "primer_checkout_components_card_form_inline_network_selector"

    static func inlineNetworkSelectorButton(forNetwork network: String) -> String {
      "primer_checkout_components_card_form_inline_network_selector_\(network.lowercased())_button"
    }

    static let dropdownNetworkSelectorButton =
      "primer_checkout_components_card_form_dropdown_network_selector_button"
  }

  enum PaymentSelection {
    static let header = "primer_checkout_components_payment_selection_header"
    static let showAllButton = "primer_checkout_components_payment_selection_show_all_button"
    static let showOtherWaysButton = "primer_checkout_components_payment_selection_show_other_ways_button"

    static func paymentMethodItem(_ type: String) -> String {
      "primer_checkout_components_payment_selection_\(type)_item"
    }

    static func vaultedPaymentMethodItem(_ id: String) -> String {
      "primer_checkout_components_vaulted_payment_method_\(id)_item"
    }

    static func deletePaymentMethodButton(_ id: String) -> String {
      "primer_checkout_components_vaulted_payment_method_\(id)_delete_button"
    }
  }

  enum Vault {
    static let cvvField = "primer_checkout_components_vault_cvv_field"
    static let cvvSecurityLabel = "primer_checkout_components_vault_cvv_security_label"
    static let payButton = "primer_checkout_components_vault_pay_button"
  }

  enum Common {
    static let closeButton = "primer_checkout_components_close_button"
    static let backButton = "primer_checkout_components_back_button"
    static let editButton = "primer_checkout_components_edit_button"
    static let doneButton = "primer_checkout_components_done_button"
    static let deleteButton = "primer_checkout_components_delete_button"
    static let cancelButton = "primer_checkout_components_cancel_button"
    static let loadingIndicator = "primer_checkout_components_loading_indicator"
  }

  enum Error {
    static let icon = "primer_checkout_components_error_icon"
    static let title = "primer_checkout_components_error_title"
    static let description = "primer_checkout_components_error_description"
    static let retryButton = "primer_checkout_components_error_retry_button"
    static let otherPaymentMethodButton = "primer_checkout_components_error_other_payment_method_button"
  }

  enum Success {
    static let container = "primer_checkout_components_success_container"
    static let icon = "primer_checkout_components_success_icon"
    static let title = "primer_checkout_components_success_title"
    static let description = "primer_checkout_components_success_description"
  }

  enum AdyenKlarna {
    static let container = "primer_checkout_components_adyen_klarna_container"
    static let logo = "primer_checkout_components_adyen_klarna_logo"
    static let title = "primer_checkout_components_adyen_klarna_title"
    static let optionList = "primer_checkout_components_adyen_klarna_option_list"
    static let backButton = "primer_checkout_components_adyen_klarna_back_button"
    static let cancelButton = "primer_checkout_components_adyen_klarna_cancel_button"

    static func optionButton(_ optionId: String) -> String {
      "primer_checkout_components_adyen_klarna_option_\(optionId.lowercased())_button"
    }
  }

  enum Klarna {
    static let container = "primer_checkout_components_klarna_container"
    static let logo = "primer_checkout_components_klarna_logo"
    static let authorizeButton = "primer_checkout_components_klarna_authorize_button"
    static let finalizeButton = "primer_checkout_components_klarna_finalize_button"
    static let paymentViewContainer = "primer_checkout_components_klarna_payment_view_container"
    static let categoriesContainer = "primer_checkout_components_klarna_categories_container"
    static let loadingIndicator = "primer_checkout_components_klarna_loading_indicator"

    static func categoryButton(_ categoryId: String) -> String {
      "primer_checkout_components_klarna_category_\(categoryId.lowercased())_button"
    }
  }

  enum QRCode {
    static let container = "primer_checkout_components_qr_code_container"
    static let amountLabel = "primer_checkout_components_qr_code_amount_label"
    static let instructionTitle = "primer_checkout_components_qr_code_instruction_title"
    static let instructionSubtitle = "primer_checkout_components_qr_code_instruction_subtitle"
    static let qrCodeImage = "primer_checkout_components_qr_code_image"
    static let successIcon = "primer_checkout_components_qr_code_success_icon"
    static let failureIcon = "primer_checkout_components_qr_code_failure_icon"
    static let loadingIndicator = "primer_checkout_components_qr_code_loading_indicator"
  }

  enum Ach {
    static let container = "primer_checkout_components_ach_container"
    static let loadingIndicator = "primer_checkout_components_ach_loading_indicator"
    static let userDetailsContainer = "primer_checkout_components_ach_user_details_container"
    static let userDetailsTitle = "primer_checkout_components_ach_user_details_title"
    static let firstNameField = "primer_checkout_components_ach_user_details_first_name_field"
    static let lastNameField = "primer_checkout_components_ach_user_details_last_name_field"
    static let emailField = "primer_checkout_components_ach_user_details_email_field"
    static let emailDisclaimer = "primer_checkout_components_ach_user_details_email_disclaimer"
    static let submitButton = "primer_checkout_components_ach_submit_button"
    static let bankCollectorContainer = "primer_checkout_components_ach_bank_collector_container"
    static let mandateContainer = "primer_checkout_components_ach_mandate_container"
    static let mandateTitle = "primer_checkout_components_ach_mandate_title"
    static let mandateTextContainer = "primer_checkout_components_ach_mandate_text_container"
    static let mandateAcceptButton = "primer_checkout_components_ach_mandate_accept_button"
    static let mandateDeclineButton = "primer_checkout_components_ach_mandate_decline_button"
  }

  enum SelectCountry {
    static let cancelButton = "primer_checkout_components_select_country_cancel_button"
    static let searchField = "primer_checkout_components_select_country_search_field"

    static func countryItem(_ code: String) -> String {
      "primer_checkout_components_select_country_\(code.lowercased())_item"
    }
  }

  enum BillingAddressRedirect {
    static let screen = "primer_checkout_components_billing_address_redirect_screen"
    static let countryCodeField = "primer_checkout_components_billing_address_redirect_country_code_field"
    static let addressLine1Field = "primer_checkout_components_billing_address_redirect_address_line1_field"
    static let addressLine2Field = "primer_checkout_components_billing_address_redirect_address_line2_field"
    static let postalCodeField = "primer_checkout_components_billing_address_redirect_postal_code_field"
    static let cityField = "primer_checkout_components_billing_address_redirect_city_field"
    static let stateField = "primer_checkout_components_billing_address_redirect_state_field"
    static let submitButton = "primer_checkout_components_billing_address_redirect_submit_button"
    static let backButton = "primer_checkout_components_billing_address_redirect_back_button"
  }

  enum FormRedirect {
    static let screen = "primer_checkout_components_form_redirect_screen"
    static let otpField = "primer_checkout_components_form_redirect_otp_field"
    static let phoneField = "primer_checkout_components_form_redirect_phone_field"
    static let phonePrefix = "primer_checkout_components_form_redirect_phone_prefix"
    static let submitButton = "primer_checkout_components_form_redirect_submit_button"

    static let cancelButton = "primer_checkout_components_form_redirect_cancel_button"
    static let pendingScreen = "primer_checkout_components_form_redirect_pending_screen"
    static let pendingMessage = "primer_checkout_components_form_redirect_pending_message"
    static let loadingIndicator = "primer_checkout_components_form_redirect_loading_indicator"
  }

  enum ApplePay {
    static let title = "primer_checkout_components_apple_pay_title"
    static let processingIndicator = "primer_checkout_components_apple_pay_processing_indicator"
    static let processingLabel = "primer_checkout_components_apple_pay_processing_label"
    static let unavailableIcon = "primer_checkout_components_apple_pay_unavailable_icon"
    static let unavailableTitle = "primer_checkout_components_apple_pay_unavailable_title"
    static let unavailableDescription = "primer_checkout_components_apple_pay_unavailable_description"
    static let chooseOtherButton = "primer_checkout_components_apple_pay_choose_other_button"
  }
}
