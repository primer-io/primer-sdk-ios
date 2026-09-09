//
//  ThemedManagedDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// A managed-checkout demo that only varies by its theme. The theme catalog lives in ``ThemeDemos``;
/// each entry is registered with this view so the theming variants don't each need their own file.
@available(iOS 15.0, *)
struct ThemedManagedDemo: View {
    let configuration: DemoConfiguration
    let title: String
    let theme: PrimerCheckoutTheme

    var body: some View {
        DemoScaffold(configuration: configuration, title: title) { clientToken in
            ManagedCheckoutView(clientToken: clientToken, settings: configuration.settings, theme: theme)
        }
    }
}
