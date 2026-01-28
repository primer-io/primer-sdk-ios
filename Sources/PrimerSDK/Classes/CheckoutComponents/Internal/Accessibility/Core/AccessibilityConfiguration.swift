//
//  AccessibilityConfiguration.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Container for all accessibility metadata associated with a UI component
struct AccessibilityConfiguration {

  let identifier: String
  let label: String
  let hint: String?

  /// Current value of element (e.g., "50%" for progress)
  let value: String?

  let traits: SwiftUI.AccessibilityTraits
  let isHidden: Bool

  /// Custom focus order priority (higher values appear first)
  let sortPriority: Int

  /// Create accessibility configuration
  /// - Parameters:
  ///   - identifier: Unique identifier for testing (must not be empty)
  ///   - label: Human-readable description (must not be empty)
  ///   - hint: Optional interaction guidance
  ///   - value: Optional current state value
  ///   - traits: SwiftUI semantic traits (e.g., .isButton, .isHeader)
  ///   - isHidden: Hide from VoiceOver (default: false)
  ///   - sortPriority: Custom focus order (default: 0)
  init(
    identifier: String,
    label: String,
    hint: String? = nil,
    value: String? = nil,
    traits: SwiftUI.AccessibilityTraits = [],
    isHidden: Bool = false,
    sortPriority: Int = 0
  ) {
    self.identifier = identifier
    self.label = label
    self.hint = hint
    self.value = value
    self.traits = traits
    self.isHidden = isHidden
    self.sortPriority = sortPriority
  }
}

extension AccessibilityConfiguration: Equatable {}
