//
//  SecureTextField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

/// A UITextField subclass that masks the `.text` property to prevent sensitive data
/// (card numbers, CVVs) from being exposed via debugger, logging, or view hierarchy dumps.
/// Use `internalText` to access the actual value.
final class SecureTextField: UITextField {
  var internalText: String? {
    get { super.text }
    set { super.text = newValue }
  }

  override var text: String? {
    get { "****" }
    set { super.text = newValue }
  }
}
