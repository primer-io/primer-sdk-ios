//
//  UITextField+Accessibility.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension UITextField {

  /// VoiceOver focuses the text field itself, which the SwiftUI accessibility on its container doesn't reach on every
  /// iOS version, so the field's name, error and hint are set here too.
  func applyAccessibility(_ config: AccessibilityConfiguration) {
    accessibilityLabel = config.labelWithValue
    accessibilityHint = config.hint
  }
}
