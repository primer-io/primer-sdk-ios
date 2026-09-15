//
//  PrimerFieldErrorIcon.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The warning glyph a field shows inside itself while it holds an error.
@available(iOS 15.0, *)
struct PrimerFieldErrorIcon: View {
  @Environment(\.designTokens) private var tokens

  var body: some View {
    let size = PrimerSize.medium(tokens: tokens)
    Image(systemName: "exclamationmark.triangle.fill")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .foregroundColor(CheckoutColors.iconNegative(tokens: tokens))
  }
}
