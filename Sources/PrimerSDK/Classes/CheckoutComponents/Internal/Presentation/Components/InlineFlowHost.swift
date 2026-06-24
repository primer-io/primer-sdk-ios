//
//  InlineFlowHost.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Presents follow-up checkout screens in a sheet when a Primer composable is embedded inline via
/// `.primerCheckoutSession`.
///
/// Inline embedding mounts no navigation observer of its own, so when the merchant's inline view
/// (e.g. ``PrimerCardForm``) triggers a payment that needs a follow-up screen — a native APM
/// (Klarna / ACH / QR / form-redirect) or the shared processing / success / failure screens — the
/// scope's navigation state flips but nothing in the merchant's tree renders it. This host overlays
/// the merchant content, observes the scope's navigation stream, and presents those in-tree SwiftUI
/// screens via a `.sheet` (leaving the merchant content intact underneath).
///
/// Web-redirect, PayPal, Apple Pay and 3DS open their own window-level UI (e.g.
/// `ASWebAuthenticationSession`); the host still presents the in-tree payment-method screen that
/// launches it.
@available(iOS 15.0, *)
@MainActor
struct InlineFlowHost: View, LogReporter {
  let scope: any CheckoutScopeInternal

  private let theme: PrimerCheckoutTheme
  @State private var sheetItem: FlowSheetItem?
  @Environment(\.bridgeController) private var bridgeController
  @StateObject private var designTokensManager = DesignTokensManager()
  @Environment(\.colorScheme) private var colorScheme

  init(scope: any CheckoutScopeInternal, theme: PrimerCheckoutTheme = PrimerCheckoutTheme()) {
    self.scope = scope
    self.theme = theme
  }

  var body: some View {
    // In a modal context (`PrimerCheckout`) the CheckoutScopeObserver owns presentation — no-op
    // here to avoid double-presenting the same flow screens.
    if bridgeController == nil {
      Color.clear
        .sheet(item: $sheetItem, onDismiss: handleSheetDismiss) { item in
          makeSheetContent(for: item.navigationState)
        }
        .task {
          for await newState in scope.navigationStateStream {
            handle(newState)
          }
        }
        .task {
          designTokensManager.applyTheme(theme)
          await loadDesignTokens(for: colorScheme)
        }
        .onChange(of: colorScheme) { newColorScheme in
          Task { await loadDesignTokens(for: newColorScheme) }
        }
    }
  }

  private func makeSheetContent(for state: CheckoutNavigationState) -> some View {
    BackportedNavigationStack {
      FlowScreenFactory(
        scope: scope,
        theme: theme,
        onCompletion: { _ in dismissFlow() },
        isInlineFlow: true
      )
      .view(for: state)
    }
    .environment(\.diContainer, DIContainer.currentSync)
    .environment(\.designTokens, designTokensManager.tokens)
    .environment(\.primerCheckoutScope, scope)
    .environment(\.layoutDirection, RTLSupport.layoutDirection)
  }

  /// FLOW states need a follow-up screen presented in the sheet. NON-FLOW states are owned by the
  /// merchant's inline content, so the sheet stays dismissed. `sheetItem` is the single source of
  /// truth — driving `.sheet(item:)` keeps presentation and content in lockstep, so the first
  /// selection never lands on a stale loading splash.
  private func handle(_ state: CheckoutNavigationState) {
    sheetItem = state.presentsInlineFlowSheet ? FlowSheetItem(navigationState: state) : nil
  }

  /// Programmatic dismissal once the success / failure screen finishes. The merchant `onCompletion`
  /// is already delivered via the session's state loop, so the host only closes the sheet here,
  /// leaving the merchant's inline content intact.
  private func dismissFlow() {
    sheetItem = nil
  }

  /// Any sheet dismissal (swipe, back, or programmatic) returns the scope to the merchant's embedded
  /// list and resets the active method's one-shot start guard, so the next selection re-presents
  /// cleanly. Modeling this as a coordinator stack-pop double-popped the stack (the screen's back
  /// already pops), which emptied it and left "back" doing nothing.
  private func handleSheetDismiss() {
    scope.cancelActivePaymentMethod(returnToSelection: true)
  }

  private func loadDesignTokens(for colorScheme: ColorScheme) async {
    logger.info(
      message: "Loading design tokens for color scheme: \(colorScheme == .dark ? "dark" : "light")")
    do {
      try await designTokensManager.fetchTokens(for: colorScheme)
      logger.info(message: "Design tokens loaded successfully")
    } catch {
      logger.error(message: "Failed to load design tokens: \(error)")
    }
  }

  /// Single source of truth for the inline sheet. The `id` is stable so the one presentation lives
  /// across the in-sheet flow lifecycle (paymentMethod → processing → success / failure): content
  /// swaps in place instead of dismissing and re-presenting on every transition.
  private struct FlowSheetItem: Identifiable {
    let navigationState: CheckoutNavigationState
    let id = "inline-flow"
  }
}
