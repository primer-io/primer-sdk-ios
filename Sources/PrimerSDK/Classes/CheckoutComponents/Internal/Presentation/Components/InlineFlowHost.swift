//
//  InlineFlowHost.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

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
/// 3DS, web-redirect, Apple Pay and PayPal already present at window level and need no host.
@available(iOS 15.0, *)
@MainActor
struct InlineFlowHost: View, LogReporter {
  let scope: any CheckoutScopeInternal

  private let theme: PrimerCheckoutTheme
  @State private var flowState: CheckoutNavigationState = .loading
  @State private var isPresenting = false
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
        .sheet(isPresented: $isPresenting, onDismiss: handleSheetDismiss) {
          makeSheetContent()
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

  private func makeSheetContent() -> some View {
    BackportedNavigationStack {
      FlowScreenFactory(
        scope: scope,
        theme: theme,
        onCompletion: { _ in dismissFlow() },
        isInlineFlow: true
      )
      .view(for: flowState)
    }
    .environment(\.diContainer, DIContainer.currentSync)
    .environment(\.designTokens, designTokensManager.tokens)
    .environment(\.primerCheckoutScope, scope)
    .environment(\.layoutDirection, RTLSupport.layoutDirection)
  }

  /// FLOW states need a follow-up screen presented in the sheet. NON-FLOW states are owned by the
  /// merchant's inline content, so the sheet stays dismissed.
  private func handle(_ state: CheckoutNavigationState) {
    switch state {
    case .paymentMethod, .processing, .success, .failure:
      flowState = state
      isPresenting = true
    case .loading,
      .paymentMethodSelection,
      .vaultedPaymentMethods,
      .deleteVaultedPaymentMethodConfirmation,
      .dismissed:
      isPresenting = false
    }
  }

  /// Programmatic dismissal once the success / failure screen finishes. The merchant `onCompletion`
  /// is already delivered via the session's state loop, so the host only closes the sheet here,
  /// leaving the merchant's inline content intact.
  private func dismissFlow() {
    isPresenting = false
  }

  /// User-driven dismissal of the sheet resets navigation so the next trigger re-presents cleanly.
  private func handleSheetDismiss() {
    scope.checkoutNavigator.navigateBack()
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
}
