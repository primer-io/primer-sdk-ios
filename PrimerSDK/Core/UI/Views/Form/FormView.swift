//
//  BankAccountFormView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

import UIKit

protocol FormViewDelegate: class, UITextFieldDelegate {
    var formType: FormType { get }
    var submitButtonTitle: String { get }
    func back()
    func openLink()
    func submit(_ value: String?, type: FormTextFieldType)
    func onSubmit()
    func onBottomLinkTapped()
}

class FormView: UIView {
    
    @Dependency private(set) var theme: PrimerThemeProtocol
    
    let navBar = UINavigationBar()
    let title = UILabel()
    let link = UILabel()
    let button = UIButton()
    let scannerButton = UIButton()
    let contentView = UIScrollView()
    
    var textFields: [[UITextField]] = []
    var validatedFields: [[Bool]] = []
    
    let countries = CountryCode.all
    
    var countryPickerView = UIPickerView()
    
    weak var delegate: FormViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(link)
        addSubview(button)
        addSubview(scannerButton)
        addSubview(contentView)
        contentView.addSubview(title)
        
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    func render() {
        if (textFields.isEmpty) {
            guard let models = delegate?.formType.textFields else { return }
            
            var i: Int = 0
            
            for (row, columns) in models.enumerated() {
                textFields.append([])
                validatedFields.append([])
                
                for (column, model) in columns.enumerated() {
                    i = configureTextField(model, column: column, row: row, index: i)
                }
                
            }
            
            textFields.forEach { row in
                row.forEach { textField in
                    anchorTextField(textField)
                    validateTextField(textField, markError: false, showValidity: false)
                }
            }
            
            validateForm()
            
        }
        
        configureNavbar()
        configureTitle()
        configureButton()
        
//        anchorNavbar()
        anchorTitle()
        anchorLink()
        anchorButton()
        
        anchorContentView()
        
        if let formType = delegate?.formType {
            switch formType {
            case .cardForm: configureScannerButton()
            default: break
            }
        }
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
        let textFieldColumn: Int = pickerView.tag % 10
        let textFieldRow: Int = (pickerView.tag - textFieldColumn) / 10
        textFields[textFieldRow][textFieldColumn].text = countries[row].rawValue
        textFields[textFieldRow][textFieldColumn].resignFirstResponder()
    }
}

// MARK: Configuration
extension FormView {
    private func configureNavbar() {
        guard let delegate = delegate else { return }
        
        // set background color
        navBar.backgroundColor = theme.colorTheme.main1
        
        // define navigation item
        let navItem = UINavigationItem()
        
        // set back button item
        let backItem = UIBarButtonItem()
        backItem.action = #selector(back)
        let backBtnImage = ImageName.back.image
        backItem.tintColor = theme.colorTheme.tint1
        backItem.image = backBtnImage
        navItem.leftBarButtonItem = backItem
        
        // remove default shadow
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        
        // attach items to navbar
        navBar.setItems([navItem], animated: false)
        
        // add top title if theme toggled true
        if (theme.layout.showTopTitle) {
            navBar.topItem?.title = delegate.formType.topTitle
        }
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        } else {
            navBar.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        }
        
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    @objc private func back() {
        delegate?.back()
    }
    
    private func configureTitle() {
        guard let delegate = delegate else { return }
        if (theme.layout.showMainTitle) {
            title.text = delegate.formType.mainTitle
        }
        title.textAlignment = .center
        title.font = theme.fontTheme.mainTitle
    }
    
    // Textfield
    private func configureTextField(_ model: FormTextFieldType, column: Int, row: Int, index: Int) -> Int {
        guard let delegate = delegate else { return 0 }
        let textField = PrimerTextField()
        textFields[row].append(textField)
        
        switch model {
        case .addressLine2:
            textField.validationIsOptional = true
        default:
            break
        }
        
        validatedFields[row].append(textField.validationIsOptional ? true : false)
        
        
        contentView.addSubview(textField)
        let val = (row * 10) + column
        textField.tag = val
        
        textField.keyboardType = model.keyboardType
        
        // accessbility identifier
        
        switch model {
        case .cardholderName: textField.accessibilityIdentifier = "nameField"
        case .cardNumber: textField.accessibilityIdentifier = "cardField"
        case .expiryDate: textField.accessibilityIdentifier = "expiryField"
        case .cvc: textField.accessibilityIdentifier = "cvcField"
        case .addressLine1: textField.accessibilityIdentifier = "addressLine1Field"
        case .addressLine2: textField.accessibilityIdentifier = "addressLine2Field"
        case .firstName: textField.accessibilityIdentifier = "firstNameField"
        case .lastName: textField.accessibilityIdentifier = "lastNameField"
        case .city: textField.accessibilityIdentifier = "cityField"
        case .country: textField.accessibilityIdentifier = "countryField"
        case .postalCode: textField.accessibilityIdentifier = "postalCodeField"
        case .email: textField.accessibilityIdentifier = "emailField"
        case .iban: textField.accessibilityIdentifier = "ibanField"
        default:
            break
        }
        
        if (val == 0) {
            textField.becomeFirstResponder()
        }
        
        switch delegate.formType.textFields[row][column] {
        case .country:
            textField.inputView = countryPickerView
            countryPickerView.tag = textField.tag
            countryPickerView.delegate = self
            countryPickerView.dataSource = self
        default: break
        }
        
        textField.text = delegate.formType.textFields[row][column].initialValue
        textField.autocapitalizationType = .none
        
        textField.label.text = delegate.formType.textFields[row][column].title
        
        textField.leftViewMode = .always
        textField.placeholder = delegate.formType.textFields[row][column].placeHolder
        
        textField.addTarget(self, action: #selector(onTextFieldEditingChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(onTextFieldEditingDidEnd), for: .editingDidEnd)
        
        textField.delegate = delegate
        return index + 1
    }
    
    @objc private func onTextFieldEditingDidEnd(_ sender: UITextField) {
        validateTextField(sender)
        validateForm()
    }
    
    @objc private func onTextFieldEditingChanged(_ sender: UITextField) {
        guard let delegate = delegate else { return }
        guard let text = sender.text?.withoutWhiteSpace else { return }
        let column: Int = sender.tag % 10
        let row: Int = (sender.tag - column) / 10
        let mask = delegate.formType.textFields[row][column].mask
        
        if (mask.exists) {
            sender.text = mask?.apply(on: text.uppercased())
        }
        
        validateTextField(sender, markError: false)
        validateForm()
    }
    
    private func validateTextField(_ sender: UITextField, markError: Bool = true, showValidity: Bool = true) {
        guard let delegate = delegate else { return }
        guard let textField = sender as? PrimerTextField else { return }
        
        if textField.validationIsOptional {
            textField.renderSubViews(validationState: .default)
            return
        }
        
        guard let text = textField.text?.withoutWhiteSpace else { return }
        
        let column: Int = textField.tag % 10
        let row: Int = (textField.tag - column) / 10
        
        if (delegate.formType.textFields.count > row) {
            let validation = delegate.formType.textFields[row][column].validate(text)
            validatedFields[row][column] = validation.0
            
            let mask = delegate.formType.textFields[row][column].mask
            sender.text = mask?.apply(on: text.uppercased()) ?? sender.text
            
            if (validation.0) {
                textField.renderSubViews(validationState: showValidity ? .valid : .default)
            } else {
                textField.renderSubViews(validationState: markError ? .invalid : .default)
                textField.errorMessage.text = markError ? validation.1 : ""
            }
        }
    }
    
    private func validateForm() {
        let isAllValid = validatedFields.allSatisfy({ row in return row.allSatisfy { return $0 == true } })
        button.toggleValidity(isAllValid, validColor: theme.colorTheme.tint1, defaultColor: theme.colorTheme.disabled1)
    }
    
    private func configureLink() {
        guard let delegate = delegate else { return }
        link.text = delegate.formType.subtitle
        link.font = .systemFont(ofSize: 15)
        link.textColor = theme.colorTheme.tint1
        link.textAlignment = .center
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(onLinkTap))
        link.isUserInteractionEnabled = true
        link.addGestureRecognizer(tapRecogniser)
    }
    
    @objc private func onLinkTap(_ sender: UITapGestureRecognizer?) {
        delegate?.openLink()
    }
    
    private func configureButton() {
        button.setTitle(delegate?.submitButtonTitle, for: .normal)
        button.layer.cornerRadius = theme.cornerRadiusTheme.buttons
        button.accessibilityIdentifier = "submitButton"
        button.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.zPosition = 10
        
        guard let delegate = delegate else { return }
        switch delegate.formType {
        case .cardForm:
            let imageView = UIImageView(image: ImageName.lock.image)
            button.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
            imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16).isActive = true
        default:
            break
        }
    }
    
    @objc private func onButtonPressed(_ button: UIButton) {
        textFields.forEach { row in
            row.forEach {
                guard let textField = $0 as? PrimerTextField else { return }
                let column: Int = textField.tag % 10
                let row: Int = (textField.tag - column) / 10
                guard let type = delegate?.formType.textFields[row][column] else { return }
                delegate?.submit(textField.text, type: type)
            }
        }
        guard let delegate = delegate else { return }
        switch delegate.formType {
        case .cardForm:
            button.setBusy(theme: theme)
        default:
            break
        }
        delegate.onSubmit()
    }
    
    private func configureScannerButton() {
        scannerButton.setTitle("Scan card", for: .normal)
        scannerButton.setTitleColor(theme.colorTheme.text3, for: .normal)
        scannerButton.titleLabel?.font = .systemFont(ofSize: 15)
        
        scannerButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)
        
        scannerButton.translatesAutoresizingMaskIntoConstraints = false
        
        scannerButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 12).isActive = true
        scannerButton.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 12).isActive = true
        
        let iconView = UIImageView()
        
        let tintedIcon = ImageName.camera.image?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = theme.colorTheme.tint1
        iconView.image = tintedIcon
        
        scannerButton.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.trailingAnchor.constraint(equalTo: scannerButton.leadingAnchor, constant: -8).isActive = true
        iconView.centerYAnchor.constraint(equalTo: scannerButton.centerYAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            iconView.heightAnchor.constraint(equalToConstant: iconView.intrinsicContentSize.height * 0.75).isActive = true
        } else {
            iconView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        
        iconView.widthAnchor.constraint(equalToConstant: iconView.intrinsicContentSize.width * 0.75).isActive = true
    }
    
    @objc private func showScanner() {
        delegate?.onBottomLinkTapped()
    }
}

// MARK: Anchoring
extension FormView {
//    func anchorNavbar() {
//        navBar.translatesAutoresizingMaskIntoConstraints = false
//
//        if #available(iOS 13.0, *) {
//            navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
//        } else {
//            navBar.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
//        }
//
//        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
//    }
    
    func anchorContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: button.topAnchor).isActive = true
    }
    
    func anchorTitle() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
        title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
    }
    
    func anchorTextField(_ textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let column: Int = textField.tag % 10
        let row: Int = (textField.tag - column) / 10
        guard let rowLength = delegate?.formType.textFields[row].count else { return }
        guard let columnLength = delegate?.formType.textFields.count else { return }
        
        if (row == 0) {
            if let formType = delegate?.formType {
                switch formType {
                case .cardForm: textField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4).isActive = true
                default: textField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24).isActive = true
                }
            } else {
                textField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24).isActive = true
            }
        } else {
            textField.topAnchor.constraint(equalTo: textFields[row - 1][0].bottomAnchor, constant: 24).isActive = true
        }
        
        if (column == 0) {
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        } else {
            textField.leadingAnchor.constraint(equalTo: textFields[row][column - 1].trailingAnchor, constant: 10).isActive = true
        }
        
        if (column == rowLength - 1) {
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
        } else {
            textField.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -(((UIScreen.main.bounds.width * (CGFloat(column) + 1)) / CGFloat(rowLength)) + 5)
            ).isActive = true
        }
        
        textField.heightAnchor.constraint(equalToConstant: theme.layout.textFieldHeight).isActive = true
        
        if (row == columnLength - 1) {
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12).isActive = true
        }
        
        return
    }
    
    func anchorLink() {
        link.translatesAutoresizingMaskIntoConstraints = false
        link.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        link.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
        guard let textField = textFields.last?.last else { return }
        link.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24).isActive = true
    }
    
    func anchorButton() {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        guard let formType = delegate?.formType else { return }
        
        switch formType {
        case .cardForm:
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -64).isActive = true
        default:
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32).isActive = true
        }
        
    }
}

extension String {
    var isValidAccountNumber: Bool {
        print(!self.isEmpty)
        return !self.isEmpty
    }
}

extension UIButton {
    func setBusy(theme: PrimerThemeProtocol) {
        let indicator = UIActivityIndicatorView()
        self.setTitle("", for: .normal)
        self.addSubview(indicator)
        indicator.pin(to: self)
        indicator.color = theme.colorTheme.text2
        indicator.startAnimating()
    }
}
