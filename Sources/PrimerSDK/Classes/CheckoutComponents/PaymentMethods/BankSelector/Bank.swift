//
//  Bank.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Public model representing a selectable bank institution in the bank selector UI.
/// Maps from the internal `AdyenBank` API response model.
@available(iOS 15.0, *)
public struct Bank: Equatable, Identifiable {
  /// Unique bank identifier used as issuer in tokenization.
  public let id: String
  /// Display name of the bank (e.g., "ING Bank").
  public let name: String
  /// URL for the bank logo image, loaded asynchronously.
  public let iconUrl: URL?
  /// Whether the bank is currently unavailable for selection.
  public let isDisabled: Bool

  public init(id: String, name: String, iconUrl: URL?, isDisabled: Bool) {
    self.id = id
    self.name = name
    self.iconUrl = iconUrl
    self.isDisabled = isDisabled
  }

  /// Creates a Bank from the internal AdyenBank API response model.
  init(from adyenBank: AdyenBank) {
    self.id = adyenBank.id
    self.name = adyenBank.name
    self.iconUrl = adyenBank.iconUrlStr.flatMap { URL(string: $0) }
    self.isDisabled = adyenBank.disabled
  }
}
