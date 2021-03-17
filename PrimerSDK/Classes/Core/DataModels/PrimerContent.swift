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
    var topTitleText: String { return "Add bank account".localized() }
    var mainTitleText: String { return "Confirm SEPA Direct Debit".localized() }
    var submitButtonLabelText: String { return "Confirm".localized() }
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
    var mainTitleText: String { return "Saved payment methods".localized() }
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

protocol FormProtocol {
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

extension FormTopTitles {
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
