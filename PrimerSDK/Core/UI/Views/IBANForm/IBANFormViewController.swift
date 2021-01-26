//
//  IBANFormViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

import UIKit

class IBANFormViewController: UIViewController {
    var formView: IBANFormView = IBANFormView()
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
        formView.delegate = self
        view.addSubview(formView)
    }
    
    deinit { print("🧨 destroy:", self.self) }
}

extension IBANFormViewController: IBANFormViewDelegate {
    var theme: PrimerTheme {
        return viewModel.theme
    }
    func cancel() { self.dismiss(animated: true, completion: nil) }
    func next() {}
    
    func onIBANTextFieldChanged(_ sender: UITextField) {
        guard let currentText = sender.text else  { return }
        let ibanMask = Mask(pattern: "**** **** **** **** **** **** **** **** **")
        sender.text = ibanMask.apply(on: currentText.uppercased())
    }
}
