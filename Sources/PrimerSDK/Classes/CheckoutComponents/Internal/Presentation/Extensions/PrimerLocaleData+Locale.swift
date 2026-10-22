//
//  PrimerLocaleData+Locale.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

extension PrimerLocaleData {
  /// The locale money is formatted in.
  var locale: Locale {
    let device = Locale.current
    let deviceLanguage = device.languageCode ?? "en"
    let deviceCode = device.regionCode.map { "\(deviceLanguage)-\($0)" } ?? deviceLanguage
    return localeCode == deviceCode ? device : Locale(identifier: localeCode)
  }
}
