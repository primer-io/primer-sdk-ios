//
//  Content.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 12/10/2021.
//

internal struct Content {
    
    struct VaultCheckoutView {
        static let payButtonTitle = NSLocalizedString(
            "primer-vault-checkout-pay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay",
            comment: "Pay - Vault checkout (Button text)"
        )
    }
    
    struct ScannerView {
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
    
    struct VaultView {
        static let editLabel = NSLocalizedString(
            "primer-vault-payment-method-edit",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Edit",
            comment: "Edit - Vault Payment Method (Button text)"
        )
        
        static let title = ""
    }
    
    struct CheckoutView {
        static let payButtonTitle = NSLocalizedString(
            "primer-vault-checkout-pay",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay",
            comment: "Pay - Vault checkout (Button text)"
        )
    }
    
    struct ConfirmMandateView {
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
    
    struct PrimerCardFormView {
        static let title = NSLocalizedString(
            "primer-form-type-main-title-card-form",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Enter your card details",
            comment: "Enter your card details - Form Type Main Title (Card)"
        )
        
        static let payButtonTitle = NSLocalizedString(
            "primer-form-view-card-submit-button-text-checkout",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Pay",
            comment: "Pay - Card Form View (Sumbit button text)"
        )
        
        static let addCardButtonTitle = NSLocalizedString(
            "primer-card-form-add-card",
            tableName: nil,
            bundle: Bundle.primerResources,
            value: "Add card",
            comment: "Add card - Card Form (Vault title text)"
        )
    }
}
