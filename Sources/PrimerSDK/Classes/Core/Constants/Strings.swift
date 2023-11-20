//
//  Strings.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation

// MARK: - Strings

struct Strings {}

// MARK: - Generic

extension Strings {

    enum Generic {

        static let somethingWentWrong = NSLocalizedString(
            "primer-error-screen",
            bundle: Bundle.primerResources,
            value: "Something went wrong, please try again.",
            comment: "A generic error message that is displayed on the error view")

        static let isRequiredSuffix = NSLocalizedString(
            "primer-error-is-required-suffix",
            bundle: Bundle.primerResources,
            value: "is required",
            comment: "A suffix to mark a required field or action being performed")

        static let cancel = NSLocalizedString(
            "primer-alert-button-cancel",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Cancel",
            comment: "Cancel - Alert button cancel")

        static let delete = NSLocalizedString(
            "primer-alert-button-delete",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Delete",
            comment: "Delete - Alert button delete")

        static let edit = NSLocalizedString(
            "primer-vault-payment-method-edit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Edit",
            comment: "Edit - Vault Payment Method (Button text)")

        static let share = NSLocalizedString(
            "primer-vault-payment-method-share",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Share",
            comment: "Share - Share button showing the standard Apple Share sheet on iOS (Button text)")

        static let close = NSLocalizedString(
            "primer-vault-payment-method-close",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Close",
            comment: "Close - Close button generally used to dismiss the PrimerSDK (Button text)")
    }
}

// MARK: - Alert

extension Strings {

    enum Alert {

        static let deleteConfirmationButtonTitle = NSLocalizedString(
            "primer-delete-alert-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Do you want to delete this payment method?",
            comment: "Do you want to delete this payment method? - Delete alert title")
    }
}

// MARK: - Payment Button

extension Strings {

    enum PaymentButton {

        static let pay = NSLocalizedString(
            "primer-card-form-pay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay",
            comment: "Pay - Card Form (Checkout submit button text)")

        static let payInInstallments = NSLocalizedString(
            "primer-button-title-pay-in-installments",
            bundle: Bundle.primerResources,
            value: "Pay in installments",
            comment: "The title of the primer 'pay in installments' button")

        static let payByMobile = NSLocalizedString(
            "payment-method-type-pay-by-mobile",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay by mobile",
            comment: "Pay by mobile - Payment By Mobile (e.g. Apaya)")

        static let payWithCard = NSLocalizedString(
            "payment-method-type-card-not-vaulted",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay with card",
            comment: "Pay with card - Payment Method Type (Card Not vaulted)")

        static let confirm = NSLocalizedString(
            "primer-confirm-mandate-confirm",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm",
            comment: "Confirm button title text")

        static let confirmToPay = NSLocalizedString(
            "confirmButtonTitle",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm to pay",
            comment: "Confirm button title text")

    }
}

// MARK: - Views

extension Strings {

    // MARK: Scanner

    enum ScannerView {

        static let title = NSLocalizedString(
            "primer-scanner-view-scan-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Scan card",
            comment: "Scan card - Scanner view (Title text)"
        )

        static let descriptionLabel = NSLocalizedString(
            "primer-scanner-view-scan-front-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Scan the front of your card",
            comment: "Scan the front of your card - Scanner view (Description text)"
        )

        static let skipButtonTitle = NSLocalizedString(
            "primer-scanner-view-manual-input",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Manual input",
            comment: "Manual input - Scanner view (Button text)"
        )
    }

    // MARK: Account Info Payment View

    enum AccountInfoPaymentView {

        static let completeYourPayment = NSLocalizedString(
            "completeYourPayment",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Complete your payment",
            comment: "Complete your payment - Account info payment title label")

        static let dueAt = NSLocalizedString(
            "dueAt",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Due at",
            comment: "The prefix copy we put before the expiration date.")

        static let pleaseTransferFunds = NSLocalizedString(
            "pleaseTransferFunds",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Please Transfer funds to the provided DBS bank account using your Singapore based bank account via FAST (preferred), MEPS or GIRO.",
            comment: "The message copy that tells the user how to transfer funds given a displayed account code.")
    }

    // MARK: Vouncher Info Confirmation Steps

    enum VoucherInfoConfirmationSteps {

        static let confirmationStepTitle = NSLocalizedString(
            "multibancoPayWith",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay with Multibanco",
            comment: "The voucher confirmation title label.")

        static let confirmationStep1LabelText = NSLocalizedString(
            "multibancoFirstStep",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "1. A voucher with payment details will be created.",
            comment: "The voucher confirmation step 1 explanation")

        static let confirmationStep2LabelText = NSLocalizedString(
            "multibancoSecondStep",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "2. Go to a Multibanco ATM, select the Multibanco payment method and enter the payment details.",
            comment: "The voucher confirmation step 2 explanation")

        static let confirmationStep3LabelText = NSLocalizedString(
            "multibancoThirdStep",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "3. Login to your online bank account to pay by bank transfer using the payment details.",
            comment: "The voucher confirmation step 3 explanation")
    }

    // MARK: Vocher Info Payment View

    enum VoucherInfoPaymentView {

        static let completeYourPayment = AccountInfoPaymentView.completeYourPayment

        static let descriptionLabel =  NSLocalizedString(
            "multibancoPleaseMakePayment",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Please make the payment at an ATM, or using online banking.",
            comment: "The voucher description label.")

        static let expiresAt = NSLocalizedString(
            "multibancoExpiresAt",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Expires at",
            comment: "The prefix copy we put before the expiration date.")

        static let entityLabelText = NSLocalizedString(
            "multibancoEntity",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Entity",
            comment: "The entity description label.")

        static let referenceLabelText = NSLocalizedString(
            "multibancoReference",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Reference",
            comment: "The reference description label.")

        static let amountLabelText = NSLocalizedString(
            "multibancoAmount",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Amount",
            comment: "The amount description label.")
    }

    // MARK: QR Code

    enum QRCodeView {

        static let scanToCodeTitle = NSLocalizedString(
            "scanToPay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Scan to pay or take a screenshot",
            comment: "Scan to pay or take a screenshot - QR code screen title label")

        static let uploadScreenshotTitle = NSLocalizedString(
            "uploadScreenshot",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Upload the screenshot in your banking app.",
            comment: "Upload the screenshot in your banking app. - QR code screen subtitle label")

        static let qrCodeImageSubtitle = NSLocalizedString(
            "qrCode",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "QR Code",
            comment: "QR Code - QR code screen subtitle label")
    }

    // MARK: Confirm Mandate

    enum ConfirmMandateView {

        static let navTitle = NSLocalizedString(
            "primer-confirm-mandate-add-bank-account",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add Bank Account",
            comment: "Add Bank Account - Confirm Mandate (Top title text_"
        )

        static let title = NSLocalizedString(
            "primer-confirm-mandate-confirm-sepa-direct-debit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm SEPA Direct Debit",
            comment: "Confirm SEPA Direct Debit - Confirm Mandate (Main title text)"
        )
    }

    // MARK: Card Form

    enum PrimerCardFormView {

        static let navBarTitle = NSLocalizedString(
            "primer-form-type-nav-bar-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Payment card",
            comment: "Card form - Navigation Bar Title")

        static let title = NSLocalizedString(
            "primer-form-type-main-title-card-form",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter your card details",
            comment: "Enter your card details - Form Type Main Title (Card)"
        )

        static let addCardButtonTitle = NSLocalizedString(
            "primer-card-form-add-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add card",
            comment: "Add card - Card Form (Vault title text)"
        )

        static let savedCardTitle = NSLocalizedString(
            "primer-saved-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Expires",
            comment: "Expires - Saved card")
    }

    // MARK: Country Selector

    enum CountrySelector {

        static let selectCountryTitle = NSLocalizedString(
            "countrySelectPlaceholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Select a country",
            comment: "Select a country - Choose your country title label")

        static let searchCountryTitle = NSLocalizedString(
            "search-country-placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Search country",
            comment: "Search country - Search country textfield placeholder")
    }

    // MARK: Phone number country code Selector

    enum PhoneNumberCountryCodeSelector {

        static let selectPhoneNumberPrefixTitle = NSLocalizedString(
            "selectPhoneNumberPrefixSelectPlaceholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Select a phone number prefix",
            comment: "Select a phone number prefix - Choose your phone number prefix title label")

        static let searchPhoneNumberPrefixTitle = NSLocalizedString(
            "select-phone-number-prefix-placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Search phone number prefix",
            comment: "Search phone number prefix - Search phone number prefix textfield placeholder")
    }

    // MARK: Bank Selector

    enum BankSelector {

        static let chooseBankTitle = NSLocalizedString(
            "choose-your-bank-title-label",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Choose your bank",
            comment: "Choose your bank - Choose your bank title label")

        static let searchBankTitle = NSLocalizedString(
            "search-bank-placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Search bank",
            comment: "Search bank - Search bank textfield placeholder")
    }

    // MARK: Checkout

    enum CheckoutView {

        static let navBarTitle = NSLocalizedString(
            "primer-checkout-nav-bar-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Choose payment method",
            comment: "Choose payment method - Checkout Navigation Bar Title")

        static let applePayButtonText = NSLocalizedString(
            "primer-direct-checkout-apple-pay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Apple pay",
            comment: "Apple pay - Direct Checkout (Apple pay button text)")

        static let payPalText = NSLocalizedString(
            "primer-direct-checkout-paypal",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "PayPal",
            comment: "PayPal - Direct Checkout (PayPal button text")
    }

    // MARK: Card Mandate

    enum ConfirmMandateViewContent {

        static let topTitleText = NSLocalizedString(
            "primer-confirm-mandate-add-bank-account",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add Bank Account",
            comment: "Add Bank Account - Confirm Mandate (Top title text_")

        static let mainTitleText = NSLocalizedString(
            "primer-confirm-mandate-confirm-sepa-direct-debit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm SEPA Direct Debit",
            comment: "Confirm SEPA Direct Debit - Confirm Mandate (Main title text)")
    }

    // MARK: IBAN Form

    enum IBANFormViewContent {

        static let mainTitleText = NSLocalizedString(
            "primer-iban-form-add-bank-account",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add Bank Account",
            comment: "Add Bank Account - IBAN Form (Main title)")

        static let subtitleText = NSLocalizedString(
            "primer-iban-form-monthly-fee-automatically-deducted",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate",
            comment: "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate - IBAN Form (Subtitle text)")

        static let textFieldPlaceholder = NSLocalizedString(
            "primer-iban-form-enter-iban",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter IBAN",
            comment: "Enter IBAN - IBAN Form (Text field placeholder text")

        static let switchLabelText = NSLocalizedString(
            "primer-iban-form-use-account-number-instead",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Use an account number instead",
            comment: "Use an account number instead - IBAN Form (Switch text)")

        static let nextButtonText = NSLocalizedString(
            "primer-iban-form-next",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Next",
            comment: "Next - IBAN Form (Button text)")
    }

    // MARK: Vault Payment Method

    enum VaultPaymentMethodViewContent {

        static let savedPaymentMethod = NSLocalizedString(
            "primer-vault-checkout-payment-method-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "SAVED PAYMENT METHOD",
            comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")

        static var mainTitleText: String {
            if PrimerInternal.shared.intent == .vault {
                return savedPaymentMethodsTitle
            } else {
                return availablePaymentMethodsTitle
            }
        }

        static let availablePaymentMethodsTitle = NSLocalizedString(
            "primer-vault-payment-method-available-payment-methods",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Available payment methods",
            comment: "Available payment methods - Vault Payment Method (Main title text)")

        static let savedPaymentMethodsTitle = NSLocalizedString(
            "primer-vault-payment-method-saved-payment-methods",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Saved payment methods",
            comment: "Saved payment methods - Vault Payment Method (Main title text)")

        static let seeAllButtonTitle = NSLocalizedString(
            "see-all",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "See all",
            comment: "See all - Universal checkout")

        static let addCard = NSLocalizedString(
            "primer-vault-payment-method-add-new-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add new card",
            comment: "Add new card - Vault Payment Method (Button text)")
    }

    // MARK: Card form

    struct CardFormView {

        static let noAdditionalFeesTitle = NSLocalizedString(
            "no_additional_fee",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "No additional fee",
            comment: "No additional fee - Universal Checkout section text")

        static let additionalFeesTitle = NSLocalizedString(
            "surcharge-additional-fee",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Additional fee may apply",
            comment: "Additional fee may apply - Surcharge (Label)")

        static let vaultNavBarTitle = NSLocalizedString(
            "primer-vault-nav-bar-title",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add payment method",
            comment: "Add payment method - Vault Navigation Bar Title")

        static let checkoutTitleText = NSLocalizedString(
            "primer-card-form-checkout",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Checkout",
            comment: "Checkout - Card Form (Checkout title text)")

        static let vaultSubmitButtonText = NSLocalizedString(
            "primer-card-form-save",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Save",
            comment: "Save - Card Form (Vault submit button text)")

        enum CardNumber {

            static let label = NSLocalizedString(
                "primer-form-text-field-title-card-number",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Card number",
                comment: "Card number - Form Text Field Title (Card number)")

            static let placeholder = NSLocalizedString(
                "primer-card-form-4242-4242-4242-4242",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "4242 4242 4242 4242",
                comment: "4242 4242 4242 4242 - Card Form (Card text field placeholder text)")

            static let invalidErrorMessage = NSLocalizedString(
                "primer-error-card-form-card-number",
                bundle: Bundle.primerResources,
                value: "Invalid card number",
                comment: "An error message displayed when the card number is not correct")
        }

        enum ExpiryDate {

            static let label = NSLocalizedString(
                "primer-form-text-field-title-expiry-date",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Expiry date",
                comment: "Expiry date - Form Text Field Title (Expiry date)")

            static let placeholder = NSLocalizedString(
                "primer-card-form-12-24",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "12/24",
                comment: "12/24 - Card Form (Expiry text field placeholder text)")

            static let invalidErrorMessage = NSLocalizedString(
                "primer-error-card-form-card-expiration-date",
                bundle: Bundle.primerResources,
                value: "Invalid date",
                comment: "An error message displayed when the card expiration date is not correct")
        }

        enum CVV {

            static let label = NSLocalizedString(
                "primer-card-form-cvv",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "CVV",
                comment: "CVV - Card Form (CVV text field placeholder text)")

            static let placeholder = "123"

            static let invalidErrorMessage = NSLocalizedString(
                "primer-error-card-form-card-cvv",
                bundle: Bundle.primerResources,
                value: "Invalid CVV",
                comment: "An error message displayed when the cvv code is not correct")
        }

        enum Cardholder {

            static let label = NSLocalizedString(
                "primer-card-form-name",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Name",
                comment: "Cardholder name")

            static let placeholder = NSLocalizedString(
                "primer-form-text-field-placeholder-cardholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "e.g. John Doe",
                comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")

            static let invalidErrorMessage = NSLocalizedString(
                "cardholderErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Cardholder name",
                comment: "An error message displayed when the city field is not correct")
        }

        enum City {

            static let label = NSLocalizedString(
                "cityLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "City",
                comment: "The billing address city container view label"
            )

            static let placeholder = NSLocalizedString(
                "cityPlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "City",
                comment: "Form Text Field Placeholder (Address city)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "cityErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "City is required",
                comment: "City is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "cityErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid city",
                comment: "An error message displayed when the city field is not correct")
        }

        enum PostalCode {

            static let label = NSLocalizedString(
                "postalCodeLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Postal code",
                comment: "The billing address postal code container view label"
            )

            static let placeholder = NSLocalizedString(
                "postalCodePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Postal Code",
                comment: "Form Text Field Placeholder (Address postal code)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "postalCodeErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Postal code is required",
                comment: "Postal code is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "postalCodeErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid postal code",
                comment: "An error message displayed when the postal code field is not correct")
        }

        enum State {

            static let label = NSLocalizedString(
                "stateLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "State / Region / County",
                comment: "The billing address state container view label"
            )

            static let placeholder = NSLocalizedString(
                "statePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "State / Region / County",
                comment: "Form Text Field Placeholder (Address State / Region / County)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "stateErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "State, Region or County is required",
                comment: "State, Region or County is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "stateErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid State, Region or County",
                comment: "An error message displayed when the State, Region or County field is not correct")
        }

        enum AddressLine1 {

            static let label = NSLocalizedString(
                "addressLine1Label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 1",
                comment: "The billing address Address line 1 container view label"
            )

            static let placeholder = NSLocalizedString(
                "addressLine1Placeholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 1",
                comment: "Form Text Field Placeholder (Address line 1)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "addressLine1ErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address Line 1 is required",
                comment: "State, Region or County is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "addressLine1ErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Address Line 1",
                comment: "An error message displayed when the Address line 1 is not correct")
        }

        enum AddressLine2 {

            static let label = NSLocalizedString(
                "addressLine2Label",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 2",
                comment: "The billing address Address line 2 container view label"
            )

            static let placeholder = NSLocalizedString(
                "addressLine2Placeholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address line 2",
                comment: "Form Text Field Placeholder (Address line 2)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "addressLine2ErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Address Line 2 is required",
                comment: "State, Region or County is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "addressLine2ErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Address Line 2",
                comment: "An error message displayed when the Address line 2 is not correct")
        }

        enum CountryCode {

            static let label = NSLocalizedString(
                "countryCodeLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Country",
                comment: "The billing address Country code container view label"
            )

            static let placeholder = NSLocalizedString(
                "countryCodePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Country",
                comment: "Form Text Field Placeholder (Country code)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "countryCodeErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Country is required",
                comment: "Country is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "countryCodeErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Country",
                comment: "An error message displayed when the Country is not correct")
        }

        enum FirstName {

            static let label = NSLocalizedString(
                "firstNameLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name",
                comment: "The billing address First name container view label"
            )

            static let placeholder = NSLocalizedString(
                "firstNamePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name",
                comment: "Form Text Field Placeholder (First name)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "firstNameErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "First name is required",
                comment: "First name is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "firstNameErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid First Name",
                comment: "An error message displayed when the First Name is not correct")
        }

        enum LastName {

            static let label = NSLocalizedString(
                "lastNameLabel",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name",
                comment: "The billing address Last name container view label"
            )

            static let placeholder = NSLocalizedString(
                "lastNamePlaceholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name",
                comment: "Form Text Field Placeholder (Last name)"
            )

            static let isRequiredErrorMessage = NSLocalizedString(
                "lastNameErrorRequired",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Last name is required",
                comment: "Last name is required - Form Validation"
            )

            static let invalidErrorMessage = NSLocalizedString(
                "lastNameErrorInvalid",
                bundle: Bundle.primerResources,
                value: "Invalid Last Name",
                comment: "An error message displayed when the Last Name is not correct")
        }
    }
}

// MARK: - Apple Pay

extension Strings {

    struct ApplePay {

        static let surcharge = NSLocalizedString(
            "surcharge",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Additional fees",
            comment: "Surcharge - Apple Pay label")
    }
}

// MARK: - Blik

extension Strings {

    enum Blik {

        static let inputTopPlaceholder = NSLocalizedString(
            "input_hint_form_blik_otp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "6 digit code",
            comment: "6 digit code - Text field top placeholder")

        static let inputTextFieldPlaceholder = NSLocalizedString(
            "payment_method_blik_loading_placeholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter your one time password",
            comment: "Enter your one time password - Text field placeholder")

        static let inputDescriptor = NSLocalizedString(
            "input_description_otp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Get the code from your banking app.",
            comment: "Get the code from your banking app - Blik descriptor")

        static let completeYourPayment = NSLocalizedString(
            "completeYourPaymentInTheBlikApp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Complete your payment in Blik app",
            comment: "Info message suggesting the user to open the Blik app to complete the payment")
    }

    enum MBWay {

        static let inputTopPlaceholder = NSLocalizedString(
            "input_hint_form_mbway_phone_number",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Phone Number",
            comment: "Phone Number - Text field top placeholder")

        static let completeYourPayment = NSLocalizedString(
            "completeYourPaymentInTheApp",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Complete your payment in the MB WAY app",
            comment: "Info message suggesting the user to open the MB WAY app to complete the payment")
    }

}

// MARK: - Primer Test (DummyAPMs)// MARK: - Blik

extension Strings {

    enum PrimerTest {

        static let headerViewText = NSLocalizedString(
            "primer-test-header-description",
            bundle: Bundle.primerResources,
            value: "This is a mocked flow for sandbox. Choose the result you want to test from the list below.",
            comment: "The title of the header for the flow decision view")
    }

    enum PrimerTestFlowDecision {

        static let successTitle = NSLocalizedString(
            "primer-test-payment-method-success-flow-title",
            bundle: Bundle.primerResources,
            value: "Authorized",
            comment: "The title of the mocked successful flow for a Test Payment Method")

        static let declineTitle = NSLocalizedString(
            "primer-test-payment-method-decline-flow-title",
            bundle: Bundle.primerResources,
            value: "Declined",
            comment: "The title of the mocked declined flow for a Test Payment Method")

        static let failTitle = NSLocalizedString(
            "primer-test-payment-method-fail-flow-title",
            bundle: Bundle.primerResources,
            value: "Failed",
            comment: "The title of the mocked failed flow for a Test Payment Method")
    }
}
