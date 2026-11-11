//
//  WebRedirectScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

/// A web-redirect method selection auto-launches the window-level redirect from the scope's
/// `start()`, so this in-tree screen only shows a processing spinner underneath it — there is no
/// intermediate "Continue" step. Mirrors Android, which routes redirect methods straight to a
/// processing screen.
@available(iOS 15.0, *)
struct WebRedirectScreen: View {
  let scope: any PrimerWebRedirectScope

  var body: some View {
    DefaultLoadingScreen()
  }
}
