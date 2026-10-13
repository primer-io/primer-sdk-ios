//
//  View+FieldTapTarget.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension View {
  /// A SwiftUI text field is only as tall as its text, so the rest of its box would ignore a tap.
  func focusesFieldOnTap(_ focus: @escaping () -> Void) -> some View {
    modifier(FieldTapTarget(focus: focus))
  }
}

@available(iOS 15.0, *)
private struct FieldTapTarget: ViewModifier {
  let focus: () -> Void

  @Environment(\.isEnabled) private var isEnabled

  func body(content: Content) -> some View {
    // Behind the field rather than on it, so the field's own taps still move the caret.
    content.background(
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { if isEnabled { focus() } }
        .accessibilityHidden(true)
    )
  }
}
