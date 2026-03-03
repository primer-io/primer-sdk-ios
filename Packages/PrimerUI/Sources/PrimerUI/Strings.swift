//
//  Strings.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable line_length
// swiftlint:disable nesting

import Foundation
import PrimerResources

// MARK: - Strings

public struct Strings {}

// MARK: - Generic

public extension Strings {

    enum Generic {

        public static let somethingWentWrong = NSLocalizedString(
            "primer-error-screen",
            bundle: Bundle.primerResources,
            value: "Something went wrong, please try again.",
            comment: "A generic error message that is displayed on the error view")

        public static let isRequiredSuffix = NSLocalizedString(
            "primer-error-is-required-suffix",
            bundle: Bundle.primerResources,
            value: "is required",
            comment: "A suffix to mark a required field or action being performed")

        public static let cancel = NSLocalizedString(
            "primer-alert-button-cancel",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Cancel",
            comment: "Cancel - Alert button cancel")

        public static let delete = NSLocalizedString(
            "primer-alert-button-delete",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Delete",
            comment: "Delete - Alert button delete")

        public static let edit = NSLocalizedString(
            "primer-vault-payment-method-edit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Edit",
            comment: "Edit - Vault Payment Method (Button text)")

        public static let share = NSLocalizedString(
            "primer-vault-payment-method-share",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Share",
            comment: "Share - Share button showing the standard Apple Share sheet on iOS (Button text)")

        public static let close = NSLocalizedString(
            "primer-vault-payment-method-close",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Close",
            comment: "Close - Close button generally used to dismiss the PrimerSDK (Button text)")
    }
}

// MARK: - Alert

public extension Strings {

    enum Alert {

        public static let deleteConfirmationButtonTitle = NSLocalizedString(
            "primer-delete-alert-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Do you want to delete this payment method?",
            comment: "Do you want to delete this payment method? - Delete alert title")
    }
}

// MARK: - Payment Button

public extension Strings {

    enum PaymentButton {

        public static let pay = NSLocalizedString(
            "primer-card-form-pay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay",
            comment: "Pay - Card Form (Checkout submit button text)")

        public static let payInInstallments = NSLocalizedString(
            "primer-button-title-pay-in-installments",
            bundle: Bundle.primerResources,
            value: "Pay in installments",
            comment: "The title of the primer 'pay in installments' button")

        public static let payWithCard = NSLocalizedString(
            "payment-method-type-card-not-vaulted",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay with card",
            comment: "Pay with card - Payment Method Type (Card Not vaulted)")

        public static let confirm = NSLocalizedString(
            "primer-confirm-mandate-confirm",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm",
            comment: "Confirm button title text")

        public static let confirmToPay = NSLocalizedString(
            "confirmButtonTitle",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm to pay",
            comment: "Confirm button title text")

        public static let payBySmartTransfer = NSLocalizedString("payBySmartTransfer",
                                                          tableName: nil,
                                                          bundle: Bundle.primerResources,
                                                          value: "Pay by Smart transfer",
                                                          comment: "Pay by Smart transfer button title text")

        public static let payByImmediateTransfer = NSLocalizedString("payByImmediateTransfer",
                                                              tableName: nil,
                                                              bundle: Bundle.primerResources,
                                                              value: "Pay by Immediate transfer",
                                                              comment: "Pay by Immediate transfer button title text")

    }
}

// MARK: - Views

public extension Strings {

    // MARK: Scanner

    enum ScannerView {

        public static let title = NSLocalizedString(
            "primer-scanner-view-scan-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Scan card",
            comment: "Scan card - Scanner view (Title text)"
        )

        public static let descriptionLabel = NSLocalizedString(
            "primer-scanner-view-scan-front-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Scan the front of your card",
            comment: "Scan the front of your card - Scanner view (Description text)"
        )

        public static let skipButtonTitle = NSLocalizedString(
            "primer-scanner-view-manual-input",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Manual input",
            comment: "Manual input - Scanner view (Button text)"
        )
    }

    // MARK: Account Info Payment View

    enum AccountInfoPaymentView {

        public static let completeYourPayment = NSLocalizedString(
            "completeYourPayment",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Complete your payment",
            comment: "Complete your payment - Account info payment title label")

        public static let dueAt = NSLocalizedString(
            "dueAt",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Due at",
            comment: "The prefix copy we put before the expiration date.")

        public static let pleaseTransferFunds = NSLocalizedString(
            "pleaseTransferFunds",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Please Transfer funds to the provided DBS bank account using your Singapore based bank account via FAST (preferred), MEPS or GIRO.",
            comment: "The message copy that tells the user how to transfer funds given a displayed account code.")
    }

    // MARK: Vouncher Info Confirmation Steps

    enum VoucherInfoConfirmationSteps {

        public static let confirmationStepTitle = NSLocalizedString(
            "multibancoPayWith",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay with Multibanco",
            comment: "The voucher confirmation title label.")

        public static let confirmationStep1LabelText = NSLocalizedString(
            "multibancoFirstStep",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "1. A voucher with payment details will be created.",
            comment: "The voucher confirmation step 1 explanation")

        public static let confirmationStep2LabelText = NSLocalizedString(
            "multibancoSecondStep",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "2. Go to a Multibanco ATM, select the Multibanco payment method and enter the payment details.",
            comment: "The voucher confirmation step 2 explanation")

        public static let confirmationStep3LabelText = NSLocalizedString(
            "multibancoThirdStep",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "3. Login to your online bank account to pay by bank transfer using the payment details.",
            comment: "The voucher confirmation step 3 explanation")
    }

    // MARK: Vocher Info Payment View

    enum VoucherInfoPaymentView {

        public static let completeYourPayment = AccountInfoPaymentView.completeYourPayment

        public static let descriptionLabel =  NSLocalizedString(
            "multibancoPleaseMakePayment",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Please make the payment at an ATM, or using online banking.",
            comment: "The voucher description label.")

        public static let expiresAt = NSLocalizedString(
            "multibancoExpiresAt",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Expires at",
            comment: "The prefix copy we put before the expiration date.")

        public static let entityLabelText = NSLocalizedString(
            "multibancoEntity",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Entity",
            comment: "The entity description label.")

        public static let referenceLabelText = NSLocalizedString(
            "multibancoReference",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Reference",
            comment: "The reference description label.")

        public static let amountLabelText = NSLocalizedString(
            "multibancoAmount",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Amount",
            comment: "The amount description label.")
    }

    // MARK: QR Code

    enum QRCodeView {

        public static let scanToCodeTitle = NSLocalizedString(
            "scanToPay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Scan to pay or take a screenshot",
            comment: "Scan to pay or take a screenshot - QR code screen title label")

        public static let uploadScreenshotTitle = NSLocalizedString(
            "uploadScreenshot",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Upload the screenshot in your banking app.",
            comment: "Upload the screenshot in your banking app. - QR code screen subtitle label")

        public static let qrCodeImageSubtitle = NSLocalizedString(
            "qrCode",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "QR Code",
            comment: "QR Code - QR code screen subtitle label")
    }

    // MARK: Confirm Mandate

    enum ConfirmMandateView {

        public static let navTitle = NSLocalizedString(
            "primer-confirm-mandate-add-bank-account",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add Bank Account",
            comment: "Add Bank Account - Confirm Mandate (Top title text_"
        )

        public static let title = NSLocalizedString(
            "primer-confirm-mandate-confirm-sepa-direct-debit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm SEPA Direct Debit",
            comment: "Confirm SEPA Direct Debit - Confirm Mandate (Main title text)"
        )
    }

    // MARK: Card Form

    enum PrimerCardFormView {

        public static let navBarTitle = NSLocalizedString(
            "primer-form-type-nav-bar-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Payment card",
            comment: "Card form - Navigation Bar Title")

        public static let title = NSLocalizedString(
            "primer-form-type-main-title-card-form",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter your card details",
            comment: "Enter your card details - Form Type Main Title (Card)"
        )

        public static let addCardButtonTitle = NSLocalizedString(
            "primer-card-form-add-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add card",
            comment: "Add card - Card Form (Vault title text)"
        )

        public static let savedCardTitle = NSLocalizedString(
            "primer-saved-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Expires",
            comment: "Expires - Saved card")
    }

    // MARK: Country Selector

    enum CountrySelector {

        public static let selectCountryTitle = NSLocalizedString(
            "countrySelectPlaceholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Select a country",
            comment: "Select a country - Choose your country title label")

        public static let searchCountryTitle = NSLocalizedString(
            "search-country-placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Search country",
            comment: "Search country - Search country textfield placeholder")
    }

    // MARK: Phone number country code Selector

    enum PhoneNumberCountryCodeSelector {

        public static let selectPhoneNumberPrefixTitle = NSLocalizedString(
            "selectPhoneNumberPrefixSelectPlaceholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Select a phone number prefix",
            comment: "Select a phone number prefix - Choose your phone number prefix title label")

        public static let searchPhoneNumberPrefixTitle = NSLocalizedString(
            "select-phone-number-prefix-placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Search phone number prefix",
            comment: "Search phone number prefix - Search phone number prefix textfield placeholder")
    }

    // MARK: Bank Selector

    enum BankSelector {

        public static let chooseBankTitle = NSLocalizedString(
            "choose-your-bank-title-label",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Choose your bank",
            comment: "Choose your bank - Choose your bank title label")

        public static let searchBankTitle = NSLocalizedString(
            "search-bank-placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Search bank",
            comment: "Search bank - Search bank textfield placeholder")
    }

    // MARK: Checkout

    enum CheckoutView {

        public static let navBarTitle = NSLocalizedString(
            "primer-checkout-nav-bar-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Choose payment method",
            comment: "Choose payment method - Checkout Navigation Bar Title")

        public static let applePayButtonText = NSLocalizedString(
            "primer-direct-checkout-apple-pay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Apple pay",
            comment: "Apple pay - Direct Checkout (Apple pay button text)")

        public static let payPalText = NSLocalizedString(
            "primer-direct-checkout-paypal",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "PayPal",
            comment: "PayPal - Direct Checkout (PayPal button text")
    }

    // MARK: Card Mandate

    enum ConfirmMandateViewContent {

        public static let topTitleText = NSLocalizedString(
            "primer-confirm-mandate-add-bank-account",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add Bank Account",
            comment: "Add Bank Account - Confirm Mandate (Top title text_")

        public static let mainTitleText = NSLocalizedString(
            "primer-confirm-mandate-confirm-sepa-direct-debit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm SEPA Direct Debit",
            comment: "Confirm SEPA Direct Debit - Confirm Mandate (Main title text)")
    }

    // MARK: IBAN Form

    enum IBANFormViewContent {

        public static let mainTitleText = NSLocalizedString(
            "primer-iban-form-add-bank-account",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add Bank Account",
            comment: "Add Bank Account - IBAN Form (Main title)")

        public static let subtitleText = NSLocalizedString(
            "primer-iban-form-monthly-fee-automatically-deducted",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate",
            comment: "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate - IBAN Form (Subtitle text)")

        public static let textFieldPlaceholder = NSLocalizedString(
            "primer-iban-form-enter-iban",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter IBAN",
            comment: "Enter IBAN - IBAN Form (Text field placeholder text")

        public static let switchLabelText = NSLocalizedString(
            "primer-iban-form-use-account-number-instead",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Use an account number instead",
            comment: "Use an account number instead - IBAN Form (Switch text)")

        public static let nextButtonText = NSLocalizedString(
            "primer-iban-form-next",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Next",
            comment: "Next - IBAN Form (Button text)")
    }

    // MARK: Vault Payment Method

    enum VaultPaymentMethodViewContent {

        public static let savedPaymentMethod = NSLocalizedString(
            "primer-vault-checkout-payment-method-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "SAVED PAYMENT METHOD",
            comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")

        public static let availablePaymentMethodsTitle = NSLocalizedString(            "primer-vault-payment-method-available-payment-methods",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Available payment methods",
            comment: "Available payment methods - Vault Payment Method (Main title text)")

        public static let savedPaymentMethodsTitle = NSLocalizedString(
            "primer-vault-payment-method-saved-payment-methods",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Saved payment methods",
            comment: "Saved payment methods - Vault Payment Method (Main title text)")

        public static let seeAllButtonTitle = NSLocalizedString(
            "see-all",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "See all",
            comment: "See all - Universal checkout")

        public static let addCard = NSLocalizedString(
            "primer-vault-payment-method-add-new-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add new card",
            comment: "Add new card - Vault Payment Method (Button text)")
    }

    // MARK: Card form

    struct CardFormView {

        public static let noAdditionalFeesTitle = NSLocalizedString(
            "no_additional_fee",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "No additional fee",
            comment: "No additional fee - Universal Checkout section text")

        public static let additionalFeesTitle = NSLocalizedString(
            "surcharge-additional-fee",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Additional fee may apply",
            comment: "Additional fee may apply - Surcharge (Label)")

        public static let vaultNavBarTitle = NSLocalizedString(
            "primer-vault-nav-bar-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add payment method",
            comment: "Add payment method - Vault Navigation Bar Title")

        public static let checkoutTitleText = NSLocalizedString(
            "primer-card-form-checkout",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Checkout",
            comment: "Checkout - Card Form (Checkout title text)")

        public static let vaultSubmitButtonText = NSLocalizedString(
            "primer-card-form-save",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Save",
            comment: "Save - Card Form (Vault submit button text)")

        public enum CardNumber {

            public static let label = NSLocalizedString(
                "primer-form-text-field-title-card-number",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Card number",
                comment: "Card number - Form Text Field Title (Card number)")

            public static let placeholder = NSLocalizedString(
                "primer-card-form-4242-4242-4242-4242",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "4242 4242 4242 4242",
                comment: "4242 4242 4242 4242 - Card Form (Card text field placeholder text)")

            public static let invalidErrorMessage = NSLocalizedString(
                "primer-error-card-form-card-number",
                bundle: Bundle.primerResources,
                value: "Invalid card number",
                comment: "An error message displayed when the card number is not correct")
        }

        public enum ExpiryDate {

            public static let label = NSLocalizedString(
                "primer-form-text-field-title-expiry-date",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Expiry date",
                comment: "Expiry date - Form Text Field Title (Expiry date)")

            public static let placeholder = NSLocalizedString(
                "card_expiry_date",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "MM/YY",
                comment: "MM/YY - Card Form (Expiry text field placeholder text)")

            public static let invalidErrorMessage = NSLocalizedString(
                "primer-error-card-form-card-expiration-date",
                bundle: Bundle.primerResources,
                value: "Invalid date",
                comment: "An error message displayed when the card expiration date is not correct")
        }

        public enum CVV {

            public static let label = NSLocalizedString(
                "primer-card-form-cvv",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "CVV",
                comment: "CVV - Card Form (CVV text field placeholder text)")

            public static let placeholder = "123"

            public static let invalidErrorMessage = NSLocalizedString(
                "primer-error-card-form-card-cvv",
                bundle: Bundle.primerResources,
                value: "Invalid CVV",
                comment: "An error message displayed when the cvv code is not correct")
        }

        public enum Cardholder {

            public static let label = NSLocalizedString(
                "primer-card-form-name",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Name",
                comment: "Cardholder name")

            public static let placeholder = NSLocalizedString(
                "primer-form-text-field-placeholder-cardholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "e.g. John Doe",
                comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")

            public static let invalidErrorMessage = NSLocalizedString(
                "cardholderErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Cardholder name",
                comment: "An error message displayed when the city field is not correct")

            public static let invalidCardholderLengthErrorMessage = NSLocalizedString(
                "form_error_card_holder_name_length",
                bundle: Bundle.primerResources,
                value: "Name must have between 2 and 45 characters",
                comment: "An error message displayed when cardholder.text length is < 2")
        }

        public enum City {

            public static let label = NSLocalizedString(
                "cityLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "City",
                comment: "The billing address city container view label"
            )

            public static let placeholder = NSLocalizedString(
                "cityPlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "City",
                comment: "Form Text Field Placeholder (Address city)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "cityErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "City is required",
                comment: "City is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "cityErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid city",
                comment: "An error message displayed when the city field is not correct")
        }

        public enum PostalCode {

            public static let label = NSLocalizedString(
                "postalCodeLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Postal code",
                comment: "The billing address postal code container view label"
            )

            public static let placeholder = NSLocalizedString(
                "postalCodePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Postal Code",
                comment: "Form Text Field Placeholder (Address postal code)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "postalCodeErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Postal code is required",
                comment: "Postal code is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "postalCodeErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid postal code",
                comment: "An error message displayed when the postal code field is not correct")
        }

        public enum State {

            public static let label = NSLocalizedString(
                "stateLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "State / Region / County",
                comment: "The billing address state container view label"
            )

            public static let placeholder = NSLocalizedString(
                "statePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "State / Region / County",
                comment: "Form Text Field Placeholder (Address State / Region / County)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "stateErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "State, Region or County is required",
                comment: "State, Region or County is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "stateErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid State, Region or County",
                comment: "An error message displayed when the State, Region or County field is not correct")
        }

        public enum AddressLine1 {

            public static let label = NSLocalizedString(
                "addressLine1Label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 1",
                comment: "The billing address Address line 1 container view label"
            )

            public static let placeholder = NSLocalizedString(
                "addressLine1Placeholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 1",
                comment: "Form Text Field Placeholder (Address line 1)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "addressLine1ErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address Line 1 is required",
                comment: "State, Region or County is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "addressLine1ErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Address Line 1",
                comment: "An error message displayed when the Address line 1 is not correct")
        }

        public enum AddressLine2 {

            public static let label = NSLocalizedString(
                "addressLine2Label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 2",
                comment: "The billing address Address line 2 container view label"
            )

            public static let placeholder = NSLocalizedString(
                "addressLine2Placeholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 2",
                comment: "Form Text Field Placeholder (Address line 2)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "addressLine2ErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address Line 2 is required",
                comment: "State, Region or County is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "addressLine2ErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Address Line 2",
                comment: "An error message displayed when the Address line 2 is not correct")
        }

        public enum CountryCode {

            public static let label = NSLocalizedString(
                "countryCodeLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Country",
                comment: "The billing address Country code container view label"
            )

            public static let placeholder = NSLocalizedString(
                "countryCodePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Country",
                comment: "Form Text Field Placeholder (Country code)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "countryCodeErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Country is required",
                comment: "Country is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "countryCodeErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Country",
                comment: "An error message displayed when the Country is not correct")
        }

        public enum FirstName {

            public static let label = NSLocalizedString(
                "firstNameLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name",
                comment: "The billing address First name container view label"
            )

            public static let placeholder = NSLocalizedString(
                "firstNamePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name",
                comment: "Form Text Field Placeholder (First name)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "firstNameErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name is required",
                comment: "First name is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "firstNameErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid First Name",
                comment: "An error message displayed when the First Name is not correct")
        }

        public enum LastName {

            public static let label = NSLocalizedString(
                "lastNameLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name",
                comment: "The billing address Last name container view label"
            )

            public static let placeholder = NSLocalizedString(
                "lastNamePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name",
                comment: "Form Text Field Placeholder (Last name)"
            )

            public static let isRequiredErrorMessage = NSLocalizedString(
                "lastNameErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name is required",
                comment: "Last name is required - Form Validation"
            )

            public static let invalidErrorMessage = NSLocalizedString(
                "lastNameErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Last Name",
                comment: "An error message displayed when the Last Name is not correct")
        }
    }

    struct CVVRecapture {
        public static let title = NSLocalizedString(
            "primer-cvv-recapture-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter CVV",
            comment: "Enter CVV - CVV recapture screen title")

        public static let explanation = NSLocalizedString(
            "primer-cvv-recapture-explanation",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Input the %d digit security code on your card for a secure payment.",
            comment: "Some cards have 3 or 4 digits for their CVV card")

        public static let buttonTitle = NSLocalizedString(
            "continue",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Continue",
            comment: "Continue")
    }
}

// MARK: - Apple Pay

public extension Strings {

    struct ApplePay {

        public static let surcharge = NSLocalizedString(
            "surcharge",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Additional fees",
            comment: "Surcharge - Apple Pay label")
    }
}

// MARK: - Blik

public extension Strings {

    enum Blik {

        public static let inputTopPlaceholder = NSLocalizedString(
            "input_hint_form_blik_otp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "6 digit code",
            comment: "6 digit code - Text field top placeholder")

        public static let inputTextFieldPlaceholder = NSLocalizedString(
            "payment_method_blik_loading_placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter your one time password",
            comment: "Enter your one time password - Text field placeholder")

        public static let inputDescriptor = NSLocalizedString(
            "input_description_otp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Get the code from your banking app.",
            comment: "Get the code from your banking app - Blik descriptor")

        public static let completeYourPayment = NSLocalizedString(
            "completeYourPaymentInTheBlikApp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Complete your payment in Blik app",
            comment: "Info message suggesting the user to open the Blik app to complete the payment")
    }

    enum MBWay {

        public static let inputTopPlaceholder = NSLocalizedString(
            "input_hint_form_mbway_phone_number",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Phone Number",
            comment: "Phone Number - Text field top placeholder")

        public static let completeYourPayment = NSLocalizedString(
            "completeYourPaymentInTheApp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Complete your payment in the MB WAY app",
            comment: "Info message suggesting the user to open the MB WAY app to complete the payment")
    }

}

// MARK: - Primer Test (DummyAPMs)// MARK: - Blik

public extension Strings {

    enum PrimerTest {

        public static let headerViewText = NSLocalizedString(
            "primer-test-header-description",
            bundle: Bundle.primerResources,
            value: "This is a mocked flow for sandbox. Choose the result you want to test from the list below.",
            comment: "The title of the header for the flow decision view")
    }

    enum PrimerTestFlowDecision {

        public static let successTitle = NSLocalizedString(
            "primer-test-payment-method-success-flow-title",
            bundle: Bundle.primerResources,
            value: "Authorized",
            comment: "The title of the mocked successful flow for a Test Payment Method")

        public static let declineTitle = NSLocalizedString(
            "primer-test-payment-method-decline-flow-title",
            bundle: Bundle.primerResources,
            value: "Declined",
            comment: "The title of the mocked declined flow for a Test Payment Method")

        public static let failTitle = NSLocalizedString(
            "primer-test-payment-method-fail-flow-title",
            bundle: Bundle.primerResources,
            value: "Failed",
            comment: "The title of the mocked failed flow for a Test Payment Method")
    }
}

// MARK: - ACH

public extension Strings {

    struct UserDetails {

        public static let subtitle = NSLocalizedString(
            "stripe_ach_user_details_collection_subtitle_label",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Your personal details",
            comment: "The subtitle label of User Details screen"
        )

        public static let continueButton = NSLocalizedString(
            "stripe_ach_user_details_collection_continue_button",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Continue",
            comment: "The continue button title of User Details screen"
        )

        public static let backButton = NSLocalizedString(
            "back_button_label",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Back",
            comment: "The back button title of User Details screen"
        )

        public static let emailDisclaimer = NSLocalizedString(
            "stripe_ach_user_details_collection_data_usage_label",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "We'll only use this to keep you updated about your payment",
            comment: "The email disclaimer label of User Details screen"
        )

        public enum FirstName {

            public static let label = NSLocalizedString(
                "stripe_ach_user_details_collection_first_name_label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name",
                comment: "The first name textfield label"
            )

            public static let errorDescriptorField = NSLocalizedString(
                "stripe_ach_user_details_collection_invalid_first_name",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Please enter a valid first name. Avoid using numbers or special characters.",
                comment: "First name error descriptor - Form Validation"
            )
        }

        public enum LastName {

            public static let label = NSLocalizedString(
                "stripe_ach_user_details_collection_last_name_label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name",
                comment: "The last name textfield label"
            )

            public static let errorDescriptorField = NSLocalizedString(
                "stripe_ach_user_details_collection_invalid_last_name",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Please enter a valid last name. Avoid using numbers or special characters.",
                comment: "Last name error descriptor - Form Validation"
            )
        }

        public enum EmailAddress {

            public static let label = NSLocalizedString(
                "stripe_ach_user_details_collection_email_address_label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Email address",
                comment: "The email address textfield label"
            )

            public static let errorDescriptorField = NSLocalizedString(
                "stripe_ach_user_details_collection_invalid_email_address",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "The email address you entered doesn't look like a real email address. Please make sure it includes an '@' and a domain (like '@example.com').",
                comment: "Email address error descriptor - Form Validation"
            )
        }

    }

    struct Mandate {

        public static let templateText = NSLocalizedString(
            "stripe_ach_mandate_template_ios",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "By clicking Accept, you authorize %@ to debit the bank account specified above for any amount owed for charges arising from your use of %@'s services and/or purchase of products from %@, pursuant to %@'s website and terms, until this authorization is revoked. You may amend or cancel this authorization at any time by providing notice to %@ with 30 (thirty) days notice.\n\nIf you use %@'s services or purchase additional products periodically pursuant to %@'s terms, you authorize %@ to debit your bank account periodically. Payments that fall outside the regular debits authorized above will only be debited after your authorization is obtained.",
            comment: "The template text for mandate info"
        )

        public static let acceptButton = NSLocalizedString(
            "stripe_ach_mandate_accept_button",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Accept",
            comment: "The accept button title for Mandate info"
        )

        public static let cancelButton = NSLocalizedString(
            "stripe_ach_mandate_cancel_payment_button",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Cancel payment",
            comment: "The cancel button title for Mandate info"
        )

    }

    struct ResultView {

        public static let paymentTitle = NSLocalizedString(
            "pay_with_payment_method",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay with %@",
            comment: "The payment method title"
        )

        public static let successMessage = NSLocalizedString(
            "stripe_ach_payment_request_completed_successfully",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "You have now authorized your bank account to be debited. You will be notified via email once the payment has been collected successfully.",
            comment: "The success message for ResultView"
        )

        public static let cancelMessage = NSLocalizedString(
            "stripe_ach_payment_request_cancelled",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Please try again or select another bank",
            comment: "The cancel message for ResultView"
        )

        public static let retryButton = NSLocalizedString(
            "retry_button",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Retry",
            comment: "The retry button title for ResultView"
        )

        public static let chooseOtherPM = NSLocalizedString(
            "choose_other_payment_method_button",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Choose other payment method",
            comment: "The choose other PM button title for ResultView"
        )

        public enum Subtitle {

            public static let successful = NSLocalizedString(
                "session_complete_payment_success_title",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Payment authorized",
                comment: "The subtitle for ResultView - Success state"
            )

            public static let cancelled = NSLocalizedString(
                "session_complete_payment_cancellation_title",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Payment cancelled",
                comment: "The subtitle for ResultView - Cancelled state"
            )

            public static let failed = NSLocalizedString(
                "session_complete_payment_failure_title",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Payment failed",
                comment: "The subtitle for ResultView - Failed state"
            )
        }
    }
}

// swiftlint:enable nesting
// swiftlint:enable line_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
