//
//  Strings.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 10/02/22.
//  Copyright © 2022 Primer API ltd, Inc. All rights reserved.
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
            comment: "Edit - Vault Payment Method (Button text)"
        )
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
        
        static let submitButtonTitle = NSLocalizedString(
            "primer-confirm-mandate-confirm",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Confirm",
            comment: "Confirm - Confirm Mandate (Button text)"
        )
    }
    
    // MARK: Card Form
    
    enum PrimerCardFormView {
        
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
        
        static let cardButtonText = NSLocalizedString(
            "primer-direct-checkout-pay-by-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay by card",
            comment: "Pay by card - Direct Checkout (Card button text)")
        
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
            if case .VAULT = Primer.shared.flow.internalSessionFlow.uxMode {
                return availablePaymentMethodsTitle
            } else {
                return savedPaymentMethodsTitle
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
        
        static let payWithCard = NSLocalizedString(
            "payment-method-type-card-not-vaulted",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay with card",
            comment: "Pay with card - Payment Method Type (Card Not vaulted)")
    }
    
    // MARK: Card form
    
    enum CardFormView {
        
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
        
        static let cardNumberTextFieldTitle = NSLocalizedString(
            "primer-form-text-field-title-card-number",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Card number",
            comment: "Card number - Form Text Field Title (Card number)")
        
        static let expiryDateTextFieldTitle = NSLocalizedString(
            "primer-form-text-field-title-expiry-date",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Expiry date",
            comment: "Expiry date - Form Text Field Title (Expiry date)")
        
        static let cvvTextFieldTitle = NSLocalizedString(
            "primer-card-form-cvv",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "CVV",
            comment: "CVV - Card Form (CVV text field placeholder text)")
        
        static let cardholderTextFieldTitle = NSLocalizedString(
            "primer-card-form-name",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Name",
            comment: "Cardholder name")
        
        static let cardholderTextFieldPlaceholder = NSLocalizedString(
            "primer-form-text-field-placeholder-cardholder",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "e.g. John Doe",
            comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")
        
        static let cardTextFieldPlaceholder = NSLocalizedString(
            "primer-card-form-4242-4242-4242-4242",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "4242 4242 4242 4242",
            comment: "4242 4242 4242 4242 - Card Form (Card text field placeholder text)")
        
        static let expiryTextFieldPlaceholder = NSLocalizedString(
            "primer-card-form-12-24",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "12/24",
            comment: "12/24 - Card Form (Expiry text field placeholder text)")
        
        static let cvcTextFieldPlaceholder = NSLocalizedString(
            "primer-card-form-cvv",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "CVV",
            comment: "CVV - Card Form (CVV text field placeholder text)")
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
        
    }
}
