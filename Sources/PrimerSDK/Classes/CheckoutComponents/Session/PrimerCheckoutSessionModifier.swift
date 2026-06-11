//
//  PrimerCheckoutSessionModifier.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
public extension View {

  /// Wires a ``PrimerCheckoutSession`` into the SwiftUI environment, bootstraps it on appear, and
  /// tears it down on disappear. Apply once around any Primer composable views — whether presented
  /// modally via ``PrimerCheckout`` or embedded inline in the merchant's own layout.
  ///
  /// ```swift
  /// @StateObject private var session = PrimerCheckoutSession(clientToken: token)
  ///
  /// ScrollView {
  ///   PrimerCardForm()
  /// }
  /// .primerCheckoutSession(session) { state in handle(state) }
  /// ```
  func primerCheckoutSession(
    _ session: PrimerCheckoutSession,
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  ) -> some View {
    modifier(PrimerCheckoutSessionModifier(session: session, onCompletion: onCompletion))
  }
}

@available(iOS 15.0, *)
private struct PrimerCheckoutSessionModifier: ViewModifier {

  @ObservedObject var session: PrimerCheckoutSession
  let onCompletion: ((PrimerCheckoutState) -> Void)?

  func body(content: Content) -> some View {
    content
      .environment(\.primerCheckoutSession, session)
      .environment(\.primerCardFormSession, session.cardForm)
      .environment(\.primerSelectionSession, session.selection)
      .overlay {
        if session.phase == .ready, let scope = session.internalScope {
          InlineFlowHost(scope: scope, theme: session.theme)
        }
      }
      .task {
        session.setCompletionHandler(onCompletion)
        await session.start()
      }
      .onDisappear { session.cancel() }
  }
}
