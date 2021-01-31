//
//  SingleFieldFormView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 18/01/2021.
//

import UIKit

protocol SingleFieldFormViewDelegate: class {
    var textFieldType: TextFieldType { get }
    var theme: PrimerTheme { get }
    func back()
    func confirm()
    func onSubmit()
    func onTextFieldEditingDidEnd(_ sender: UITextField)
    func onTextFieldEditingChanged(_ sender: UITextField, mainButton: UIButton)
}

class SingleFieldFormView: UIView {
    let navBar = UINavigationBar()
    let title = UILabel()
    let textField = UITextField()
    let link = UILabel()
    let button = UIButton()
    
    weak var delegate: SingleFieldFormViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(title)
        addSubview(textField)
        addSubview(link)
        addSubview(button)
        
        configureNavbar()
        configureTitle()
        configureTextField()
        configureLink()
        configureButton()
        
        anchorNavbar()
        anchorTitle()
        anchorTextField()
        anchorLink()
        anchorButton()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: Configuration
extension SingleFieldFormView {
    func configureNavbar() {
        guard let delegate = delegate else { return }
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem()
        backItem.action = #selector(back)
        let backBtnImage = ImageName.back.image
        backItem.tintColor = .systemBlue
        backItem.image = backBtnImage
        let editItem = UIBarButtonItem()
        editItem.title = delegate.textFieldType.topRightButtonTitle
        editItem.tintColor = .systemBlue
        editItem.action = #selector(confirm)
        navItem.leftBarButtonItem = backItem
        navItem.rightBarButtonItem = editItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = delegate.textFieldType.topTitle
    }
    
    @objc private func back() { delegate?.back() }
    
    @objc private func confirm() { delegate?.confirm() }
    
    func configureTitle() {
        guard let delegate = delegate else { return }
        title.text = delegate.textFieldType.mainTitle
        title.textAlignment = .center
        title.font = .systemFont(ofSize: 20)
    }
    
    func configureTextField() {
        guard let delegate = delegate else { return }
        textField.text = delegate.textFieldType.initialValue
        delegate.onTextFieldEditingChanged(textField, mainButton: button)
        textField.addLine()
        textField.setLeftPaddingPoints(5)
        textField.addTarget(self, action: #selector(onTextFieldEditingDidEnd), for: .editingDidEndOnExit)
        textField.addTarget(self, action: #selector(onTextFieldEditingChanged), for: .editingChanged)
        textField.autocapitalizationType = .none
        textField.addMiniTitle(delegate.textFieldType.placeHolder)
    }
    
    @objc private func onTextFieldEditingDidEnd(_ sender: UITextField) {
        delegate?.onTextFieldEditingDidEnd(sender)
    }
    
    @objc private func onTextFieldEditingChanged(_ sender: UITextField) {
        delegate?.onTextFieldEditingChanged(sender, mainButton: button)
    }
    
    func configureLink() {
        guard let delegate = delegate else { return }
        link.text = delegate.textFieldType.subtitle
        link.font = .systemFont(ofSize: 15)
        link.textColor = .systemBlue
        link.textAlignment = .center
    }
    
    func configureButton() {
        guard let delegate = delegate else { return }
        button.setTitle("Next", for: .normal)
        button.layer.cornerRadius = delegate.theme.cornerRadiusTheme.buttons
        button.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
    }
    
    @objc private func onButtonPressed(_ button: UIButton) {
        delegate?.onSubmit()
    }
}

// MARK: Anchoring
extension SingleFieldFormView {
    func anchorNavbar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    func anchorTitle() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        title.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
    }
    
    func anchorTextField() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        textField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24).isActive = true
    }
    
    func anchorLink() {
        link.translatesAutoresizingMaskIntoConstraints = false
        link.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        link.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        link.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -30).isActive = true
    }
    
    func anchorButton() {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true
    }
}
