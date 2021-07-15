//
//  BankAccountFormViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class FormViewController: PrimerViewController {
    let subview: FormView = FormView()

    weak var reloadDelegate: ReloadDelegate?

    var formType: FormType
    
    
    // This is really bad 😢 Since we have no navigation controller logic, and we need a way to
    // know when we pop the view controller within the 'keyboardWillHide(:)' function, that'll do
    // for now ¯\_(ツ)_/¯
    var isPopping: Bool = false


    init() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        formType = state.routerState.formType!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        view.addSubview(subview)
        subview.delegate = self
        subview.pin(to: view)
        subview.render()
        view.layoutIfNeeded()
        
        let viewModel: FormViewModelProtocol = DependencyContainer.resolve()
        viewModel.loadConfig({ [weak self] _ in
            DispatchQueue.main.async {

            }
        })
    }

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }
}

extension FormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   // delegate method
        textField.resignFirstResponder()
        return true
    }
}

extension FormViewController: FormViewDelegate {

    func back() {
        isPopping = true
        view.endEditing(true)
        let viewModel: FormViewModelProtocol = DependencyContainer.resolve()
        viewModel.onReturnButtonTapped()
    }

    func openLink() {

    }

    func submit(_ value: String?, type: FormTextFieldType) {
        let viewModel: FormViewModelProtocol = DependencyContainer.resolve()
        viewModel.setState(value, type: type)
    }

    var submitButtonTitle: String {
        let viewModel: FormViewModelProtocol = DependencyContainer.resolve()
        return viewModel.getSubmitButtonTitle(formType: formType)
    }

    func onSubmit() {
        view.endEditing(true)
        let viewModel: FormViewModelProtocol = DependencyContainer.resolve()
        viewModel.onSubmit(formType: formType)
    }

    func onBottomLinkTapped() {
        #if canImport(CardScan)
        viewModel.onBottomLinkTapped(delegate: self)
        #endif
    }
}

#if canImport(CardScan)
internal extension FormViewController: CardScannerViewControllerDelegate {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails) {
        switch formType {
        case .cardForm:
            subview.textFields[0][0].text = cardDetails.name
            let numberMask = Mask(pattern: "#### #### #### ####")
            subview.textFields[1][0].text = numberMask.apply(on: cardDetails.number!)
            guard let year = cardDetails.expiryYear else { return }
            guard let month = cardDetails.expiryMonth else { return }
            subview.textFields[2][0].text = month + "/" + year
        default:
            break
        }
    }
}
#endif

#endif
