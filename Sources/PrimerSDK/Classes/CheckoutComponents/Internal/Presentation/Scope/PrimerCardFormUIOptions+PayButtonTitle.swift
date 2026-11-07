//
//  PrimerCardFormUIOptions+PayButtonTitle.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

extension PrimerCardFormUIOptions {
  static func payButtonTitle(
    _ options: PrimerCardFormUIOptions?,
    formattedAmount: String?,
    defaultTitle: String,
    defaultTitleWithAmount: (String) -> String
  ) -> String {
    let customText = options?.payButtonText?.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = customText?.isEmpty == false ? customText : nil
    guard options?.payButtonAmountVisible == true, let formattedAmount else { return title ?? defaultTitle }
    return title.map { "\($0) \(formattedAmount)" } ?? defaultTitleWithAmount(formattedAmount)
  }
}
