//
//  PrimerTextFieldExtension.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// Configuration for PrimerTextField behavior and appearance
@available(iOS 15.0, *)
struct PrimerTextFieldConfiguration {
    /// Keyboard type for the text field
    let keyboardType: UIKeyboardType

    /// Autocapitalization behavior
    let autocapitalizationType: UITextAutocapitalizationType

    /// Autocorrection behavior
    let autocorrectionType: UITextAutocorrectionType

    /// Text content type for autofill suggestions
    let textContentType: UITextContentType?

    /// Return key type
    let returnKeyType: UIReturnKeyType

    /// Whether the text should be displayed as secure (e.g., CVV)
    let isSecureTextEntry: Bool

    /// Default configuration for standard text input
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
        self.borderStyle = .none
        self.backgroundColor = .clear

        // Apply keyboard configuration
        self.keyboardType = configuration.keyboardType
        self.autocapitalizationType = configuration.autocapitalizationType
        self.autocorrectionType = configuration.autocorrectionType
        self.textContentType = configuration.textContentType
        self.returnKeyType = configuration.returnKeyType
        self.isSecureTextEntry = configuration.isSecureTextEntry

        // Text styling with design tokens
        // Note: We ignore styling.font because SwiftUI Font cannot be properly converted to UIFont
        // Custom fonts would be lost in the conversion. Always use PrimerFont.uiFontBodyLarge instead.
        self.font = PrimerFont.uiFontBodyLarge(tokens: tokens)
        self.textColor = styling?.textColor.map(UIColor.init) ?? UIColor(PrimerCheckoutColors.textPrimary(tokens: tokens))

        // Placeholder styling with design tokens
        let placeholderColor = styling?.placeholderColor.map(UIColor.init) ?? UIColor(PrimerCheckoutColors.textPlaceholder(tokens: tokens))
        self.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [ .foregroundColor: placeholderColor, .font: font ]
        )

        // Add keyboard accessory view with "Done" button
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: PrimerComponentHeight.keyboardAccessory))
        accessoryView.backgroundColor = UIColor.systemGray6

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        if let target = doneButtonTarget {
            doneButton.addTarget(target, action: doneButtonAction, for: .touchUpInside)
        }

        accessoryView.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor)
        ])

        self.inputAccessoryView = accessoryView
    }
}
