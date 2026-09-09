//
//  CheckoutScopeObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct CheckoutScopeObserver: View, LogReporter {
  private let scope: any CheckoutScopeInternal
  private let theme: PrimerCheckoutTheme
  private let onCompletion: ((PrimerCheckoutState) -> Void)?
  @State private var navigationState: CheckoutNavigationState = .loading
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.bridgeController) private var bridgeController
  @StateObject private var designTokensManager = DesignTokensManager()

  init(
    scope: any CheckoutScopeInternal,
    theme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    onCompletion: ((PrimerCheckoutState) -> Void)?
  ) {
    self.scope = scope
    self.theme = theme
    self.onCompletion = onCompletion
  }

  var body: some View {
    makeWrappedContent()
      .background(CheckoutColors.background(tokens: designTokensManager.tokens))
  }

  @ViewBuilder
  private func makeWrappedContent() -> some View {
    if bridgeController != nil {
      makeContentView()
    } else {
      BackportedNavigationStack(content: makeContentView)
    }
  }

  private func makeContentView() -> some View {
    VStack(spacing: 0) {
      getCurrentView()
        .animation(.easeInOut(duration: 0.3), value: navigationState)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .environment(\.diContainer, DIContainer.currentSync)
    .environment(\.designTokens, designTokensManager.tokens)
    .environment(\.primerCheckoutScope, scope)
    .task {
      for await newState in scope.navigationStateStream {
        navigationState = newState
      }
    }
    .onAppear {
      Task {
        await setupDesignTokens()
      }
    }
    .onChange(of: colorScheme) { newColorScheme in
      Task {
        await loadDesignTokens(for: newColorScheme)
      }
    }
  }

  private func getCurrentView() -> some View {
    FlowScreenFactory(
      scope: scope,
      theme: theme,
      onCompletion: onCompletion,
      isInlineFlow: false
    )
    .view(for: navigationState)
  }

  private func setupDesignTokens() async {
    logger.info(message: "Setting up design tokens...")

    // Apply merchant theme overrides
    designTokensManager.applyTheme(theme)

    await loadDesignTokens(for: colorScheme)
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
