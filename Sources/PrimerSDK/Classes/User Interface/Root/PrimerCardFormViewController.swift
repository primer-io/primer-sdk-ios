//
//  PrimerCardFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// Subclass of the PrimerFormViewController that uses the checkout components and the card components manager
class PrimerCardFormViewController: PrimerFormViewController {
    
    private var cardComponentsManager: CardComponentsManager!
    private var flow: PaymentFlow!
    
    private let cardNumberContainerView = PrimerCustomFieldView()
    private let cardNumberField = PrimerCardNumberFieldView()
    private let expiryDateContainerView = PrimerCustomFieldView()
    private let expiryDateField = PrimerExpiryDateFieldView()
    private let cvvContainerView = PrimerCustomFieldView()
    private let cvvField = PrimerCVVFieldView()
    private let cardholderNameContainerView = PrimerCustomFieldView()
    private let cardholderNameField = PrimerCardholderNameFieldView()
    private let submitButton = PrimerButton()
    
    init(flow: PaymentFlow) {
        self.flow = flow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        title = NSLocalizedString("primer-form-type-main-title-card-form",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Enter your card details",
                                  comment: "Enter your card details - Form Type Main Title (Card)")
        
        view.backgroundColor = .white
        
        verticalStackView.spacing = 2
        
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = .black
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = self
        
        cardNumberContainerView.fieldView = cardNumberField
        cardNumberContainerView.placeholderText = "Card number"
        cardNumberContainerView.setup()
        verticalStackView.addArrangedSubview(cardNumberContainerView)

        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fillEqually
        
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.delegate = self
        
        expiryDateContainerView.fieldView = expiryDateField
        expiryDateContainerView.placeholderText = "Expiry"
        expiryDateContainerView.setup()
        horizontalStackView.addArrangedSubview(expiryDateContainerView)
        
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.delegate = self
        
        cvvContainerView.fieldView = cvvField
        cvvContainerView.placeholderText = "CVV/CVC"
        cvvContainerView.setup()
        horizontalStackView.addArrangedSubview(cvvContainerView)
        horizontalStackView.spacing = 16
        verticalStackView.addArrangedSubview(horizontalStackView)
        
        cardholderNameField.placeholder = "John Smith"
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.delegate = self
        
        cardholderNameContainerView.fieldView = cardholderNameField
        cardholderNameContainerView.placeholderText = "Name"
        cardholderNameContainerView.setup()
        verticalStackView.addArrangedSubview(cardholderNameContainerView)
        
        if flow == .checkout {
            let saveCardSwitchContainerStackView = UIStackView()
            saveCardSwitchContainerStackView.axis = .horizontal
            saveCardSwitchContainerStackView.alignment = .fill
            saveCardSwitchContainerStackView.spacing = 8.0
            
            let saveCardSwitch = UISwitch()
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardSwitch)
            
            let saveCardLabel = UILabel()
            saveCardLabel.text = "Save this card"
            saveCardLabel.textColor = .black
            saveCardLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardLabel)
            
            verticalStackView.addArrangedSubview(saveCardSwitchContainerStackView)
            saveCardSwitchContainerStackView.isHidden = true
        }
        
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        var buttonTitle: String = ""
        if flow == .checkout {
            let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
            buttonTitle = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Pay",
                                            comment: "Pay - Card Form View (Sumbit button text)") + " " + (viewModel.amountStringed ?? "")
        } else if flow == .vault {
            buttonTitle = NSLocalizedString("primer-card-form-add-card",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Add card",
                                            comment: "Add card - Card Form (Vault title text)")
        }
        
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isEnabled = false
        submitButton.setTitle(buttonTitle, for: .normal)
        submitButton.setTitleColor(theme.colorTheme.text2, for: .normal)
        submitButton.backgroundColor = theme.colorTheme.disabled1
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        verticalStackView.addArrangedSubview(submitButton)
        
        
        
        cardComponentsManager = CardComponentsManager(
//            clientToken: state.accessToken,
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField)
        cardComponentsManager.delegate = self        
    }
    
    @objc func payButtonTapped(_ sender: UIButton) {
        cardComponentsManager.tokenize()
    }
    
}

extension PrimerCardFormViewController: CardComponentsManagerDelegate, PrimerTextFieldViewDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.flow == .vault {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
                
            } else {
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { [weak self] err in
                    DispatchQueue.main.async { [weak self] in
                        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                        
                        if settings.hasDisabledSuccessScreen {
                            Primer.shared.dismissPrimer()
                        } else {
                            if let err = err {
                                let evc = ErrorViewController(message: PrimerError.amountMissing.localizedDescription)
                                evc.view.translatesAutoresizingMaskIntoConstraints = false
                                evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                                Primer.shared.primerRootVC?.show(viewController: evc)
                            } else {
                                let svc = SuccessViewController()
                                svc.view.translatesAutoresizingMaskIntoConstraints = false
                                svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                                Primer.shared.primerRootVC?.show(viewController: svc)
                            }
                        }
                    }
                })
            }
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if let clientToken = state.accessToken {
            completion(clientToken, nil)
        } else {
            completion(nil, PrimerError.clientTokenNull)
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        submitButton.showSpinner(isLoading)
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = !isLoading
    }
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        if primerTextFieldView is PrimerCardNumberFieldView {
            cardNumberContainerView.errorText = nil
        } else if primerTextFieldView is PrimerExpiryDateFieldView {
            expiryDateContainerView.errorText = nil
        } else if primerTextFieldView is PrimerCVVFieldView {
            cvvContainerView.errorText = nil
        } else if primerTextFieldView is PrimerCardholderNameFieldView {
            cardholderNameContainerView.errorText = nil
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if primerTextFieldView is PrimerCardNumberFieldView, isValid == false {
            cardNumberContainerView.errorText = "Invalid card number"
            print("PrimerCardNumberFieldView.isValid: \(isValid)")
        } else if primerTextFieldView is PrimerExpiryDateFieldView, isValid == false {
            expiryDateContainerView.errorText = "Invalid date"
            print("PrimerExpiryDateFieldView.isValid: \(isValid)")
        } else if primerTextFieldView is PrimerCVVFieldView, isValid == false {
            cvvContainerView.errorText = "Invalid CVV"
            print("PrimerCVVFieldView.isValid: \(isValid)")
        } else if primerTextFieldView is PrimerCardholderNameFieldView, isValid == false {
            cardholderNameContainerView.errorText = "Invalid name"
            print("PrimerCardholderNameFieldView.isValid: \(isValid)")
        }

        if cardNumberField.isTextValid,
           expiryDateField.isTextValid,
           cvvField.isTextValid,
           cardholderNameField.isTextValid
        {
            submitButton.isEnabled = true
            submitButton.backgroundColor = .black
        } else {
            submitButton.isEnabled = false
            submitButton.backgroundColor = .lightGray
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {

    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {
        
    }
    
}

class PrimerCustomFieldView: UIView {

    var stackView: UIStackView = UIStackView()
    var placeholderText: String?
    var errorText: String? {
        didSet {
            errorLabel.text = errorText ?? ""
        }
    }
    var fieldView: PrimerTextFieldView!
    private let errorLabel = UILabel()

    func setup() {
        addSubview(stackView)
        stackView.alignment = .fill
        stackView.axis = .vertical

        let topPlaceholderLabel = UILabel()
        topPlaceholderLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        topPlaceholderLabel.text = placeholderText
        topPlaceholderLabel.textColor = PrimerColor(rgb: 0x007AFF)
        topPlaceholderLabel.textAlignment = .left
        stackView.addArrangedSubview(topPlaceholderLabel)

        let textFieldStackView = UIStackView()
        textFieldStackView.alignment = .fill
        textFieldStackView.axis = .vertical
        textFieldStackView.addArrangedSubview(fieldView)
        textFieldStackView.spacing = 0
        let bottomLine = UIView()
        bottomLine.backgroundColor = PrimerColor(rgb: 0x007AFF)
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(textFieldStackView)
        stackView.addArrangedSubview(bottomLine)

        
        errorLabel.textColor = .red
        errorLabel.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = nil
        errorLabel.textAlignment = .right
        
        stackView.addArrangedSubview(errorLabel)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }

}
