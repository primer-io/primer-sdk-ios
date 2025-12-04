//
//  PrimerTextFieldExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// Configuration for PrimerTextField behavior and appearance
@available(iOS 15.0, *)
struct PrimerTextFieldConfiguration {
    let keyboardType: UIKeyboardType
    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let textContentType: UITextContentType?
    let returnKeyType: UIReturnKeyType
    let isSecureTextEntry: Bool

    static let standard = PrimerTextFieldConfiguration(
        keyboardType: .default,
        autocapitalizationType: .words,
        autocorrectionType: .no,
        textContentType: nil,
        returnKeyType: .done,
        isSecureTextEntry: false
    )

    /// Configuration for email input
    static let email = PrimerTextFieldConfiguration(
        keyboardType: .emailAddress,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .emailAddress,
        returnKeyType: .done,
        isSecureTextEntry: false
    )

    /// Configuration for number pad input
    static let numberPad = PrimerTextFieldConfiguration(
        keyboardType: .numberPad,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: nil,
        returnKeyType: .done,
        isSecureTextEntry: false
    )

    /// Configuration for CVV input (secure, number pad, one-time code)
    static let cvv = PrimerTextFieldConfiguration(
        keyboardType: .numberPad,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .oneTimeCode,
        returnKeyType: .done,
        isSecureTextEntry: true
    )

    /// Configuration for postal code input (default keyboard, all caps)
    static let postalCode = PrimerTextFieldConfiguration(
        keyboardType: .default,
        autocapitalizationType: .allCharacters,
        autocorrectionType: .no,
        textContentType: nil,
        returnKeyType: .done,
        isSecureTextEntry: false
    )

    /// Configuration for expiry date input (number pad, no autofill)
    static let expiryDate = PrimerTextFieldConfiguration(
        keyboardType: .numberPad,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .none,
        returnKeyType: .done,
        isSecureTextEntry: false
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

/// UITextField extension for consistent Primer styling and configuration
@available(iOS 15.0, *)
extension UITextField {
    /// Configures the text field with Primer design tokens and standard settings
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

        // Apply keyboard configuration
        keyboardType = configuration.keyboardType
        autocapitalizationType = configuration.autocapitalizationType
        autocorrectionType = configuration.autocorrectionType
        textContentType = configuration.textContentType
        returnKeyType = configuration.returnKeyType
        isSecureTextEntry = configuration.isSecureTextEntry

        // Text styling with design tokens
        if let fontName = styling?.fontName {
            font = PrimerFont.uiFont(
                family: fontName,
                weight: styling?.fontWeight,
                size: styling?.fontSize
            )
        } else {
            font = PrimerFont.uiFontBodyLarge(tokens: tokens)
        }
        textColor = styling?.textColor.map(UIColor.init) ?? UIColor(CheckoutColors.textPrimary(tokens: tokens))

        // Placeholder styling with design tokens
        let placeholderColor = styling?.placeholderColor.map(UIColor.init) ?? UIColor(CheckoutColors.textPlaceholder(tokens: tokens))
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor, .font: font]
        )

        // Add keyboard accessory view with "Done" button
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: PrimerComponentHeight.keyboardAccessory))
        accessoryView.backgroundColor = UIColor.systemGray6
        // Hide container from accessibility - only the button should be accessible
        accessoryView.isAccessibilityElement = false

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        doneButton.accessibilityLabel = "Done"
        doneButton.accessibilityTraits = .button
        if let target = doneButtonTarget {
            doneButton.addTarget(target, action: doneButtonAction, for: .touchUpInside)
        }

        accessoryView.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor),
        ])

        inputAccessoryView = accessoryView
    }
}
