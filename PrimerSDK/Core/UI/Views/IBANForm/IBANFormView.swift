//
//  IBANFormView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

import UIKit

protocol IBANFormViewDelegate: class {
    var theme: PrimerTheme { get }
    func cancel() -> Void
    func next() -> Void
    func onIBANTextFieldChanged(_ sender: UITextField) -> Void
}


class IBANFormView: UIView, ReactiveView {
    let indicator = UIActivityIndicatorView()
    let navBar = UINavigationBar()
    let mainTitle = UILabel()
    let subtitle = UILabel()
    let textField = UITextField()
    let switchLabel = UILabel()
    let nextButton = UIButton()
    
    weak var  delegate: IBANFormViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(mainTitle)
        addSubview(subtitle)
        addSubview(textField)
        addSubview(switchLabel)
        addSubview(nextButton)
        
        configureNavBar()
        configureMainTitle()
        configureSubtitle()
        
        configureTextField()
        configureSwitchLabel()
        configureNextButton(disabled: true)
        
        anchorMainTitle()
        anchorSubtitle()
        anchorTextField()
        anchorSwitchLabel()
        anchorNextButton()
        
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func render(isBusy: Bool) {
        
    }
    
    private func configureNavBar() {
        guard let theme = delegate?.theme else { return }
        navBar.backgroundColor = theme.backgroundColor
        navBar.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 44)
        let navItem = UINavigationItem(title: "")
        let doneItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancel))
        doneItem.tintColor = .blue
        
        navItem.leftBarButtonItem = doneItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
    }
    
    @objc private func cancel() { delegate?.cancel() }
    
    private func configureMainTitle() {
        guard let theme = delegate?.theme else { return }
        mainTitle.text = theme.content.ibanForm.mainTitleText
        mainTitle.textColor = theme.fontColorTheme.title
        mainTitle.font = .boldSystemFont(ofSize: 32)
    }
    
    private func configureSubtitle() {
        guard let theme = delegate?.theme else { return }
        subtitle.text = theme.content.ibanForm.subtitleText
        subtitle.textColor = .gray
        subtitle.numberOfLines = 0
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.sizeToFit()
    }
    
    private func configureTextField() {
        guard let theme = delegate?.theme else { return }
        textField.backgroundColor = .white
        textField.placeholder = theme.content.ibanForm.textFieldPlaceholder
        textField.layer.cornerRadius = theme.cornerRadiusTheme.textFields
        textField.setLeftPaddingPoints(5)
        textField.adjustsFontSizeToFitWidth = true
        textField.addTarget(self, action: #selector(onExpiryTextFieldChanged), for: .editingChanged)
    }
    
    @objc private func onExpiryTextFieldChanged(_ sender: UITextField) {
        delegate?.onIBANTextFieldChanged(sender)
        guard let trimmedString = sender.text?.trimmingCharacters(in: .whitespaces) else { return }
        configureNextButton(disabled: trimmedString.count < 5)
    }
    
    private func configureSwitchLabel() {
        guard let theme = delegate?.theme else { return }
        switchLabel.text = theme.content.ibanForm.switchLabelText
        switchLabel.font = .systemFont(ofSize: 14, weight: .light)
        switchLabel.textColor = .blue
    }
    
    private func configureNextButton(disabled: Bool) {
        guard let theme = delegate?.theme else { return }
        nextButton.setTitle(theme.content.ibanForm.nextButtonText, for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = theme.cornerRadiusTheme.buttons
        nextButton.backgroundColor = disabled ? .lightGray : .blue
        
        if (disabled) {
            nextButton.removeTarget(self, action: #selector(presentNext), for: .touchUpInside)
        } else {
            nextButton.addTarget(self, action: #selector(presentNext), for: .touchUpInside)
        }
    }
    
    @objc func presentNext() { delegate?.next() }
    
    //
    
    private func anchorMainTitle() {
        mainTitle.translatesAutoresizingMaskIntoConstraints = false
        mainTitle.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 8).isActive = true
        mainTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
    }
    
    private func anchorSubtitle() {
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.topAnchor.constraint(equalTo: mainTitle.bottomAnchor, constant: 12).isActive = true
        subtitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        subtitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
    }
    
    private func anchorTextField() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12).isActive = true
        textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    private func anchorSwitchLabel() {
        switchLabel.translatesAutoresizingMaskIntoConstraints = false
        switchLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 12).isActive = true
        switchLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        switchLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
    }
    
    private func anchorNextButton() {
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.topAnchor.constraint(equalTo: switchLabel.bottomAnchor, constant: 24).isActive = true
        nextButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        nextButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
}

