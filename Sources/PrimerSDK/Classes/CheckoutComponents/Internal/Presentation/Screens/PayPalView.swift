//
//  PayPalView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerResources
@_spi(PrimerInternal) import PrimerCore

/// PayPal selection auto-launches the window-level redirect (`ASWebAuthenticationSession`) from the
/// scope's `start()`, so this in-tree screen only shows a processing spinner underneath it — there
/// is no intermediate "Continue to PayPal" step. Mirrors Android, which routes redirect methods
/// straight to a processing screen.
@available(iOS 15.0, *)
struct PayPalView: View {
  let scope: any PrimerPayPalScope

  var body: some View {
    DefaultLoadingScreen()
  }
}
