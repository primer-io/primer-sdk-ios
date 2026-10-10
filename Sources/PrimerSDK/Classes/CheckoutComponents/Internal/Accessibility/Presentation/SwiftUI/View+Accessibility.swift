//
//  View+Accessibility.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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

  /// Before iOS 18 the value can't be switched on and off without rebuilding the field, so it is read with the label.
  private var label: String {
    if #available(iOS 18.0, *) { return config.label }
    return config.labelWithValue
  }

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
      .accessibilityLabel(label)
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
    // A branch that flips rebuilds the content, and a rebuilt text field loses its focus.
    if #available(iOS 18.0, *) {
      content.accessibilityHint(hint ?? "", isEnabled: hint?.isEmpty == false)
    } else if let hint, !hint.isEmpty {
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
    // An empty value would hide the field's own value, so it is switched off rather than set to "".
    if #available(iOS 18.0, *) {
      content.accessibilityValue(value ?? "", isEnabled: value?.isEmpty == false)
    } else {
      // Only a branch could apply it here, and a field's error flips that branch on every focus, so the label reads it.
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
