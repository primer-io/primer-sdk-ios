//
//  AccessibilityConfigurable.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
/// Protocol for views that provide accessibility configuration
protocol AccessibilityConfigurable {
    /// The accessibility configuration for this view
    var accessibilityConfiguration: AccessibilityConfiguration { get }

    /// Apply accessibility traits to the view
    /// Called automatically when view appears or state changes
    func applyAccessibilityTraits()
}

@available(iOS 15.0, *)
/// Default implementation for SwiftUI views
extension AccessibilityConfigurable where Self: View {
    func applyAccessibilityTraits() {
        // SwiftUI views apply traits via view modifiers (no action needed)
        // This method exists for protocol conformance and UIKit interop
    }
}
