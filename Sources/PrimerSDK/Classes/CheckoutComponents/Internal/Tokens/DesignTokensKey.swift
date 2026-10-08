//
//  DesignTokensKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

struct DesignTokensKey: EnvironmentKey {
  static let defaultValue: DesignTokens? = nil
}

/// The scheme the tokens were loaded for. Inline, a forced `appearanceMode` moves the tokens but not the
/// merchant's `colorScheme`, so SDK views that pick a variant themselves read this one. Nil follows `colorScheme`.
struct DesignTokensColorSchemeKey: EnvironmentKey {
  static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
  var designTokens: DesignTokens? {
    get { self[DesignTokensKey.self] }
    set { self[DesignTokensKey.self] = newValue }
  }

  var designTokensColorScheme: ColorScheme? {
    get { self[DesignTokensColorSchemeKey.self] }
    set { self[DesignTokensColorSchemeKey.self] = newValue }
  }
}
