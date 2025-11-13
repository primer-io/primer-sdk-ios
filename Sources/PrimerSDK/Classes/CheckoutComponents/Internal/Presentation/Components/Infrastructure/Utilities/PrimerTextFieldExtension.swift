//
//  PrimerTextFieldExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
struct PrimerTextFieldConfiguration {
    let keyboardType: UIKeyboardType
    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let textContentType: UITextContentType?
    let returnKeyType: UIReturnKeyType
    let isSecureTextEntry: Bool

    static let standard = PrimerTextFieldConfiguration()

    static let email = PrimerTextFieldConfiguration(
        keyboardType: .emailAddress,
        autocapitalizationType: .none,
        textContentType: .emailAddress
    )

    static let numberPad = PrimerTextFieldConfiguration(
        keyboardType: .numberPad,
        autocapitalizationType: .none
    )

    static let cvv = PrimerTextFieldConfiguration(
        keyboardType: .numberPad,
        autocapitalizationType: .none,
        textContentType: .oneTimeCode,
        isSecureTextEntry: true
    )

    static let postalCode = PrimerTextFieldConfiguration(
        autocapitalizationType: .allCharacters
    )

    static let expiryDate = PrimerTextFieldConfiguration(
        keyboardType: .numberPad,
        autocapitalizationType: .none,
        textContentType: .none
    )

    init(
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .words,
        autocorrectionType: UITextAutocorrectionType = .no,
        textContentType: UITextContentType? = nil,
        returnKeyType: UIReturnKeyType = .done,
        isSecureTextEntry: Bool = false
    ) {
        self.keyboardType = keyboardType
        self.autocapitalizationType = autocapitalizationType
        self.autocorrectionType = autocorrectionType
        self.textContentType = textContentType
        self.returnKeyType = returnKeyType
        self.isSecureTextEntry = isSecureTextEntry
    }
}

@available(iOS 15.0, *)
extension UITextField {
    func configurePrimerStyle(
        placeholder: String,
        configuration: PrimerTextFieldConfiguration,
        styling: PrimerFieldStyling?,
        tokens: DesignTokens?,
        doneButtonTarget: Any?,
        doneButtonAction: Selector
    ) {
        self.placeholder = placeholder
        borderStyle = .none
        backgroundColor = .clear

        applyConfiguration(configuration)

        let font = PrimerFont.uiFontBodyLarge(tokens: tokens)
        applyTextStyling(placeholder: placeholder, styling: styling, tokens: tokens, font: font)

        inputAccessoryView = setupKeyboardAccessory(target: doneButtonTarget, action: doneButtonAction)
    }

    private func applyConfiguration(_ configuration: PrimerTextFieldConfiguration) {
        keyboardType = configuration.keyboardType
        autocapitalizationType = configuration.autocapitalizationType
        autocorrectionType = configuration.autocorrectionType
        textContentType = configuration.textContentType
        returnKeyType = configuration.returnKeyType
        isSecureTextEntry = configuration.isSecureTextEntry
    }

    private func applyTextStyling(
        placeholder: String,
        styling: PrimerFieldStyling?,
        tokens: DesignTokens?,
        font: UIFont
    ) {
        // Note: We ignore styling.font because SwiftUI Font cannot be properly converted to UIFont
        // Custom fonts would be lost in the conversion. Always use PrimerFont.uiFontBodyLarge instead.
        self.font = font
        textColor = styling?.textColor.map(UIColor.init) ?? UIColor(CheckoutColors.textPrimary(tokens: tokens))

        let placeholderColor = styling?.placeholderColor.map(UIColor.init) ?? UIColor(CheckoutColors.textPlaceholder(tokens: tokens))
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor, .font: font]
        )
    }

    private func setupKeyboardAccessory(target: Any?, action: Selector) -> UIView {
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: PrimerComponentHeight.keyboardAccessory))
        accessoryView.backgroundColor = UIColor.systemGray6

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        if let target {
            doneButton.addTarget(target, action: action, for: .touchUpInside)
        }

        accessoryView.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor),
        ])

        return accessoryView
    }
}
