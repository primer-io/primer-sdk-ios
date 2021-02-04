//
//  BankAccountFormView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

import UIKit

protocol FormViewDelegate: class, UITextFieldDelegate {
    var formType: FormType { get }
    var validatedFields: [Bool] { get set }
    func back()
    func openLink()
    func submit(_ value: String?, type: FormTextFieldType)
    func onSubmit()
}

class FormView: UIView {
    let navBar = UINavigationBar()
    let title = UILabel()
    let link = UILabel()
    let button = UIButton()
    var textFields: [UITextField] = []
    
    let countries = CountryCode.all
    
    var countryPickerView = UIPickerView()
    
    weak var delegate: FormViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(title)
        addSubview(link)
        addSubview(button)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { print("🧨 destroy:", self.self) }
    
    func render() {
        if (textFields.isEmpty) {
            guard let models = delegate?.formType.textFields else { return }
            for (i, model) in models.enumerated() {
                configureTextField(model, index: i)
            }
        }
        
        configureNavbar()
        configureTitle()
        configureButton()
        validateForm()
        
        anchorNavbar()
        anchorTitle()
        anchorLink()
        anchorButton()
    }
}

// MARK: Picker
extension FormView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return countries[row].country
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textFields[pickerView.tag].text = countries[row].rawValue
        textFields[pickerView.tag].resignFirstResponder()
    }
}

// MARK: Configuration
extension FormView {
    private func configureNavbar() {
        guard let delegate = delegate else { return }
        
        // set background color
        navBar.backgroundColor = Primer.theme.colorTheme.main1
        
        // define navigation item
        let navItem = UINavigationItem()
        
        // set back button item
        let backItem = UIBarButtonItem()
        backItem.action = #selector(back)
        let backBtnImage = ImageName.back.image
        backItem.tintColor = Primer.theme.colorTheme.text1
        backItem.image = backBtnImage
        navItem.leftBarButtonItem = backItem
        
        // remove default shadow
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        
        // attach items to navbar
        navBar.setItems([navItem], animated: false)
        
        // add top title if theme toggled true
        if (Primer.theme.layout.showTopTitle) {
            navBar.topItem?.title = delegate.formType.topTitle
        }
    }
    
    @objc private func back() {
        delegate?.back()
    }
    
    private func configureTitle() {
        guard let delegate = delegate else { return }
        if (Primer.theme.layout.showMainTitle) {
            title.text = delegate.formType.mainTitle
        }
        title.textAlignment = .center
        title.font = Primer.theme.fontTheme.mainTitle
    }
    
    // Textfield
    private func configureTextField(_ model: FormTextFieldType, index: Int) {
        guard let delegate = delegate else { return }
        let textField = UITextField()
        textFields.append(textField)
        addSubview(textField)
        textField.tag = index
        
        if (index == 0) {
            textField.becomeFirstResponder()
        }
        
        switch delegate.formType.textFields[index] {
        case .country:
            textField.inputView = countryPickerView
            countryPickerView.tag = textField.tag
            countryPickerView.delegate = self
            countryPickerView.dataSource = self
        default: break
        }
        
        textField.text = delegate.formType.textFields[index].initialValue
        textField.autocapitalizationType = .none
        
        if (Primer.theme.textFieldTheme == .doublelined) {
            let leftView = UILabel()
            leftView.text =  delegate.formType.textFields[index].title + "   "
            leftView.font = .boldSystemFont(ofSize: 17)
            leftView.textColor = Primer.theme.colorTheme.text1
            textField.leftView = leftView
        } else {
            let padding: CGFloat = 5
            textField.setLeftPaddingPoints(padding)
        }
        
        textField.leftViewMode = .always
        textField.placeholder = delegate.formType.textFields[index].placeHolder
        
        textField.addTarget(self, action: #selector(onTextFieldEditingDidEnd), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(onTextFieldEditingChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(onTextFieldEditingDidBegin), for: .editingDidBegin)
        
        textField.addBorder(
            isFocused: false,
            title: "",
            cornerRadius: 4,
            theme: Primer.theme.textFieldTheme,
            color: Primer.theme.colorTheme.text3,
            backgroundColor: Primer.theme.colorTheme.main1
        )
        
        textField.delegate = delegate
        anchorTextField(textField)
    }
    
    @objc private func onTextFieldEditingDidBegin(_ sender: UITextField) {
        guard let delegate = delegate else { return }
        let title = delegate.formType.textFields[sender.tag].title
        
        sender.addBorder(
            isFocused: true,
            title: title,
            cornerRadius: 4,
            theme: Primer.theme.textFieldTheme,
            color: Primer.theme.textFieldTheme == .doublelined ? Primer.theme.colorTheme.disabled1 : Primer.theme.colorTheme.text3,
            backgroundColor: Primer.theme.colorTheme.main1
        )
        
        sender.layoutIfNeeded()
    }
    
    @objc private func onTextFieldEditingDidEnd(_ sender: UITextField) {
        validateTextField(sender)
        validateForm()
    }
    
    @objc private func onTextFieldEditingChanged(_ sender: UITextField) {
        guard let delegate = delegate else { return }
        guard let text = sender.text?.withoutWhiteSpace else { return }
        let mask = delegate.formType.textFields[sender.tag].mask
        
        if (mask.exists) {
            sender.text = mask?.apply(on: text.uppercased())
        }
        
        sender.textColor = Primer.theme.colorTheme.text1
        
        let validation = delegate.formType.textFields[sender.tag].validate(text)
        
        delegate.validatedFields[sender.tag] = validation.0
        
        validateForm()
    }
    
    private func validateTextField(_ sender: UITextField) {
        guard let delegate = delegate else { return }
        guard let text = sender.text?.withoutWhiteSpace else { return }
        
        let validation = delegate.formType.textFields[sender.tag].validate(text)
        
        delegate.validatedFields[sender.tag] = validation.0
        
        sender.toggleValidity(
            delegate.validatedFields[sender.tag],
            theme: Primer.theme.textFieldTheme,
            errorMessage: validation.1,
            hideValidTheme: validation.2
        )
        guard let mask = delegate.formType.textFields[sender.tag].mask else { return }
        sender.text = mask.apply(on: text.uppercased())
    }
    
    private func validateForm() {
        let isAllValid = delegate?.validatedFields.allSatisfy({ $0 == true }) ?? false
        button.toggleValidity(isAllValid, validColor: Primer.theme.colorTheme.tint1)
    }
    
    private func configureLink() {
        guard let delegate = delegate else { return }
        link.text = delegate.formType.subtitle
        link.font = .systemFont(ofSize: 15)
        link.textColor = Primer.theme.colorTheme.tint1
        link.textAlignment = .center
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(onLinkTap))
        link.isUserInteractionEnabled = true
        link.addGestureRecognizer(tapRecogniser)
    }
    
    @objc private func onLinkTap(_ sender: UITapGestureRecognizer?) {
        delegate?.openLink()
    }
    
    private func configureButton() {
        button.setTitle("Next".localized(), for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.zPosition = 10
    }
    
    @objc private func onButtonPressed(_ button: UIButton) {
        textFields.forEach {
            guard let type = delegate?.formType.textFields[$0.tag] else { return }
            delegate?.submit($0.text, type: type)
        }
        delegate?.onSubmit()
    }
}

// MARK: Anchoring
extension FormView {
    func anchorNavbar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    func anchorTitle() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        title.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
    }
    
    func anchorTextField(_ textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let topAnchor = textField.tag == 0 ?
            textField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24) :
            textField.topAnchor.constraint(equalTo: textFields[textField.tag - 1].bottomAnchor, constant: 12)
        
        topAnchor.isActive = true
        textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
    }
    
    func anchorLink() {
        link.translatesAutoresizingMaskIntoConstraints = false
        link.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        link.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        guard let textField = textFields.last else { return }
        link.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24).isActive = true
    }
    
    func anchorButton() {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true
    }
}

extension String {
    var isValidAccountNumber: Bool {
        print(!self.isEmpty)
        return !self.isEmpty
    }
}
