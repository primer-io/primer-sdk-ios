//
//  InternalPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

/// Internal representation of a payment method with full details.
/// This is used internally and mapped to the public CheckoutPaymentMethod.
struct InternalPaymentMethod: Equatable {
  let id: String
  let type: String
  let name: String
  let icon: UIImage?
  let configId: String?
  let isEnabled: Bool
  let supportedCurrencies: [String]?
  let requiredInputElements: [PrimerInputElementType]
  let metadata: [String: Any]?
  // Surcharge support
  let surcharge: Int?  // Raw amount in minor currency units
  let hasUnknownSurcharge: Bool  // "Fee may apply" flag
  let networkSurcharges: [String: Int]?  // Card network-specific surcharges
  let backgroundColor: UIColor?  // Dynamic background color from server
  let buttonText: String?  // Custom button text from displayMetadata
  let textColor: UIColor?  // Theme-aware text color from displayMetadata
  let borderColor: UIColor?  // Theme-aware border color from displayMetadata
  let borderWidth: CGFloat?  // Theme-aware border width from displayMetadata
  let cornerRadius: CGFloat?  // Custom corner radius from displayMetadata

  init(
    id: String,
    type: String,
    name: String,
    icon: UIImage? = nil,
    configId: String? = nil,
    isEnabled: Bool = true,
    supportedCurrencies: [String]? = nil,
    requiredInputElements: [PrimerInputElementType] = [],
    metadata: [String: Any]? = nil,
    surcharge: Int? = nil,
    hasUnknownSurcharge: Bool = false,
    networkSurcharges: [String: Int]? = nil,
    backgroundColor: UIColor? = nil,
    buttonText: String? = nil,
    textColor: UIColor? = nil,
    borderColor: UIColor? = nil,
    borderWidth: CGFloat? = nil,
    cornerRadius: CGFloat? = nil
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.icon = icon
    self.configId = configId
    self.isEnabled = isEnabled
    self.supportedCurrencies = supportedCurrencies
    self.requiredInputElements = requiredInputElements
    self.metadata = metadata
    self.surcharge = surcharge
    self.hasUnknownSurcharge = hasUnknownSurcharge
    self.networkSurcharges = networkSurcharges
    self.backgroundColor = backgroundColor
    self.buttonText = buttonText
    self.textColor = textColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.cornerRadius = cornerRadius
  }

  static func == (lhs: InternalPaymentMethod, rhs: InternalPaymentMethod) -> Bool {
    lhs.id == rhs.id && lhs.type == rhs.type && lhs.name == rhs.name
      && lhs.isEnabled == rhs.isEnabled && lhs.surcharge == rhs.surcharge
      && lhs.hasUnknownSurcharge == rhs.hasUnknownSurcharge
      && lhs.backgroundColor == rhs.backgroundColor
  }
}
