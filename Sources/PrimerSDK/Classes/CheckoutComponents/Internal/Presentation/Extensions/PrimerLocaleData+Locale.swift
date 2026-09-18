//
//  PrimerLocaleData+Locale.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

extension PrimerLocaleData {
  /// The locale money is formatted in. Reached through `ConfigurationService.locale`, which is where
  /// every amount the SDK prints takes both its currency and its locale, so the two cannot disagree.
  ///
  /// Yields the device locale untouched when the configured code already describes the device.
  /// `localeCode` carries only a language and a region, so rebuilding from it would drop the script
  /// subtag and the number format a customer chose in Settings. A device on `sr-Latn-RS` would start
  /// printing as `sr-RS`, and `PrimerLocaleData()` seeds itself from the device, so that would hit
  /// every merchant who never set one.
  var locale: Locale {
    let device = Locale.current
    let deviceLanguage = device.languageCode ?? "en"
    let deviceCode = device.regionCode.map { "\(deviceLanguage)-\($0)" } ?? deviceLanguage
    return localeCode == deviceCode ? device : Locale(identifier: localeCode)
  }
}
