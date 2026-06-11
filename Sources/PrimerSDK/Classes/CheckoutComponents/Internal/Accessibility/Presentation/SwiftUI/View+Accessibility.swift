//
//  View+Accessibility.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension View {

  /// Applies comprehensive accessibility configuration to a SwiftUI view
  /// - Parameter config: AccessibilityConfiguration containing all accessibility metadata
  /// - Returns: Modified view with accessibility properties applied
  ///
  /// Example usage:
  /// ```swift
  /// Button("Submit") { }
  ///     .accessibility(config: AccessibilityConfiguration(
  ///         identifier: "checkout_submit_button",
  ///         label: "Submit payment",
  ///         hint: "Double-tap to submit payment",
  ///         traits: [.isButton]
  ///     ))
  /// ```
  func accessibility(config: AccessibilityConfiguration, combinesChildren: Bool = true) -> some View {
    modifier(
      ConditionalAccessibilityElement(
        config: config,
        combinesChildren: combinesChildren
      )
    )
  }
}

@available(iOS 15.0, *)
private struct ConditionalAccessibilityElement: ViewModifier {
  let config: AccessibilityConfiguration
  let combinesChildren: Bool

  @ViewBuilder
  func body(content: Content) -> some View {
    if combinesChildren {
      applyMetadata(to: content.accessibilityElement(children: .ignore))
    } else {
      applyMetadata(to: content)
    }
  }

  private func applyMetadata(to content: some View) -> some View {
    content
      .accessibilityIdentifier(config.identifier)
      .accessibilityLabel(config.label)
      .modifier(ConditionalAccessibilityHint(hint: config.hint))
      .modifier(ConditionalAccessibilityValue(value: config.value))
      .accessibilityAddTraits(config.traits)
      .accessibilityHidden(config.isHidden)
      .modifier(ConditionalAccessibilitySortPriority(sortPriority: config.sortPriority))
  }
}

@available(iOS 15.0, *)
private struct ConditionalAccessibilityHint: ViewModifier {
  let hint: String?

  func body(content: Content) -> some View {
    if let hint, !hint.isEmpty {
      content.accessibilityHint(hint)
    } else {
      content
    }
  }
}

@available(iOS 15.0, *)
private struct ConditionalAccessibilityValue: ViewModifier {
  let value: String?

  func body(content: Content) -> some View {
    if let value, !value.isEmpty {
      content.accessibilityValue(value)
    } else {
      content
    }
  }
}

@available(iOS 15.0, *)
private struct ConditionalAccessibilitySortPriority: ViewModifier {
  let sortPriority: Int

  func body(content: Content) -> some View {
    if sortPriority != 0 {
      content.accessibilitySortPriority(Double(sortPriority))
    } else {
      content
    }
  }
}
