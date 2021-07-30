//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit

class PrimerFormViewController: UIViewController {

    internal var verticalStackView: UIStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(verticalStackView)
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
        
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        } else {
            verticalStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        }
        if #available(iOS 11.0, *) {
            verticalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20).isActive = true
        } else {
            verticalStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        }
        verticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        
    }
    
}

class PrimerCustomFieldView: UIView {

    private var stackView: UIStackView = UIStackView()
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
        topPlaceholderLabel.textAlignment = .left
        stackView.addArrangedSubview(topPlaceholderLabel)

        let textFieldStackView = UIStackView()
        textFieldStackView.alignment = .leading
        textFieldStackView.axis = .vertical
        textFieldStackView.addArrangedSubview(fieldView)
        textFieldStackView.spacing = 0
        let bottomLine = UIView()
        bottomLine.backgroundColor = .blue
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(textFieldStackView)
        stackView.addArrangedSubview(bottomLine)

        
        errorLabel.textColor = .red
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = ""
        errorLabel.textAlignment = .right
        
        stackView.addArrangedSubview(errorLabel)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }

}

class PrimerCardFormViewController: PrimerFormViewController {
    
    private var cardComponentsManager: CardComponentsManager!
    private var flow: PaymentFlow!
    
    private let cardNumberContainerView = PrimerCustomFieldView()
    private let expiryDateContainerView = PrimerCustomFieldView()
    private let cvvContainerView = PrimerCustomFieldView()
    private let cardholderNameContainerView = PrimerCustomFieldView()
    
    init(flow: PaymentFlow) {
        self.flow = flow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Enter your card details"
        
        view.backgroundColor = .white
        
        verticalStackView.spacing = 8
//        view.layoutIfNeeded()
        
//        let titleLabel = UILabel()
//        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
//        titleLabel.text = "Checkout"
//        titleLabel.textAlignment = .center
//        verticalStackView.addArrangedSubview(titleLabel)
        
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 40).isActive = true
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
        
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        expiryDateField.delegate = self
        
        expiryDateContainerView.fieldView = expiryDateField
        expiryDateContainerView.placeholderText = "Expiry"
        expiryDateContainerView.setup()
        horizontalStackView.addArrangedSubview(expiryDateContainerView)
        
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cvvField.delegate = self
        
        cvvContainerView.fieldView = cvvField
        cvvContainerView.placeholderText = "CVV/CVC"
        cvvContainerView.setup()
        horizontalStackView.addArrangedSubview(cvvContainerView)
        horizontalStackView.spacing = 8
        verticalStackView.addArrangedSubview(horizontalStackView)
        
        let cardholderNameField = PrimerCardholderNameFieldView()
        cardholderNameField.placeholder = "John Smith"
        cardholderNameField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cardholderNameField.delegate = self
        
        cardholderNameContainerView.fieldView = cardholderNameField
        cardholderNameContainerView.placeholderText = "Name"
        cardholderNameContainerView.setup()
        verticalStackView.addArrangedSubview(cardholderNameContainerView)
        
        let button = UIButton()
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.setTitle("Pay", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.backgroundColor = .black
        button.roundCorners(.allCorners, radius: 8)
        button.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        verticalStackView.addArrangedSubview(button)
        
        let testView = UIView()
        testView.heightAnchor.constraint(equalToConstant: 2000).isActive = true
        verticalStackView.addArrangedSubview(testView)
        
        cardComponentsManager = CardComponentsManager(
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
        
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        print(errors)
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        print("isLoading: \(isLoading)")
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {
        if primerTextFieldView is PrimerCardNumberFieldView {
            cardNumberContainerView.errorText = "Invalid card number"
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {
        
    }
    
}
