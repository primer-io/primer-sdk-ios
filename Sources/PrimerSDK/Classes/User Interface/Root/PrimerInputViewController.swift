//
//  PrimerInputViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/11/21.
//

#if canImport(UIKit)

import UIKit

internal class Input {
    var name: String?
    var topPlaceholder: String?
    var textFieldPlaceholder: String?
    var keyboardType: UIKeyboardType?
    var allowedCharacterSet: CharacterSet?
    var maxCharactersAllowed: UInt?
    var isValid: ((_ text: String) -> Bool?)?
    var descriptor: String?
    var text: String?
    var primerTextFieldView: PrimerTextFieldView?
}

internal class PrimerInputViewController: PrimerFormViewController {
    
    private(set) var inputs: [Input] = []
    private let confirmButton = PrimerButton()
    
    init(inputs: [Input]) {
        self.inputs = inputs
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Blik"
        
        verticalStackView.spacing = 16
        
        for input in inputs {
            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.spacing = 2
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .fill
            
            let inputTextFieldView = PrimerGenericFieldView()
            inputTextFieldView.delegate = self
            inputTextFieldView.translatesAutoresizingMaskIntoConstraints = false
            inputTextFieldView.heightAnchor.constraint(equalToConstant: 35).isActive = true
            inputTextFieldView.textField.keyboardType = input.keyboardType ?? .default
            inputTextFieldView.allowedCharacterSet = input.allowedCharacterSet
            inputTextFieldView.maxCharactersAllowed = input.maxCharactersAllowed
            inputTextFieldView.isValid = input.isValid
            inputTextFieldView.shouldMaskText = false
            input.primerTextFieldView = inputTextFieldView
            
            let inputContainerView = PrimerCustomFieldView()
            inputContainerView.fieldView = inputTextFieldView
            inputContainerView.placeholderText = input.topPlaceholder
            inputContainerView.setup()
            inputContainerView.tintColor = .systemBlue
            stackView.addArrangedSubview(inputContainerView)
            
            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                stackView.addArrangedSubview(lbl)
            }
            
            verticalStackView.addArrangedSubview(stackView)
        }
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        confirmButton.isEnabled = false
        confirmButton.clipsToBounds = true
        confirmButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        confirmButton.layer.cornerRadius = 4
        confirmButton.backgroundColor = confirmButton.isEnabled ? .systemBlue : .lightGray
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        verticalStackView.addArrangedSubview(confirmButton)
    }
    
    private func enableConfirmButton(_ flag: Bool) {
        confirmButton.isEnabled = flag
        confirmButton.backgroundColor = flag ? .systemBlue : .lightGray
    }

    @objc
    func confirmButtonTapped() {
        view.endEditing(true)
    }
    

}

extension PrimerInputViewController: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        if let input = inputs.filter({ $0.primerTextFieldView == primerTextFieldView }).first {
            
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        let isTextsValid = inputs.compactMap({ $0.primerTextFieldView?.isTextValid })
        
        if isTextsValid.contains(false) {
            enableConfirmButton(false)
        } else {
            enableConfirmButton(true)
        }

        print("Validations:\n\(isTextsValid)")
    }
    
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        return true
    }
    
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        if let input = inputs.filter({ $0.primerTextFieldView == primerTextFieldView }).first {
            
        }
        return true
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {
        
    }
    
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {
        print("primerTextFieldView: \(primerTextFieldView.text)")
    }
    
}


#endif
