//
//  IBANFormViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

import UIKit

class IBANFormViewController: UIViewController {
    
    var formView: IBANFormView?
    let viewModel: IBANFormViewModelProtocol
    let transitionDelegate = TransitionDelegate()
    
    init(viewModel: IBANFormViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        view.backgroundColor = viewModel.theme.backgroundColor
        formView = IBANFormView(frame: view.frame, theme: viewModel.theme)
        formView?.delegate = self
        view.addSubview(formView!)
    }
    
    deinit { print("🧨 destroy:", self.self) }
}

extension IBANFormViewController: IBANFormViewDelegate {
    func cancel() { self.dismiss(animated: true, completion: nil) }
    func next() {
        let confirmMandateViewModel = viewModel.confirmMandateViewModel
        let confirmMandateViewController = ConfirmMandateViewController(viewModel: confirmMandateViewModel)
        confirmMandateViewController.iban = formView?.textField.text
        self.present(confirmMandateViewController, animated: true, completion: nil)
    }
    
    func onIBANTextFieldChanged(_ sender: UITextField) {
        guard let currentText = sender.text else  { return }
        let ibanMask = Mask(pattern: "**** **** **** **** **** **** **** **** **")
        sender.text = ibanMask.apply(on: currentText.uppercased())
    }
}

protocol IBANFormViewDelegate: class {
    func cancel() -> Void
    func next() -> Void
    func onIBANTextFieldChanged(_ sender: UITextField) -> Void
}
