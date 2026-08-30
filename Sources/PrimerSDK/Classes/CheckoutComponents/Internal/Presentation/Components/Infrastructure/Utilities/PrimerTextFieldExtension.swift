//
//  PrimerTextFieldExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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

  static let email = PrimerTextFieldConfiguration(
    keyboardType: .emailAddress,
    autocapitalizationType: .none,
    autocorrectionType: .no,
    textContentType: .emailAddress,
    returnKeyType: .done,
    isSecureTextEntry: false
  )

  static let numberPad = PrimerTextFieldConfiguration(
    keyboardType: .numberPad,
    autocapitalizationType: .none,
    autocorrectionType: .no,
    textContentType: nil,
    returnKeyType: .done,
    isSecureTextEntry: false
  )

  /// Secure entry with number pad and no autofill
  static let cvv = PrimerTextFieldConfiguration(
    keyboardType: .numberPad,
    autocapitalizationType: .none,
    autocorrectionType: .no,
    textContentType: nil,
    returnKeyType: .done,
    isSecureTextEntry: true
  )

  /// Uses all caps auto-capitalization
  static let postalCode = PrimerTextFieldConfiguration(
    keyboardType: .default,
    autocapitalizationType: .allCharacters,
    autocorrectionType: .no,
    textContentType: nil,
    returnKeyType: .done,
    isSecureTextEntry: false
  )

  /// Number pad with no autofill
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

@available(iOS 15.0, *)
extension UITextField {
  func configurePrimerStyle(
    placeholder: String,
    configuration: PrimerTextFieldConfiguration,
    tokens: DesignTokens?,
    doneButtonTarget: Any?,
    doneButtonAction: Selector
  ) {
    self.placeholder = placeholder

    // Apply keyboard configuration
    keyboardType = configuration.keyboardType
    autocapitalizationType = configuration.autocapitalizationType
    autocorrectionType = configuration.autocorrectionType
    textContentType = configuration.textContentType
    returnKeyType = configuration.returnKeyType
    isSecureTextEntry = configuration.isSecureTextEntry

    inputAccessoryView = Self.makeDoneAccessory(
      tokens: tokens,
      target: doneButtonTarget,
      action: doneButtonAction
    )

    applyPrimerAppearance(placeholder: placeholder, tokens: tokens)
  }

  /// Every token-derived appearance property, reapplied from `updateUIView` as well as at creation
  /// so a colour-scheme change repaints the bridged field. Sets no user state.
  func applyPrimerAppearance(placeholder: String, tokens: DesignTokens?) {
    borderStyle = .none
    backgroundColor = .clear

    // Text styling with design tokens
    let textFont = PrimerFont.uiFontBodyLarge(tokens: tokens)
    font = textFont
    adjustsFontForContentSizeCategory = true
    textColor = UIColor(CheckoutColors.inputText(tokens: tokens))

    // Placeholder styling with design tokens
    let placeholderColor = UIColor(CheckoutColors.textPlaceholder(tokens: tokens))
    attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: [.foregroundColor: placeholderColor, .font: textFont]
    )

    if let toolbar = inputAccessoryView as? UIToolbar {
      Self.applyDoneAccessoryStyle(to: toolbar, tokens: tokens)
    }
  }

  /// Auto-sizing keyboard toolbar with a trailing "Done" button.
  private static func makeDoneAccessory(
    tokens: DesignTokens?,
    target: Any?,
    action: Selector
  ) -> UIToolbar {
    let toolbar = UIToolbar(
      frame: CGRect(x: 0, y: 0, width: 0, height: PrimerComponentHeight.keyboardAccessory)
    )
    toolbar.barStyle = .default
    toolbar.sizeToFit()

    let doneItem = UIBarButtonItem(
      title: CheckoutComponentsStrings.doneButton,
      style: .done,
      target: target,
      action: action
    )
    doneItem.accessibilityLabel = CheckoutComponentsStrings.doneButton

    toolbar.items = [.flexibleSpace(), doneItem]
    applyDoneAccessoryStyle(to: toolbar, tokens: tokens)
    return toolbar
  }

  /// Restyled in place rather than rebuilt, so reapplying it cannot reload the live keyboard.
  private static func applyDoneAccessoryStyle(to toolbar: UIToolbar, tokens: DesignTokens?) {
    let tint = UIColor(CheckoutColors.buttonPrimary(tokens: tokens))
    toolbar.tintColor = tint
    let titleFont = PrimerFont.uiFontTitleLarge(tokens: tokens)
    toolbar.items?.forEach {
      $0.setTitleTextAttributes([.font: titleFont, .foregroundColor: tint], for: .normal)
      $0.setTitleTextAttributes([.font: titleFont, .foregroundColor: tint], for: .highlighted)
    }
  }
}
