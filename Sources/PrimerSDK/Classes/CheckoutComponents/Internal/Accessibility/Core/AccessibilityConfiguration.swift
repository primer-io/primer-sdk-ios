//
//  AccessibilityConfiguration.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

struct AccessibilityConfiguration {

  let identifier: String
  let label: String
  let hint: String?
  let value: String?
  let traits: SwiftUI.AccessibilityTraits
  let isHidden: Bool
  let sortPriority: Int

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
