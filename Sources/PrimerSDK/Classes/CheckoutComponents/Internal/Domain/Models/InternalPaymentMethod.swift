//
//  InternalPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

struct InternalPaymentMethod: Equatable {
  let id: String
  let type: String
  let name: String
  let icon: UIImage?
  let configId: String?
  let isEnabled: Bool
  let supportedCurrencies: [String]?
  let requiredInputElements: [PrimerInputElementType]
  let surcharge: Int?
  let hasUnknownSurcharge: Bool
  let networkSurcharges: [String: Int]?
  let backgroundColor: UIColor?
  let buttonText: String?
  let textColor: UIColor?
  let borderColor: UIColor?
  let borderWidth: CGFloat?
  let cornerRadius: CGFloat?

  init(
    id: String,
    type: String,
    name: String,
    icon: UIImage? = nil,
    configId: String? = nil,
    isEnabled: Bool = true,
    supportedCurrencies: [String]? = nil,
    requiredInputElements: [PrimerInputElementType] = [],
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

  // Manual conformance: `UIImage`/`UIColor` fields block automatic synthesis. All
  // rendering-affecting fields are included so that Equatable-based diffing (SwiftUI onChange,
  // dedup) reflects styling and config changes.
  static func == (lhs: InternalPaymentMethod, rhs: InternalPaymentMethod) -> Bool {
    lhs.id == rhs.id && lhs.type == rhs.type && lhs.name == rhs.name && lhs.icon == rhs.icon
      && lhs.configId == rhs.configId && lhs.isEnabled == rhs.isEnabled
      && lhs.supportedCurrencies == rhs.supportedCurrencies
      && lhs.requiredInputElements == rhs.requiredInputElements
      && lhs.surcharge == rhs.surcharge && lhs.hasUnknownSurcharge == rhs.hasUnknownSurcharge
      && lhs.networkSurcharges == rhs.networkSurcharges && lhs.backgroundColor == rhs.backgroundColor
      && lhs.buttonText == rhs.buttonText && lhs.textColor == rhs.textColor
      && lhs.borderColor == rhs.borderColor && lhs.borderWidth == rhs.borderWidth
      && lhs.cornerRadius == rhs.cornerRadius
  }
}
