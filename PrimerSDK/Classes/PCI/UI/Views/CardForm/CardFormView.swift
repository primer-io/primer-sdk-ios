////
////  CardFormView.swift
////  PrimerScannerDemo
////
////  Created by Carl Eriksson on 29/11/2020.
////
//
//import UIKit
//
//protocol CardFormViewDelegate: class {
//    func cancel()
//    func showScanner()
//    func validateCardName(_ text: String?, updateTextField: Bool)
//    func validateCardNumber(_ text: String?, updateTextField: Bool)
//    func validateExpiry(_ text: String?, updateTextField: Bool)
//    func validateCVC(_ text: String?, updateTextField: Bool)
//}
//
//class CardFormView: UIView {
//    
//    @Dependency private(set) var theme: PrimerThemeProtocol
//    
//    var titleText: String { return uxMode == .CHECKOUT ? theme.content.cardFormView.checkoutTitleText : theme.content.cardFormView.vaultTitleText }
//    var submitButtonText: String { return uxMode == .CHECKOUT ? theme.content.cardFormView.checkoutSubmitButtonText : theme.content.cardFormView.vaultSubmitButtonText }
//    private let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
//    private let fieldHeight: CGFloat = 40.0
//    private let uxMode: UXMode
//    
//    let navBar = UINavigationBar()
//    let title = UILabel()
//    let submitButton = UIButton()
//    let scannerButton = UIButton()
//    let nameTF = UITextField()
//    let cardTF = UITextField()
//    let expTF = UITextField()
//    let cvcTF = UITextField()
//    
//    weak var delegate: CardFormViewDelegate?
//    
//    init(frame: CGRect, uxMode: UXMode, delegate: CardFormViewDelegate?) {
//        self.uxMode = uxMode
//        self.delegate = delegate
//        super.init(frame: frame)
//        
//        addSubview(navBar)
//        addSubview(submitButton)
//        addSubview(nameTF)
//        addSubview(cardTF)
//        addSubview(expTF)
//        addSubview(cvcTF)
//        addSubview(scannerButton)
//        
//        configureNavBar()
//        configureSubmitButton()
//        configureNameTF()
//        configureCardTF()
//        configureExpTF()
//        configureCvcTF()
//        configureScannerButton()
//        
//        anchorNavBar()
//        setSubmitButtonConstraints()
//        setNameTFConstraints()
//        setCardTFConstraints()
//        setExpTFConstraints()
//        setCvcTFConstraints()
//        
//        layoutIfNeeded()
//    }
//    
//    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//}
//
//// MARK: Configuration
//extension CardFormView {
//    private func configureNavBar() {
//        let navItem = UINavigationItem()
//        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
//        navItem.leftBarButtonItem = backItem
//        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        navBar.shadowImage = UIImage()
//        navBar.setItems([navItem], animated: false)
//        navBar.topItem?.title = theme.content.cardFormView.vaultTitleText
//    }
//    
//    @objc private func cancel() { delegate?.cancel() }
//    
//    private func configureSubmitButton() {
//        submitButton.layer.cornerRadius = 12
//        submitButton.setTitle(submitButtonText, for: .normal)
//        submitButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
//        let imageView = UIImageView(image: ImageName.lock.image)
//        submitButton.addSubview(imageView)
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor).isActive = true
//        imageView.trailingAnchor.constraint(equalTo: submitButton.trailingAnchor, constant: -16).isActive = true
//    }
//    
//    private func configureNameTF() {
//        nameTF.tag = 0
//        nameTF.placeholder = theme.content.cardFormView.nameTextFieldPlaceholder
//        nameTF.rightViewMode = .always
//        nameTF.textColor = theme.colorTheme.text1
//        nameTF.tintColor = theme.colorTheme.text1
//        nameTF.setLeftPaddingPoints(5)
//        nameTF.setRightPaddingPoints(5)
//        //
//        nameTF.addTarget(self, action: #selector(onNameTextFieldEditingDidEnd), for: .editingDidEnd)
//        nameTF.addTarget(self, action: #selector(onNameTextFieldDidChange), for: .editingChanged)
//        nameTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
////        nameTF.addBorder(
////            isFocused: false,
////            title: "",
////            cornerRadius: theme.cornerRadiusTheme.textFields,
////            textfieldTheme: theme.textFieldTheme,
////            color: theme.colorTheme.tint1,
////            backgroundColor: theme.colorTheme.main1,
////            theme: theme
////        )
//        nameTF.becomeFirstResponder()
//    }
//    
//    @objc private func onNameTextFieldDidChange(_ sender: UITextField) {
//        delegate?.validateCardName(sender.text, updateTextField: false)
//        sender.textColor = theme.colorTheme.text1
//    }
//    
//    @objc private func onNameTextFieldEditingDidEnd(_ sender: UITextField) {
//        delegate?.validateCardName(sender.text, updateTextField: true)
//    }
//    
//    private func configureCardTF() {
//        cardTF.tag = 1
//        cardTF.placeholder = theme.content.cardFormView.cardTextFieldPlaceholder
//        cardTF.rightViewMode = .always
//        cardTF.textColor = theme.colorTheme.text1
//        cardTF.tintColor = theme.colorTheme.text1
//        cardTF.setLeftPaddingPoints(5)
//        cardTF.setRightPaddingPoints(5)
//        cardTF.keyboardType = UIKeyboardType.numberPad
//        cardTF.addTarget(self, action: #selector(onCardTextFieldEditingDidEnd), for: .editingDidEnd)
//        cardTF.addTarget(self, action: #selector(onCardTextFieldDidChange), for: .editingChanged)
//        cardTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
//        cardTF.addBorder(
//            isFocused: false,
//            title: "",
//            cornerRadius: theme.cornerRadiusTheme.textFields,
//            textfieldTheme: theme.textFieldTheme,
//            color: theme.colorTheme.tint1,
//            backgroundColor: theme.colorTheme.main1,
//            theme: theme
//        )
//    }
//    
//    
//    @objc private func onTextFieldEditingDidBegin(_ sender: UITextField) {
//        
//        var title = ""
//        
//        switch sender.tag {
//        case 0: title = "Cardholder name"
//        case 1: title = "Card number"
//        case 2: title = "Expiry date"
//        case 3: title = "CVC"
//        default: break
//        }
//        
//        sender.addBorder(
//            isFocused: true,
//            title: title,
//            cornerRadius: theme.cornerRadiusTheme.textFields,
//            textfieldTheme: theme.textFieldTheme,
//            color: theme.colorTheme.tint1,
//            backgroundColor: theme.colorTheme.main1,
//            theme: theme
//        )
//        sender.layoutIfNeeded()
//    }
//    
//    @objc private func onCardTextFieldDidChange(_ sender: UITextField) {
//        delegate?.validateCardNumber(sender.text, updateTextField: false)
//        sender.textColor = theme.colorTheme.text1
//    }
//    
//    @objc private func onCardTextFieldEditingDidEnd(_ sender: UITextField) {
//        delegate?.validateCardNumber(sender.text, updateTextField: true)
//    }
//    
//    private func configureExpTF() {
//        expTF.tag = 2
//        expTF.placeholder = theme.content.cardFormView.expiryTextFieldPlaceholder
//        expTF.rightViewMode = .always
//        expTF.textColor = theme.colorTheme.text1
//        expTF.tintColor = theme.colorTheme.text1
//        expTF.setLeftPaddingPoints(5)
//        expTF.setRightPaddingPoints(5)
//        expTF.keyboardType = UIKeyboardType.numberPad
//        expTF.addTarget(self, action: #selector(onExpiryTextFieldEditingDidEnd), for: .editingDidEnd)
//        expTF.addTarget(self, action: #selector(onExpiryTextFieldDidChange), for: .editingChanged)
//        expTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
////        expTF.addBorder(
////            isFocused: false,
////            title: "",
////            cornerRadius: theme.cornerRadiusTheme.textFields,
////            textfieldTheme: theme.textFieldTheme,
////            color: theme.colorTheme.tint1,
////            backgroundColor: theme.colorTheme.main1,
////            theme: theme
////        )
//    }
//    
//    @objc private func onExpiryTextFieldDidChange(_ sender: UITextField) {
//        delegate?.validateExpiry(sender.text, updateTextField: false)
//        sender.textColor = theme.colorTheme.text1
//    }
//    
//    @objc private func onExpiryTextFieldEditingDidEnd(_ sender: UITextField) {
//        delegate?.validateExpiry(sender.text, updateTextField: true)
//    }
//    
//    private func configureCvcTF() {
//        cvcTF.tag = 3
//        cvcTF.placeholder = theme.content.cardFormView.cvcTextFieldPlaceholder
//        cvcTF.rightViewMode = .always
//        expTF.textColor = theme.colorTheme.text1
//        expTF.tintColor = theme.colorTheme.text1
//        cvcTF.setLeftPaddingPoints(5)
//        cvcTF.setRightPaddingPoints(5)
//        cvcTF.keyboardType = UIKeyboardType.numberPad
//        cvcTF.addTarget(self, action: #selector(onCVCTextFieldEditingDidEnd), for: .editingDidEnd)
//        cvcTF.addTarget(self, action: #selector(onCVCTextFieldDidChange), for: .editingChanged)
//        cvcTF.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
//        cvcTF.addBorder(
//            isFocused: false,
//            title: "",
//            cornerRadius: theme.cornerRadiusTheme.textFields,
//            textfieldTheme: theme.textFieldTheme,
//            color: theme.colorTheme.tint1,
//            backgroundColor: theme.colorTheme.main1,
//            theme: theme
//        )
//    }
//    
//    @objc private func onCVCTextFieldDidChange(_ sender: UITextField) {
//        delegate?.validateCVC(sender.text, updateTextField: false)
//        sender.textColor = theme.colorTheme.text1
//    }
//    
//    @objc private func onCVCTextFieldEditingDidEnd(_ sender: UITextField) {
//        delegate?.validateCVC(sender.text, updateTextField: true)
//    }
//    
//    private func configureScannerButton() {
//        scannerButton.setTitle("Scan card", for: .normal)
//        scannerButton.setTitleColor(theme.colorTheme.text3, for: .normal)
//        scannerButton.titleLabel?.font = .systemFont(ofSize: 15)
//        
//        scannerButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)
//        
//        scannerButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        scannerButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 12).isActive = true
//        scannerButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 12).isActive = true
//        
//        let iconView = UIImageView(image: ImageName.camera.image)
//        scannerButton.addSubview(iconView)
//        iconView.translatesAutoresizingMaskIntoConstraints = false
//        iconView.trailingAnchor.constraint(equalTo: scannerButton.leadingAnchor, constant: -8).isActive = true
//        iconView.centerYAnchor.constraint(equalTo: scannerButton.centerYAnchor).isActive = true
//        
//        if #available(iOS 11.0, *) {
//            iconView.heightAnchor.constraint(equalToConstant: iconView.intrinsicContentSize.height * 0.75).isActive = true
//        } else {
//            iconView.heightAnchor.constraint(equalToConstant: 0).isActive = true
//        }
//        
//        iconView.widthAnchor.constraint(equalToConstant: iconView.intrinsicContentSize.width * 0.75).isActive = true
//    }
//    
//    @objc private func showScanner() { delegate?.showScanner() }
//}
//
//// MARK: Anchoring
//
//extension CardFormView {
//    private func anchorNavBar() {
//        navBar.translatesAutoresizingMaskIntoConstraints = false
//        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
//        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
//    }
//    private func setNameTFConstraints() {
//        nameTF.translatesAutoresizingMaskIntoConstraints = false
//        nameTF.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 24).isActive = true
//        nameTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
//        nameTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
//        nameTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
//    }
//    private func setCardTFConstraints() {
//        cardTF.translatesAutoresizingMaskIntoConstraints = false
//        cardTF.topAnchor.constraint(equalTo: nameTF.bottomAnchor, constant: 12).isActive = true
//        cardTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
//        cardTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
//        cardTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
//    }
//    private func setExpTFConstraints() {
//        expTF.translatesAutoresizingMaskIntoConstraints = false
//        expTF.topAnchor.constraint(equalTo: cardTF.bottomAnchor, constant: 12).isActive = true
//        expTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
//        expTF.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -6).isActive = true
//        expTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
//    }
//    private func setCvcTFConstraints() {
//        cvcTF.translatesAutoresizingMaskIntoConstraints = false
//        cvcTF.topAnchor.constraint(equalTo: cardTF.bottomAnchor, constant: 12).isActive = true
//        cvcTF.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 6).isActive = true
//        cvcTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
//        cvcTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
//    }
//    private func setSubmitButtonConstraints() {
//        submitButton.translatesAutoresizingMaskIntoConstraints = false
//        submitButton.topAnchor.constraint(equalTo: expTF.bottomAnchor, constant: 24).isActive = true
//        submitButton.heightAnchor.constraint(equalToConstant: fieldHeight + 12).isActive = true
//        submitButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
//        submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
//        submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
//    }
//}
