//
//  PrimerPaymentMethods.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// The payment-method list, composed from a header, per-method row, and empty-state slot.
///
/// Resolves its ``PrimerSelectionSession`` from the environment (provided by
/// `.primerCheckoutSession(_:)`). Mirrors Android v3's `PrimerPaymentMethods`.
///
/// ```swift
/// PrimerPaymentMethods(method: { method, onSelect in
///   MyBrandRow(name: method.name, action: onSelect)
/// })
/// ```
@available(iOS 15.0, *)
public struct PrimerPaymentMethods<Header: View, Method: View, Empty: View>: View {

  @Environment(\.primerSelectionSession) private var session

  private let header: (PrimerSelectionSession) -> Header
  private let method: (CheckoutPaymentMethod, @escaping () -> Void) -> Method
  private let emptyState: (PrimerSelectionSession) -> Empty

  public init(
    @ViewBuilder header: @escaping (PrimerSelectionSession) -> Header
      = { PaymentMethodsDefaults.header($0) },
    @ViewBuilder method: @escaping (CheckoutPaymentMethod, @escaping () -> Void) -> Method
      = { PaymentMethodsDefaults.method($0, onSelect: $1) },
    @ViewBuilder emptyState: @escaping (PrimerSelectionSession) -> Empty
      = { PaymentMethodsDefaults.emptyState($0) }
  ) {
    self.header = header
    self.method = method
    self.emptyState = emptyState
  }

  public var body: some View {
    if let session {
      Bound(session: session, header: header, method: method, emptyState: emptyState)
    } else {
      PaymentMethodsDefaults.unavailable()
    }
  }

  private struct Bound: View {
    @ObservedObject var session: PrimerSelectionSession
    let header: (PrimerSelectionSession) -> Header
    let method: (CheckoutPaymentMethod, @escaping () -> Void) -> Method
    let emptyState: (PrimerSelectionSession) -> Empty
    @Environment(\.designTokens) private var tokens

    var body: some View {
      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        AnyView(header(session))
        if session.state.paymentMethods.isEmpty {
          AnyView(emptyState(session))
        } else {
          ForEach(session.state.paymentMethods) { paymentMethod in
            AnyView(method(paymentMethod) { session.select(paymentMethod) })
          }
        }
      }
    }
  }
}
