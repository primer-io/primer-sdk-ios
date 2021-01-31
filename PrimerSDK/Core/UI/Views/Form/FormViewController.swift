//
//  BankAccountFormViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

import UIKit

class FormViewController: UIViewController {
    let subview: FormView = FormView()
    
    let viewModel: FormViewModelProtocol
    
    var validatedFields: [Bool]
    
    weak var router: RouterDelegate?
    weak var reloadDelegate: ReloadDelegate?
    
    var formType: FormType { return viewModel.formType }
    
    init(viewModel: FormViewModelProtocol, router: RouterDelegate) {
        self.viewModel = viewModel
        self.router = router
        self.validatedFields = viewModel.formType.textFields.map { _ in return false }
        super.init(nibName: nil, bundle: nil)
        view.addSubview(subview)
        subview.delegate = self
        subview.pin(to: view)
        subview.render()
        view.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.isHidden = true
    }
}

extension FormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
      textField.resignFirstResponder()
      return true
    }
}

extension FormViewController: FormViewDelegate {
    
    func back() {
        router?.pop()
    }
    
    func openLink() {
        switch formType {
//        case .iban: router?.popAndShow(.form(type: .bankAccount(mandate: viewModel.mandate)))
//        case .bankAccount: router?.popAndShow(.form(type: .iban(mandate: viewModel.mandate)))
        default: break
        }
    }
    
    func submit(_ value: String?, type: FormTextFieldType) {
        viewModel.setState(value, type: type)
    }
    
    func onSubmit() {
        if (viewModel.popOnComplete) {
            router?.pop()
            return
        }
        switch formType {
        case .iban: router?.show(.form(type: .name(mandate: viewModel.mandate)))
        case .bankAccount: router?.show(.form(type: .name(mandate: viewModel.mandate)))
        case .name: router?.show(.form(type: .email(mandate: viewModel.mandate)))
        case .email: router?.show(.form(type: .address(mandate: viewModel.mandate)))
        case .address: router?.popAllAndShow(.confirmMandate)
        }
    }
}

protocol FormViewModelProtocol {
    var formType: FormType { get }
    var popOnComplete: Bool { get }
    var mandate: DirectDebitMandate { get }
    func setState(_ value: String?, type: FormTextFieldType)
}

class FormViewModel: FormViewModelProtocol {
    
    var formType: FormType
    
    var popOnComplete: Bool {
        return formType.popOnComplete
    }
    var mandate: DirectDebitMandate {
        return state.directDebitMandate
    }
    
    private var state: AppStateProtocol
    
    init(context: CheckoutContextProtocol, formType: FormType) {
        self.formType = formType
        self.state = context.state
    }
    
    deinit { print("🧨 destroy:", self.self) }
    
    func setState(_ value: String?, type: FormTextFieldType) {
        switch type {
        case .iban: state.directDebitMandate.iban = value?.withoutWhiteSpace
        case .accountNumber: state.directDebitMandate.accountNumber = value
        case .addressLine1: state.directDebitMandate.address?.addressLine1 = value
        case .addressLine2: state.directDebitMandate.address?.addressLine2 = value
        case .city: state.directDebitMandate.address?.city = value
        case .country: state.directDebitMandate.address?.countryCode = value
        case .email: state.directDebitMandate.email = value
        case .firstName: state.directDebitMandate.firstName = value
        case .lastName: state.directDebitMandate.lastName = value
        case .postalCode: state.directDebitMandate.address?.postalCode = value
        case .sortCode: state.directDebitMandate.sortCode = value
        }
        print(state.directDebitMandate)
    }
}
