//
//  DesignTokensKey.swift
//  
//
//  Created by Boris on 12.2.25..
//

import SwiftUI

/*
Abstract:

In your app’s view hierarchy, you can inject a DesignTokens instance (typically loaded from an API or generated via a build system like Style Dictionary) into the environment.
    For example, you could do this at the root of your view hierarchy using:
        .environment(\.designTokens, myDesignTokensInstance)
    Downstream views can then access these tokens using:
        @Environment(\.designTokens)

This approach allows you to decouple your design token configuration from the view code, making it easy to swap or update tokens without modifying individual view components. It also leverages SwiftUI’s built‑in environment mechanism for propagating configuration data, ensuring consistency and making theming straightforward.
*/

/// Define a custom EnvironmentKey for our design tokens.
/// This key will be used to store and retrieve a DesignTokens object in the SwiftUI environment.
/// The default value is nil, meaning that if no tokens are provided, the environment will return nil.
struct DesignTokensKey: EnvironmentKey {
    static let defaultValue: DesignTokens? = nil
}

/// Extend EnvironmentValues to include a new property, `designTokens`.
/// This computed property allows views to read and write design tokens from the SwiftUI environment.
/// It uses the `DesignTokensKey` to store the value.
extension EnvironmentValues {
    var designTokens: DesignTokens? {
        get { self[DesignTokensKey.self] }
        set { self[DesignTokensKey.self] = newValue }
    }
}
