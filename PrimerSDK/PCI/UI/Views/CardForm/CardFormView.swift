//
//  CardFormView.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 29/11/2020.
//

import UIKit

protocol CardFormViewDelegate: class {
    func cancel()
    func showScanner()
    func validateCardName(_ text: String?)
    func validateCardNumber(_ text: String?)
    func validateExpiry(_ text: String?)
    func validateCVC(_ text: String?)
}

class CardFormView: UIView {
    var titleText: String { return uxMode == .CHECKOUT ? theme.content.cardFormView.checkoutTitleText : theme.content.cardFormView.vaultTitleText }
    var submitButtonText: String { return uxMode == .CHECKOUT ? theme.content.cardFormView.checkoutSubmitButtonText : theme.content.cardFormView.vaultSubmitButtonText }
    private let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    private let borderColor = UIColor(red: 225/255, green: 222/255, blue: 218/255, alpha: 1).cgColor
    private let fieldHeight: CGFloat = 40.0
    private let theme: PrimerTheme
    private let uxMode: UXMode
    
    let navBar = UINavigationBar()
    let title = UILabel()
    let submitButton = UIButton()
    let scannerButton = UIButton()
    let nameTF = UITextField()
    let cardTF = UITextField()
    let expTF = UITextField()
    let cvcTF = UITextField()
    
    weak var delegate: CardFormViewDelegate?
    
    init(frame: CGRect, theme: PrimerTheme, uxMode: UXMode, delegate: CardFormViewDelegate?) {
        self.theme = theme
        self.uxMode = uxMode
        self.delegate = delegate
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(submitButton)
        addSubview(nameTF)
        addSubview(cardTF)
        addSubview(expTF)
        addSubview(cvcTF)
        
        configureNavBar()
        configureSubmitButton()
        configureNameTF()
        configureCardTF()
        configureExpTF()
        configureCvcTF()
        
        anchorNavBar()
        setSubmitButtonConstraints()
        setNameTFConstraints()
        setCardTFConstraints()
        setExpTFConstraints()
        setCvcTFConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: Configuration
extension CardFormView {
    private func configureNavBar() {
        navBar.backgroundColor = theme.backgroundColor
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        let editItem = UIBarButtonItem()
        editItem.title = theme.content.cardFormView.scannerButtonText
        editItem.action = #selector(showScanner)
        navItem.leftBarButtonItem = backItem
        navItem.rightBarButtonItem = editItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = theme.content.cardFormView.vaultTitleText
    }
    @objc private func cancel() { delegate?.cancel() }
    @objc private func showScanner() { delegate?.showScanner() }
    private func configureSubmitButton() {
        submitButton.layer.cornerRadius = theme.cornerRadiusTheme.buttons
        submitButton.setTitle(submitButtonText, for: .normal)
        submitButton.setTitleColor(theme.fontColorTheme.payButton, for: .normal)
    }
    private func configureNameTF() {
        nameTF.tag = 0
        nameTF.placeholder = theme.content.cardFormView.nameTextFieldPlaceholder
        nameTF.rightViewMode = .always
        nameTF.textColor = .darkGray
        nameTF.tintColor = .black
        nameTF.backgroundColor = .white
        nameTF.setLeftPaddingPoints(5)
        nameTF.setRightPaddingPoints(5)
        //
        nameTF.addTarget(self, action: #selector(onNameTextFieldEditingDidEnd), for: .editingDidEnd)
        nameTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
        nameTF.addBorder(isFocused: false, title: "", cornerRadius: theme.cornerRadiusTheme.textFields, theme: theme.textFieldTheme)
    }
    @objc private func onNameTextFieldEditingDidEnd(_ sender: UITextField) {
        delegate?.validateCardName(sender.text)
    }
    private func configureCardTF() {
        cardTF.tag = 1
        cardTF.placeholder = theme.content.cardFormView.cardTextFieldPlaceholder
        cardTF.rightViewMode = .always
        cardTF.textColor = .darkGray
        cardTF.tintColor = .black
        cardTF.setLeftPaddingPoints(5)
        cardTF.setRightPaddingPoints(5)
        cardTF.keyboardType = UIKeyboardType.numberPad
        cardTF.addTarget(self, action: #selector(onCardTextFieldEditingDidEnd), for: .editingDidEnd)
        cardTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
        cardTF.addBorder(isFocused: false, title: "", cornerRadius: theme.cornerRadiusTheme.textFields, theme: theme.textFieldTheme)
    }
    
    @objc private func onTextFieldEditingDidBegin(_ sender: UITextField) {
        
        var title = ""
        
        switch sender.tag {
        case 0: title = "Cardholder name"
        case 1: title = "Card number"
        case 2: title = "Expiry date"
        case 3: title = "CVC"
        default: break
        }
        
        sender.addBorder(isFocused: true, title: title, cornerRadius: theme.cornerRadiusTheme.textFields, theme: theme.textFieldTheme)
        sender.layoutIfNeeded()
    }
    
    @objc private func onCardTextFieldEditingDidEnd(_ sender: UITextField) {
        delegate?.validateCardNumber(sender.text)
    }
    
    private func configureExpTF() {
        expTF.tag = 2
        expTF.placeholder = theme.content.cardFormView.expiryTextFieldPlaceholder
        expTF.rightViewMode = .always
        expTF.textColor = .darkGray
        expTF.tintColor = .black
        expTF.setLeftPaddingPoints(5)
        expTF.setRightPaddingPoints(5)
        expTF.keyboardType = UIKeyboardType.numberPad
        expTF.addTarget(self, action: #selector(onExpiryTextFieldEditingDidEnd), for: .editingDidEnd)
        expTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
        expTF.addBorder(isFocused: false, title: "", cornerRadius: theme.cornerRadiusTheme.textFields, theme: theme.textFieldTheme)
    }
    @objc private func onExpiryTextFieldEditingDidEnd(_ sender: UITextField) {
        delegate?.validateExpiry(sender.text)
    }
    private func configureCvcTF() {
        cvcTF.tag = 3
        cvcTF.placeholder = theme.content.cardFormView.cvcTextFieldPlaceholder
        cvcTF.rightViewMode = .always
        cvcTF.textColor = .darkGray
        cvcTF.tintColor = .black
        cvcTF.backgroundColor = .white
        cvcTF.setLeftPaddingPoints(5)
        cvcTF.setRightPaddingPoints(5)
        cvcTF.keyboardType = UIKeyboardType.numberPad
        cvcTF.addTarget(self, action: #selector(onCVCTextFieldEditingDidEnd), for: .editingDidEnd)
        cvcTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
        cvcTF.addBorder(isFocused: false, title: "", cornerRadius: theme.cornerRadiusTheme.textFields, theme: theme.textFieldTheme)
    }
    @objc private func onCVCTextFieldEditingDidEnd(_ sender: UITextField) {
        delegate?.validateCVC(sender.text)
    }
}

// MARK: Anchoring

extension CardFormView {
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    private func setNameTFConstraints() {
        nameTF.translatesAutoresizingMaskIntoConstraints = false
        nameTF.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 24).isActive = true
        nameTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        nameTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        nameTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    private func setCardTFConstraints() {
        cardTF.translatesAutoresizingMaskIntoConstraints = false
        cardTF.topAnchor.constraint(equalTo: nameTF.bottomAnchor, constant: 12).isActive = true
        cardTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        cardTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        cardTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    private func setExpTFConstraints() {
        expTF.translatesAutoresizingMaskIntoConstraints = false
        expTF.topAnchor.constraint(equalTo: cardTF.bottomAnchor, constant: 12).isActive = true
        expTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        expTF.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -6).isActive = true
        expTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    private func setCvcTFConstraints() {
        cvcTF.translatesAutoresizingMaskIntoConstraints = false
        cvcTF.topAnchor.constraint(equalTo: cardTF.bottomAnchor, constant: 12).isActive = true
        cvcTF.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 6).isActive = true
        cvcTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        cvcTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    private func setSubmitButtonConstraints() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: expTF.bottomAnchor, constant: 24).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: fieldHeight + 12).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    }
}
