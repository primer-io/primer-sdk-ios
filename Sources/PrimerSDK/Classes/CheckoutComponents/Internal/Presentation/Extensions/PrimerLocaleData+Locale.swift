//
//  PrimerLocaleData+Locale.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

extension PrimerLocaleData {
  /// The locale money is formatted in. Every amount the SDK prints goes through this, so a merchant
  /// who sets `localeData` sees it applied consistently rather than in some places only.
  ///
  /// Defaults to the device locale, because `PrimerLocaleData()` seeds itself from the device.
  var locale: Locale { Locale(identifier: localeCode) }
}
