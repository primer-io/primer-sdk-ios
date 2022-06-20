#if canImport(UIKit)

import Foundation

public struct PrimerContent {
    let ibanForm = IBANFormViewContent()
    let directCheckout = DirectCheckoutViewContent()
    let vaultCheckout = VaultCheckoutViewContent()
    let vaultPaymentMethodView = VaultPaymentMethodViewContent()
    let scannerView = ScannerViewContent()
    let cardFormView = CardFormViewContent()
    let singleFieldFormDirectDebitContent = SingleFieldFormDirectDebitContent()
    var formMainTitles = FormMainTitles()
    var formTopTitles = FormTopTitles()
    var confirmMandateContent = ConfirmMandateViewContent()

    mutating func setTopTitle(_ text: String, for formType: PrimerFormType) {
        switch formType {
        case .address: formTopTitles.address = text
        case .cardForm: formTopTitles.cardForm = text
        case .name: formTopTitles.name = text
        case .email: formTopTitles.email = text
        case .iban: formTopTitles.iban = text
        case .bankAccount: formTopTitles.bankAccount = text
        }
    }
}

struct ConfirmMandateViewContent {
    var topTitleText: String { return NSLocalizedString("primer-confirm-mandate-add-bank-account",
                                                        tableName: nil,
                                                        bundle: Bundle.primerResources,
                                                        value: "Add Bank Account",
                                                        comment: "Add Bank Account - Confirm Mandate (Top title text_") }

    var mainTitleText: String { return NSLocalizedString("primer-confirm-mandate-confirm-sepa-direct-debit",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "Confirm SEPA Direct Debit",
                                                         comment: "Confirm SEPA Direct Debit - Confirm Mandate (Main title text)") }

    var submitButtonLabelText: String { return NSLocalizedString("primer-confirm-mandate-confirm",
                                                                 tableName: nil,
                                                                 bundle: Bundle.primerResources,
                                                                 value: "Confirm",
                                                                 comment: "Confirm - Confirm Mandate (Button text)") }
}

struct IBANFormViewContent {
    var mainTitleText: String { return NSLocalizedString("primer-iban-form-add-bank-account",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "Add Bank Account",
                                                         comment: "Add Bank Account - IBAN Form (Main title)") }

    var subtitleText: String { return NSLocalizedString("primer-iban-form-monthly-fee-automatically-deducted",
                                                        tableName: nil,
                                                        bundle: Bundle.primerResources,
                                                        value: "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate",
                                                        comment: "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate - IBAN Form (Subtitle text)") }

    var textFieldPlaceholder: String { return NSLocalizedString("primer-iban-form-enter-iban",
                                                                tableName: nil,
                                                                bundle: Bundle.primerResources,
                                                                value: "Enter IBAN",
                                                                comment: "Enter IBAN - IBAN Form (Text field placeholder text") }

    var switchLabelText: String { return NSLocalizedString("primer-iban-form-use-account-number-instead",
                                                           tableName: nil,
                                                           bundle: Bundle.primerResources,
                                                           value: "Use an account number instead",
                                                           comment: "Use an account number instead - IBAN Form (Switch text)") }

    var nextButtonText: String { return NSLocalizedString("primer-iban-form-next",
                                                          tableName: nil,
                                                          bundle: Bundle.primerResources,
                                                          value: "Next",
                                                          comment: "Next - IBAN Form (Button text)")}
}

struct DirectCheckoutViewContent {
    var cardButtonText: String { return NSLocalizedString("primer-direct-checkout-pay-by-card",
                                                          tableName: nil,
                                                          bundle: Bundle.primerResources,
                                                          value: "Pay by card",
                                                          comment: "Pay by card - Direct Checkout (Card button text)") }

    var applePayButtonText: String { return NSLocalizedString("primer-direct-checkout-apple-pay",
                                                              tableName: nil,
                                                              bundle: Bundle.primerResources,
                                                              value: "Apple pay",
                                                              comment: "Apple pay - Direct Checkout (Apple pay button text)") }

    var payPalText: String { return NSLocalizedString("primer-direct-checkout-paypal",
                                                      tableName: nil,
                                                      bundle: Bundle.primerResources,
                                                      value: "PayPal",
                                                      comment: "PayPal - Direct Checkout (PayPal button text") }
}

struct VaultCheckoutViewContent {
    var payButtonText: String { return NSLocalizedString("primer-vault-checkout-pay",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "Pay",
                                                         comment: "Pay - Vault checkout (Button text)") }
}

struct VaultPaymentMethodViewContent {
    var mainTitleText: String {
        if Primer.shared.intent == .vault {
            return NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                                             tableName: nil,
                                                             bundle: Bundle.primerResources,
                                                             value: "Available payment methods",
                                                             comment: "Available payment methods - Vault Payment Method (Main title text)")
        } else {
            return NSLocalizedString("primer-vault-payment-method-saved-payment-methods",
                                                             tableName: nil,
                                                             bundle: Bundle.primerResources,
                                                             value: "Saved payment methods",
                                                             comment: "Saved payment methods - Vault Payment Method (Main title text)")
        }
    }

    var editButtonText: String { return NSLocalizedString("primer-vault-payment-method-edit",
                                                          tableName: nil,
                                                          bundle: Bundle.primerResources,
                                                          value: "Edit",
                                                          comment: "Edit - Vault Payment Method (Button text)") }

    var addButtonText: String { return NSLocalizedString("primer-vault-payment-method-add-new-card",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "Add new card",
                                                         comment: "Add new card - Vault Payment Method (Button text)") }
}

struct ScannerViewContent {
    var titleText: String { return NSLocalizedString("primer-scanner-view-scan-card",
                                                     tableName: nil,
                                                     bundle: Bundle.primerResources,
                                                     value: "Scan card",
                                                     comment: "Scan card - Scanner view (Title text)") }

    var descriptionText: String { return NSLocalizedString("primer-scanner-view-scan-front-card",
                                                           tableName: nil,
                                                           bundle: Bundle.primerResources,
                                                           value: "Scan the front of your card",
                                                           comment: "Scan the front of your card - Scanner view (Description text)") }

    var skipButtonText: String { return NSLocalizedString("primer-scanner-view-manual-input",
                                                          tableName: nil,
                                                          bundle: Bundle.primerResources,
                                                          value: "Manual input",
                                                          comment: "Manual input - Scanner view (Button text)") }
}

struct CardFormViewContent {
    var checkoutTitleText: String { return NSLocalizedString("primer-card-form-checkout",
                                                             tableName: nil,
                                                             bundle: Bundle.primerResources,
                                                             value: "Checkout",
                                                             comment: "Checkout - Card Form (Checkout title text)") }

    var vaultTitleText: String { return NSLocalizedString("primer-card-form-add-card",
                                                          tableName: nil,
                                                          bundle: Bundle.primerResources,
                                                          value: "Add card",
                                                          comment: "Add card - Card Form (Vault title text)") }

    var checkoutSubmitButtonText: String { return NSLocalizedString("primer-card-form-pay",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "Pay",
                                                                    comment: "Pay - Card Form (Checkout submit button text)") }

    var vaultSubmitButtonText: String { return NSLocalizedString("primer-card-form-save",
                                                                 tableName: nil,
                                                                 bundle: Bundle.primerResources,
                                                                 value: "Save",
                                                                 comment: "Save - Card Form (Vault submit button text)") }

    var scannerButtonText: String { return NSLocalizedString("primer-card-form-scan-card",
                                                             tableName: nil,
                                                             bundle: Bundle.primerResources,
                                                             value: "Scan card",
                                                             comment: "Scan card - Card Form (Scanner button text)") }

    var nameTextFieldPlaceholder: String { return NSLocalizedString("primer-card-form-john-doe",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "John Doe",
                                                                    comment: "John Doe - Card Form (Name text field placeholder text)") }

    var cardTextFieldPlaceholder: String { return NSLocalizedString("primer-card-form-4242-4242-4242-4242",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "4242 4242 4242 4242",
                                                                    comment: "4242 4242 4242 4242 - Card Form (Card text field placeholder text)") }

    var expiryTextFieldPlaceholder: String { return NSLocalizedString("primer-card-form-12-24",
                                                                      tableName: nil,
                                                                      bundle: Bundle.primerResources,
                                                                      value: "12/24",
                                                                      comment: "12/24 - Card Form (Expiry text field placeholder text)") }

    var cvcTextFieldPlaceholder: String { return NSLocalizedString("primer-card-form-cvv",
                                                                   tableName: nil,
                                                                   bundle: Bundle.primerResources,
                                                                   value: "CVV",
                                                                   comment: "CVV - Card Form (CVV text field placeholder text)") }
}

struct SingleFieldFormDirectDebitContent {
    var navBarRightText: String { return NSLocalizedString("primer-nav-bar-confirm",
                                                           tableName: nil,
                                                           bundle: Bundle.primerResources,
                                                           value: "Confirm",
                                                           comment: "Confirm - Single Field Form (Navigation bar right button text)") }

    var navBarTitle: String { return NSLocalizedString("primer-nav-bar-add-bank-account",
                                                       tableName: nil,
                                                       bundle: Bundle.primerResources,
                                                       value: "Add Bank Account",
                                                       comment: "Add Bank Account - Single Field Form (Navigation bar title text)") }
}

internal protocol FormProtocol {
    var address: String { get }
    var cardForm: String { get }
    var name: String { get }
    var email: String { get }
    var iban: String { get }
    var bankAccount: String { get }
}

public struct FormMainTitles {
    private var titles = Dictionary(
        uniqueKeysWithValues: PrimerFormType.allCases.map { ($0.rawValue, "") }
    )

    mutating func setMainTitle(_ text: String, for formType: PrimerFormType) {
        titles[formType.rawValue] = text
    }

    func getMainTitle(for formType: PrimerFormType) -> String {
        return titles[formType.rawValue]!
    }
}

public struct FormTopTitles: FormProtocol {
    var address = ""
    var cardForm = ""
    var name = ""
    var email = ""
    var iban = ""
    var bankAccount = ""
}

internal extension FormTopTitles {
    mutating func setTopTitle(_ text: String, for formType: PrimerFormType) {
        switch formType {
        case .address: address = text
        case .cardForm: cardForm = text
        case .name: name = text
        case .email: email = text
        case .iban: iban = text
        case .bankAccount: bankAccount = text
        }
    }
}

#endif
