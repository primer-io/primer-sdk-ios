//
//  ProgrammaticFieldValue.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Mirrors a programmatic field write back into the input view the customer sees.
///
/// Each input view keeps its own `@State` copy of the text so the UIKit text fields can format and
/// validate keystroke by keystroke, which leaves the binding to the scope one-way. A merchant calling
/// `PrimerCardFormSession.updateCardholderName(_:)` changed the form data but never the visible field.
///
/// The adopted value is re-validated too, otherwise a prefilled field would leave the submit button
/// disabled until the customer focused and left it.
///
/// Not applicable to `.cardNumber` and `.cvv`: the scope deliberately hands back a masked PAN and an
/// empty CVV, so there is no value to mirror.
@available(iOS 15.0, *)
struct ProgrammaticFieldValue: ViewModifier {
  let field: PrimerInputElementType
  let scope: (any CardFormFieldScopeInternal)?

  @Binding var text: String
  @Binding var isFocused: Bool

  @Environment(\.diContainer) private var container
  @State private var observationTask: Task<Void, Never>?

  func body(content: Content) -> some View {
    content
      .onAppear(perform: observeScopeValue)
      .onDisappear {
        observationTask?.cancel()
        observationTask = nil
      }
  }

  private func observeScopeValue() {
    // `.cardNumber` and `.cvv` are deliberately unreadable from the scope, so mirroring them would put
    // a masked PAN or an empty string where the customer's own input was.
    guard let scope, field != .cardNumber, field != .cvv else { return }

    observationTask?.cancel()
    observationTask = Task { @MainActor in
      // The stream replays the current state on subscription, so a write that landed before the field
      // appeared arrives with the first element rather than needing separate seeding.
      for await _ in scope.state {
        let value = scope.getFieldValue(field)
        // Never fight the keyboard: while the field holds focus, its own text is the source of truth.
        guard !isFocused, value != text else { continue }
        text = value
        revalidate(value, in: scope)
      }
    }
  }

  /// Marks the adopted value valid or not, without surfacing an error message — the customer has not
  /// typed anything they could be told off about.
  private func revalidate(_ value: String, in scope: any CardFormFieldScopeInternal) {
    guard let container,
      let validationService = try? container.resolveSync(ValidationService.self)
    else { return }

    scope.updateValidationStateIfNeeded(
      for: field,
      isValid: validationService.validateField(type: field, value: value).isValid
    )
  }
}

@available(iOS 15.0, *)
extension View {
  /// Keeps `text` in step with programmatic writes to `field`. See ``ProgrammaticFieldValue``.
  func programmaticValue(
    _ field: PrimerInputElementType,
    from scope: (any CardFormFieldScopeInternal)?,
    text: Binding<String>,
    isFocused: Binding<Bool>
  ) -> some View {
    modifier(
      ProgrammaticFieldValue(field: field, scope: scope, text: text, isFocused: isFocused)
    )
  }
}
