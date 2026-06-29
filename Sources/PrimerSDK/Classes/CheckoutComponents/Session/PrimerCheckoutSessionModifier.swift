//
//  PrimerCheckoutSessionModifier.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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
private struct PrimerCheckoutSessionModifier: ViewModifier, LogReporter {

  @ObservedObject var session: PrimerCheckoutSession
  let onCompletion: ((PrimerCheckoutState) -> Void)?
  @Environment(\.colorScheme) private var colorScheme
  @StateObject private var designTokensManager = DesignTokensManager()

  func body(content: Content) -> some View {
    content
      .environment(\.primerCheckoutSession, session)
      .environment(\.primerCardFormSession, session.cardForm)
      .environment(\.primerSelectionSession, session.selection)
      // Mirror the managed path's CheckoutScopeObserver so inline composables behave identically:
      // the DI container resolves their services (without it, input fields render disabled
      // placeholders), the design tokens apply the merchant's theme (without them, a custom theme
      // is silently ignored inline), and the checkout scope is exposed for parity.
      .environment(\.diContainer, DIContainer.currentSync)
      .environment(\.designTokens, designTokensManager.tokens)
      .environment(\.primerCheckoutScope, session.internalScope)
      .overlay {
        if session.phase == .ready, let scope = session.internalScope {
          InlineFlowHost(scope: scope, theme: session.theme)
        }
      }
      .task {
        session.setCompletionHandler(onCompletion)
        await session.start()
      }
      .task {
        designTokensManager.applyTheme(session.theme)
        await loadDesignTokens(for: colorScheme)
      }
      .onChange(of: colorScheme) { newColorScheme in
        Task { await loadDesignTokens(for: newColorScheme) }
      }
      .onDisappear { session.cancel() }
  }

  private func loadDesignTokens(for colorScheme: ColorScheme) async {
    do {
      try await designTokensManager.fetchTokens(for: colorScheme)
    } catch {
      logger.error(message: "Failed to load design tokens: \(error)")
    }
  }
}
