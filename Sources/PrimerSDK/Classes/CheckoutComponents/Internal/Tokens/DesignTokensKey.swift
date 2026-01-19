//
//  DesignTokensKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

/// Environment key for injecting design tokens into SwiftUI views.
struct DesignTokensKey: EnvironmentKey {
    static let defaultValue: DesignTokens? = nil
}

extension EnvironmentValues {
    var designTokens: DesignTokens? {
        get { self[DesignTokensKey.self] }
        set { self[DesignTokensKey.self] = newValue }
    }
}
