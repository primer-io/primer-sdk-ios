//
//  SingleFieldFormViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 18/01/2021.
//

import UIKit

enum SingleFieldFormType {
    case directDebit
}

class SingleFieldFormViewController: UIViewController {
    
    var subView: SingleFieldFormView = SingleFieldFormView()
    var viewModel: SingleFieldFormViewModelProtocol
    weak var router: RouterDelegate?
    
    init(viewModel: SingleFieldFormViewModelProtocol, router: RouterDelegate) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewDidLoad() {
        self.subView = SingleFieldFormView()
        subView.delegate = self
        view.addSubview(subView)
        subView.pin(to: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        subView.textField.becomeFirstResponder()
    }
}

enum TextFieldType {
    case iban(_ initialValue: String?)
    case name(_ initialValue: String?)
    case email(_ initialValue: String?)
    case address(_ initialValue: String?)
    
    var mask: Mask? {
        switch self {
        case .iban: return Mask(pattern: "**** **** **** **** **** **** **** **** **")
        case .name: return nil
        case .email: return nil
        case .address: return nil
        }
    }
    
    var initialValue: String? {
        switch self {
        case .iban(let val): return val
        case .name(let val): return val
        case .email(let val): return val
        case .address(let val): return val
        }
    }
    
    var topTitle: String {
        switch self {
        case .iban: return "Add bank account"
        case .name: return "Add bank account"
        case .email: return "Add bank account"
        case .address: return "Add bank account"
        }
    }
    
    var topRightButtonTitle: String {
        switch self {
        case .iban: return "Confirm"
        case .name: return "Confirm"
        case .email: return "Confirm"
        case .address: return "Confirm"
        }
    }
    
    var mainTitle: String {
        switch self {
        case .iban: return "SEPA Direct Debit Mandate"
        case .name: return ""
        case .email: return ""
        case .address: return ""
        }
    }
    
    var placeHolder: String {
        switch self {
        case .iban: return "IBAN"
        case .name: return "First and last name"
        case .email: return "Email"
        case .address: return "Address"
        }
    }
    
    var subtitle: String {
        switch self {
        case .iban: return "Use an account number instead"
        case .name: return ""
        case .email: return ""
        case .address: return ""
        }
    }
    
    func validate(_ text: String) -> Bool {
        switch self {
        case .iban: return text.isNotValidIBAN
        case .name: return text.isEmpty
        case .email:
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return !emailPred.evaluate(with: text)
        case .address:
            return text.isEmpty
        }
    }
}

extension UIButton {
    func toggleValidity(_ isValid: Bool, validColor: UIColor) {
        self.backgroundColor = isValid ? validColor : Primer.theme.colorTheme.main2
        self.isEnabled = isValid
    }
}

extension SingleFieldFormViewController: SingleFieldFormViewDelegate {
    
    var textFieldType: TextFieldType {
        return viewModel.textFieldType
    }
    
    var theme: PrimerTheme {
        return viewModel.theme
    }
    
    func back() {
        router?.pop()
    }
    
    func confirm() {
        print("confirming")
    }
    
    func onSubmit() {
        if (viewModel.mandateCompleted) {
            router?.pop(); return
        }
        switch viewModel.textFieldType {
        case .iban: router?.show(.singleFieldForm(type: .name(viewModel.mandate.firstName)))
        case .name: router?.show(.singleFieldForm(type: .email(viewModel.mandate.email)))
        case .email: router?.show(.singleFieldForm(type: .address("")))
        case .address: router?.popAllAndShow(.confirmMandate)
        }
    }
    
    func onTextFieldEditingDidEnd(_ sender: UITextField) {
        guard let text = sender.text else  { return }
        sender.toggleValidity(viewModel.textFieldType.validate(text), theme: theme.textFieldTheme)
    }
    
    func onTextFieldEditingChanged(_ sender: UITextField, mainButton: UIButton) {
        guard let text = sender.text else { return }
        viewModel.setState(text)
        let validColor = viewModel.theme.colorTheme.tint1
        mainButton.toggleValidity(viewModel.textFieldType.validate(text), validColor: validColor)
        guard let mask = viewModel.textFieldType.mask else { return }
        sender.text = mask.apply(on: text.uppercased())
    }
}

protocol SingleFieldFormViewModelProtocol {
    var theme: PrimerTheme { get }
    var mandateCompleted: Bool { get }
    var mandate: DirectDebitMandate { get }
    var textFieldType: TextFieldType { get }
    func setState(_ text: String)
}

class SingleFieldFormViewModel: SingleFieldFormViewModelProtocol {
    var theme: PrimerTheme { return context.settings.theme }
    var mandateCompleted: Bool { return context.state.directDebitFormCompleted }
    var mandate: DirectDebitMandate { return context.state.directDebitMandate }
    
    let textFieldType: TextFieldType
    
    private let context: CheckoutContext
    
    init(context: CheckoutContext, textFieldType: TextFieldType) {
        self.context = context
        self.textFieldType = textFieldType
    }
    
    deinit { print("🧨 destroy:", self.self) }
    
    func setState(_ text: String) {
        switch textFieldType {
        case .iban: context.state.directDebitMandate.iban = text.withoutWhiteSpace
        case .name: context.state.directDebitMandate.firstName = text
        case .email: context.state.directDebitMandate.email = text
        default: print("default")
        }
        print(context.state.directDebitMandate)
    }
    
}

extension String {
    var withoutWhiteSpace: String {
        return self.filter { !$0.isWhitespace }
    }
    
    var isNotValidIBAN: Bool {
        return self.withoutWhiteSpace.count < 6
    }
}
