//
//  AnimationConstants.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

/// Animation specifications matching Figma design system
struct AnimationConstants {

    // MARK: - Duration

    /// Standard duration for focus state transitions (0.2 seconds)
    static let focusDuration: Double = 0.2

    /// Standard duration for error state transitions (0.2 seconds)
    static let errorDuration: Double = 0.2

    /// Standard duration for general UI state changes (0.2 seconds)
    static let standardDuration: Double = 0.2

    /// Auto-dismiss delay for success and error screens (3.0 seconds)
    static let autoDismissDelay: Double = 3.0

    // MARK: - Animation Curves

    /// Standard easing curve for smooth transitions
    static let standardCurve: Animation = .easeInOut(duration: standardDuration)

    /// Focus state animation
    static let focusAnimation: Animation = .easeInOut(duration: focusDuration)

    /// Error state animation
    static let errorAnimation: Animation = .easeInOut(duration: errorDuration)

    /// Error appearance animation with spring effect
    static let errorSpringAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    // MARK: - Slide Offsets

    /// Slide offset for error animations (horizontal and vertical)
    static let errorSlideOffset: CGFloat = 10
}
