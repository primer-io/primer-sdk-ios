//
//  KlarnaButtonText.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// The translated "Pay with Klarna" split at the brand name, so the badge takes the name's place and
/// keeps each language's word order: "Klarna ile öde" puts the badge first, "Mit Klarna bezahlen" in the middle.
struct KlarnaButtonText {
  let before: String?
  let after: String?

  private static let brandName = "Klarna"

  init(_ label: String) {
    let brand = label.range(of: Self.brandName)
    before = brand.flatMap { Self.piece(label[..<$0.lowerBound]) }
    after = brand.flatMap { Self.piece(label[$0.upperBound...]) }
  }

  private static func piece(_ text: Substring) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    return trimmed.isEmpty ? nil : trimmed
  }
}
