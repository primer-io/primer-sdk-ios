//
//  AnimationConstants.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

/// Animation specifications matching Figma design system
struct AnimationConstants {

  // MARK: - Duration

  static let focusDuration: Double = 0.2
  static let errorDuration: Double = 0.2
  static let standardDuration: Double = 0.2
  static let autoDismissDelay: Double = 3.0

  // MARK: - Animation Curves

  static let standardCurve: Animation = .easeInOut(duration: standardDuration)
  static let focusAnimation: Animation = .easeInOut(duration: focusDuration)
  static let errorAnimation: Animation = .easeInOut(duration: errorDuration)
  static let errorSpringAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
  static let successSpringAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.6)

  // MARK: - Slide Offsets

  static let errorSlideOffset: CGFloat = 10
}
