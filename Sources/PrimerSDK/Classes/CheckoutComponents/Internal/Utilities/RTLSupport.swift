//
//  RTLSupport.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// Provides utilities for detecting and handling right-to-left (RTL) layout direction.
/// Used by CheckoutComponents to properly support RTL languages like Arabic, Hebrew, Persian, Kurdish, and Urdu.
@available(iOS 15.0, *)
enum RTLSupport {
    /// Returns `true` if the application's user interface is currently in right-to-left layout direction.
    static var isRightToLeft: Bool {
        UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }

    /// Returns the current layout direction as a SwiftUI `LayoutDirection` value.
    /// Use this to inject the layout direction into SwiftUI's environment.
    static var layoutDirection: LayoutDirection {
        isRightToLeft ? .rightToLeft : .leftToRight
    }
}
