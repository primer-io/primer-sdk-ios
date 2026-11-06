//
//  PaymentMethodAssetVariant.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

/// The backend's three versions of a partner button. A button takes one version for its background,
/// logo and text, chosen by the background, so a logo never sits on a background it was not made for.
enum PaymentMethodAssetVariant {
  case colored, light, dark

  /// The coloured version in both modes; without it, the current mode's, then the other mode's.
  static func pick<T>(colored: T?, light: T?, dark: T?, isDark: Bool) -> Self? {
    if colored != nil { return .colored }
    if isDark { return dark != nil ? .dark : light.map { _ in .light } }
    return light != nil ? .light : dark.map { _ in .dark }
  }

  /// Without a backend background the button takes the sheet's colour, which follows the mode.
  static func forBackground(_ background: PrimerTheme.BaseColors?, isDark: Bool) -> Self {
    pick(colored: background?.coloredHex, light: background?.lightHex, dark: background?.darkHex, isDark: isDark)
      ?? (isDark ? .dark : .light)
  }

  func value<T>(colored: T?, light: T?, dark: T?) -> T? {
    switch self {
    case .colored: colored
    case .light: light
    case .dark: dark
    }
  }

  /// This version, or when it is missing, the one `pick` chooses from what there is.
  func valueOrAny<T>(colored: T?, light: T?, dark: T?, isDark: Bool) -> T? {
    value(colored: colored, light: light, dark: dark)
      ?? Self.pick(colored: colored, light: light, dark: dark, isDark: isDark)?.value(colored: colored, light: light, dark: dark)
  }
}
