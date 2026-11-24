//
//  PrimerCardFormUIOptions+PayButtonTitle.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

extension PrimerCardFormUIOptions {
  static let amountToken = "{amount}"

  static func payButtonTitle(
    _ options: PrimerCardFormUIOptions?,
    formattedAmount: @autoclosure () -> String?,
    defaultTitle: String
  ) -> String {
    guard let text = options?.payButtonText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
      return defaultTitle
    }
    guard text.contains(amountToken) else { return text }
    if let amount = formattedAmount() {
      return text.replacingOccurrences(of: amountToken, with: amount)
    }
    let withoutAmount = text
      .replacingOccurrences(of: amountToken, with: "")
      .split(separator: " ", omittingEmptySubsequences: true)
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return withoutAmount.isEmpty ? defaultTitle : withoutAmount
  }
}
