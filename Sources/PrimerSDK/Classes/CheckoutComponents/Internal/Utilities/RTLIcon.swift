//
//  RTLIcon.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Provides RTL-aware SF Symbol icon names for directional navigation icons.
/// Automatically flips chevron directions based on the current layout direction.
@available(iOS 15.0, *)
enum RTLIcon {
    /// Returns the appropriate back navigation chevron icon name.
    /// - In LTR layouts: Returns "chevron.left" (pointing left/back)
    /// - In RTL layouts: Returns "chevron.right" (pointing right/back in RTL context)
    static var backChevron: String {
        RTLSupport.isRightToLeft ? "chevron.right" : "chevron.left"
    }

    /// Returns the appropriate forward navigation chevron icon name.
    /// - In LTR layouts: Returns "chevron.right" (pointing right/forward)
    /// - In RTL layouts: Returns "chevron.left" (pointing left/forward in RTL context)
    static var forwardChevron: String {
        RTLSupport.isRightToLeft ? "chevron.left" : "chevron.right"
    }
}
