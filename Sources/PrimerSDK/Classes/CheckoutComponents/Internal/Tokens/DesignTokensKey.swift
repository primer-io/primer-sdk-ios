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

extension EnvironmentValues {
  var designTokens: DesignTokens? {
    get { self[DesignTokensKey.self] }
    set { self[DesignTokensKey.self] = newValue }
  }
}
