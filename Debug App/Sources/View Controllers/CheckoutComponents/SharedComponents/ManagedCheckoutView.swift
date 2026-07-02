//
//  ManagedCheckoutView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Renders the managed ``PrimerCheckout`` with the given settings and theme, dismissing the demo on
/// completion. Shared by the theme demos, which differ only by their `PrimerCheckoutTheme`.
@available(iOS 15.0, *)
struct ManagedCheckoutView: View {
    let clientToken: String
    let settings: PrimerSettings
    let theme: PrimerCheckoutTheme

    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        PrimerCheckout(
            clientToken: clientToken,
            primerSettings: settings,
            primerTheme: theme,
            onCompletion: { _ in dismiss() }
        )
    }
}
