public struct PrimerContent {
    let ibanForm = IBANFormViewContent()
    let directCheckout = DirectCheckoutViewContent()
    let vaultCheckout = VaultCheckoutViewContent()
    let vaultPaymentMethodView = VaultPaymentMethodViewContent()
    let scannerView = ScannerViewContent()
    let cardFormView = CardFormViewContent()
    let singleFieldFormDirectDebitContent = SingleFieldFormDirectDebitContent()
}

struct IBANFormViewContent {
    var mainTitleText: String { return "Add bank account".localized() }
    var subtitleText: String { return "Your monthly fee will be automatically deducted from this account, using SEPA Core DirectDebit Mandate".localized() }
    var textFieldPlaceholder: String { return "Enter IBAN".localized() }
    var switchLabelText: String { return "Use an account number instead".localized() }
    var nextButtonText: String { return "Next".localized() }
}

struct DirectCheckoutViewContent {
    var cardButtonText: String { return "Pay by card".localized() }
    var applePayButtonText: String { return "Apple pay".localized() }
    var payPalText: String { return "PayPal".localized() }
}

struct VaultCheckoutViewContent {
    var payButtonText: String { return "Pay".localized() }
}

struct VaultPaymentMethodViewContent {
    var mainTitleText: String { return "Other ways to pay".localized() }
    var editButtonText: String { return "Edit".localized() }
    var addButtonText: String { return "Add new card".localized() }
}

struct ScannerViewContent {
    var titleText: String { return "Scan card".localized() }
    var descriptionText: String { return "Scan the front of your card".localized() }
    var skipButtonText: String { return "Manual input".localized() }
}

struct CardFormViewContent {
    var checkoutTitleText: String { return "Checkout".localized() }
    var vaultTitleText: String { return "Add card".localized() }
    var checkoutSubmitButtonText: String { return "Pay".localized() }
    var vaultSubmitButtonText: String { return "Save".localized() }
    var scannerButtonText: String { return "Scan card".localized() }
    var nameTextFieldPlaceholder: String { return "John Doe".localized() }
    var cardTextFieldPlaceholder: String { return "4242 4242 4242 4242".localized() }
    var expiryTextFieldPlaceholder: String { return "12/20".localized() }
    var cvcTextFieldPlaceholder: String { return "CVV".localized() }
}

struct SingleFieldFormDirectDebitContent {
    var navBarRightText: String { return "Confirm".localized() }
    var navBarTitle: String { return "Add bank account".localized() }
}
