//
//  SlideInModifier.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

enum SlideDirection {
    case leading
    case trailing
    case top
    case bottom

    var axis: Axis {
        switch self {
        case .leading, .trailing:
            return .horizontal
        case .top, .bottom:
            return .vertical
        }
    }

    var offsetMultiplier: CGFloat {
        switch self {
        case .leading, .top:
            return -1
        case .trailing, .bottom:
            return 1
        }
    }
}

/// A view modifier that animates a view sliding in/out with fade effect
struct SlideInModifier: ViewModifier {
    let isVisible: Bool
    let direction: SlideDirection

    /// The distance to slide (default uses AnimationConstants.errorSlideOffset)
    let slideDistance: CGFloat

    /// The animation to use (default uses AnimationConstants.errorSpringAnimation)
    let animation: Animation

    init(
        isVisible: Bool,
        direction: SlideDirection,
        slideDistance: CGFloat = AnimationConstants.errorSlideOffset,
        animation: Animation = AnimationConstants.errorSpringAnimation
    ) {
        self.isVisible = isVisible
        self.direction = direction
        self.slideDistance = slideDistance
        self.animation = animation
    }

    func body(content: Content) -> some View {
        content
            .offset(
                x: direction.axis == .horizontal ? offsetValue : 0,
                y: direction.axis == .vertical ? offsetValue : 0
            )
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(animation, value: isVisible)
    }

    private var offsetValue: CGFloat {
        isVisible ? 0 : slideDistance * direction.offsetMultiplier
    }
}

// MARK: - View Extension

extension View {
    /// Applies a slide-in animation effect
    ///
    /// - Parameters:
    ///   - isVisible: Whether the view should be visible
    ///   - direction: The direction from which the view slides in
    ///   - slideDistance: The distance to slide (default uses AnimationConstants.errorSlideOffset)
    ///   - animation: The animation to use (default uses AnimationConstants.errorSpringAnimation)
    /// - Returns: A view with the slide-in animation applied
    func slideIn(
        isVisible: Bool,
        from direction: SlideDirection,
        distance slideDistance: CGFloat = AnimationConstants.errorSlideOffset,
        animation: Animation = AnimationConstants.errorSpringAnimation
    ) -> some View {
        modifier(
            SlideInModifier(
                isVisible: isVisible,
                direction: direction,
                slideDistance: slideDistance,
                animation: animation
            )
        )
    }
}
