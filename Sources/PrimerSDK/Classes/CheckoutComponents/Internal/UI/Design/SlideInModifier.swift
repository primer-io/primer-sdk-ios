//
//  SlideInModifier.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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
      .horizontal
    case .top, .bottom:
      .vertical
    }
  }

  var offsetMultiplier: CGFloat {
    switch self {
    case .leading, .top:
      -1
    case .trailing, .bottom:
      1
    }
  }
}

struct SlideInModifier: ViewModifier {
  let isVisible: Bool
  let direction: SlideDirection
  let slideDistance: CGFloat
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

extension View {
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
