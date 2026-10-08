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

  /// The same configuration carrying a content type, so one preset covers several fields that
  /// differ only in what the OS should offer to fill.
  func offering(_ contentType: UITextContentType?) -> PrimerTextFieldConfiguration {
    PrimerTextFieldConfiguration(
      keyboardType: keyboardType,
      autocapitalizationType: autocapitalizationType,
      autocorrectionType: autocorrectionType,
      textContentType: contentType,
      returnKeyType: returnKeyType,
      isSecureTextEntry: isSecureTextEntry
    )
  }

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

  /// Phone entry. The billing phone was on an alphabetic keyboard with word capitalisation.
  static let phoneNumber = PrimerTextFieldConfiguration(
    keyboardType: .phonePad,
    autocapitalizationType: .none,
    autocorrectionType: .no,
    textContentType: .telephoneNumber,
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
    borderStyle = .none
    backgroundColor = .clear
    // At large text sizes the placeholder's width would otherwise push the form off screen.
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    // Apply keyboard configuration
    keyboardType = configuration.keyboardType
    autocapitalizationType = configuration.autocapitalizationType
    autocorrectionType = configuration.autocorrectionType
    textContentType = configuration.textContentType
    returnKeyType = configuration.returnKeyType
    isSecureTextEntry = configuration.isSecureTextEntry

    // Text styling with design tokens
    let textFont = PrimerFont.uiFontBodyLarge(tokens: tokens)
    font = textFont
    adjustsFontForContentSizeCategory = true
    textColor = UIColor(CheckoutColors.inputText(tokens: tokens))
    // The caret, like Android's cursor, takes the focused border colour.
    tintColor = UIColor(CheckoutColors.borderFocus(tokens: tokens))
    // A UITextField kerns typed text from its default attributes, not from `font`.
    if let letterSpacing = PrimerTextStyle.bodyLarge.letterSpacing(tokens: tokens) {
      defaultTextAttributes[.kern] = letterSpacing
    }

    // Placeholder styling with design tokens
    attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: Self.primerPlaceholderAttributes(font: textFont, tokens: tokens)
    )

    inputAccessoryView = Self.makeDoneAccessory(
      tokens: tokens,
      target: doneButtonTarget,
      action: doneButtonAction
    )
  }

  /// The token-derived colours a bridged field paints, reapplied after a colour-scheme change and
  /// when the field locks or unlocks around a payment (locked text takes `textDisabled`): the text,
  /// the placeholder, the caret and the tint of the Done button.
  ///
  /// Deliberately narrow. It does not touch the font, border or fill, and it repaints the existing
  /// `inputAccessoryView` rather than replacing it: writing those on a live field is what broke the
  /// two earlier attempts at this fix.
  func repaintPrimerColors(placeholder: String, tokens: DesignTokens?, isEnabled: Bool = true) {
    textColor = UIColor(CheckoutColors.inputText(tokens: tokens, isEnabled: isEnabled))
    tintColor = UIColor(CheckoutColors.borderFocus(tokens: tokens))
    attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: Self.primerPlaceholderAttributes(
        font: font ?? PrimerFont.uiFontBodyLarge(tokens: tokens),
        tokens: tokens
      )
    )
    if let toolbar = inputAccessoryView as? UIToolbar {
      Self.paintDoneAccessory(toolbar, tokens: tokens)
    }
  }

  /// The font and letter spacing of the typed text, which only a re-theme moves. The repainter calls
  /// this after the SwiftUI update and only when they changed: writing the font from every update
  /// invalidated the field's size mid-layout and stopped the card form rendering.
  func repaintPrimerTypography(placeholder: String, tokens: DesignTokens?, isEnabled: Bool) {
    font = PrimerFont.uiFontBodyLarge(tokens: tokens)
    if let letterSpacing = PrimerTextStyle.bodyLarge.letterSpacing(tokens: tokens) {
      defaultTextAttributes[.kern] = letterSpacing
    } else {
      defaultTextAttributes.removeValue(forKey: .kern)
    }
    repaintPrimerColors(placeholder: placeholder, tokens: tokens, isEnabled: isEnabled)
  }

  private static func primerPlaceholderAttributes(
    font: UIFont,
    tokens: DesignTokens?
  ) -> [NSAttributedString.Key: Any] {
    var attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor(CheckoutColors.textPlaceholder(tokens: tokens)),
      .font: font
    ]
    if let letterSpacing = PrimerTextStyle.bodyLarge.letterSpacing(tokens: tokens) {
      attributes[.kern] = letterSpacing
    }
    return attributes
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

    // Not .done: iOS 26 draws it as .prominent, a capsule filled with the tint, which makes the label unreadable.
    let doneItem = UIBarButtonItem(
      title: CheckoutComponentsStrings.doneButton,
      style: .plain,
      target: target,
      action: action
    )
    doneItem.accessibilityLabel = CheckoutComponentsStrings.doneButton

    toolbar.items = [.flexibleSpace(), doneItem]
    paintDoneAccessory(toolbar, tokens: tokens)
    return toolbar
  }

  private static func paintDoneAccessory(_ toolbar: UIToolbar, tokens: DesignTokens?) {
    let tint = UIColor(CheckoutColors.buttonPrimary(tokens: tokens))
    let attributes: [NSAttributedString.Key: Any] = [.font: PrimerFont.uiFontTitleLarge(tokens: tokens), .foregroundColor: tint]
    toolbar.tintColor = tint
    toolbar.items?.forEach {
      $0.setTitleTextAttributes(attributes, for: .normal)
      $0.setTitleTextAttributes(attributes, for: .highlighted)
    }
  }
}

/// Holds the token set and lock state a bridged field was last painted with, so `updateUIView`
/// repaints on a colour-scheme change or when the form locks for a payment, and does nothing on the
/// keystrokes that make up almost every other call. A lock also disables the field and ends its edit,
/// and a re-theme that moves the font or letter spacing rewrites them once the update is over.
///
/// Identity, not equality: `DesignTokensManager` decodes a fresh `DesignTokens` per scheme, and the
/// `UIColor`s built from it never compare equal, so a value check would repaint every time.
@available(iOS 15.0, *)
final class PrimerFieldRepainter {
  private var appliedTokens: DesignTokens?
  private var appliedEnabled = true

  /// Seeded from `makeUIView`, which has already painted the field.
  func markApplied(_ tokens: DesignTokens?) {
    appliedTokens = tokens
  }

  func repaintIfNeeded(
    _ textField: UITextField,
    placeholder: String,
    tokens: DesignTokens?,
    isEnabled: Bool = true
  ) {
    guard appliedTokens !== tokens || appliedEnabled != isEnabled else { return }
    let typographyMoved = Self.typographyMoved(from: appliedTokens, to: tokens)
    appliedTokens = tokens
    appliedEnabled = isEnabled
    textField.repaintPrimerColors(placeholder: placeholder, tokens: tokens, isEnabled: isEnabled)
    textField.isEnabled = isEnabled
    // Greyed out alone, a focused field kept typing into the payment. Async: ending the edit writes a binding.
    if !isEnabled, textField.isFirstResponder {
      DispatchQueue.main.async { [weak textField] in textField?.resignFirstResponder() }
    }
    if typographyMoved {
      DispatchQueue.main.async { [weak self, weak textField] in
        guard let self else { return }
        textField?.repaintPrimerTypography(placeholder: placeholder, tokens: appliedTokens, isEnabled: appliedEnabled)
      }
    }
  }

  /// A scheme change decodes new tokens with the same font and spacing, so only a re-theme moves them.
  private static func typographyMoved(from old: DesignTokens?, to new: DesignTokens?) -> Bool {
    PrimerFont.uiFontBodyLarge(tokens: old) != PrimerFont.uiFontBodyLarge(tokens: new)
      || PrimerTextStyle.bodyLarge.letterSpacing(tokens: old) != PrimerTextStyle.bodyLarge.letterSpacing(tokens: new)
  }
}

// MARK: - Per-field configuration

@available(iOS 15.0, *)
extension PrimerInputElementType {
  /// What the OS should offer to fill, and the keyboard to go with it. Without a content type iOS
  /// shows no saved card, no camera scan and no saved address, which is what the card form had.
  var fieldConfiguration: PrimerTextFieldConfiguration {
    switch self {
    case .phoneNumber: .phoneNumber
    case .firstName: .standard.offering(.givenName)
    case .lastName: .standard.offering(.familyName)
    case .addressLine1: .standard.offering(.streetAddressLine1)
    case .addressLine2: .standard.offering(.streetAddressLine2)
    default: .standard
    }
  }
}
