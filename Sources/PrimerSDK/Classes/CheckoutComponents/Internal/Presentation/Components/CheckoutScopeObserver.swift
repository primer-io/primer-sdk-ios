//
//  CheckoutScopeObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CheckoutScopeObserver: View, LogReporter {
  private let scope: DefaultCheckoutScope
  private let theme: PrimerCheckoutTheme
  private let onCompletion: ((PrimerCheckoutState) -> Void)?
  @State private var navigationState: DefaultCheckoutScope.NavigationState = .loading
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.bridgeController) private var bridgeController
  @StateObject private var designTokensManager = DesignTokensManager()

  init(
    scope: DefaultCheckoutScope,
    theme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    onCompletion: ((PrimerCheckoutState) -> Void)?
  ) {
    self.scope = scope
    self.theme = theme
    self.onCompletion = onCompletion
  }

  var body: some View {
    if bridgeController != nil {
      makeContentView()
        .background(CheckoutColors.background(tokens: designTokensManager.tokens))
    } else {
      BackportedNavigationStack(content: makeContentView)
      .background(CheckoutColors.background(tokens: designTokensManager.tokens))
    }
  }

  private func makeContentView() -> some View {
    VStack(spacing: 0) {
      getCurrentView()
        .animation(.easeInOut(duration: 0.3), value: navigationState)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .environmentObject(scope)
    .environment(\.diContainer, DIContainer.currentSync)
    .environment(\.designTokens, designTokensManager.tokens)
    .environment(\.primerCheckoutScope, scope)
    .onReceive(scope.$navigationState) { newState in
      navigationState = newState
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

  @ViewBuilder
  private func getCurrentView() -> some View {
    switch navigationState {
    case .loading:
      makeLoadingView()
    case .paymentMethodSelection:
      makePaymentMethodSelectionView()
    case .vaultedPaymentMethods:
      makeVaultedPaymentMethodsView()
    case let .deleteVaultedPaymentMethodConfirmation(method):
      makeDeleteConfirmationView(method: method)
    case let .paymentMethod(paymentMethodType):
      makePaymentMethodView(type: paymentMethodType)
    case .processing:
      makeProcessingView()
    case let .success(result):
      makeSuccessView(result: result)
    case let .failure(error):
      makeFailureView(error: error)
    case .dismissed:
      makeDismissedView()
    }
  }

  @ViewBuilder
  private func makeLoadingView() -> some View {
    if scope.isInitScreenEnabled {
      if let customSplash = scope.splashScreen {
        AnyView(customSplash())
      } else {
        SplashScreen()
      }
    } else {
      EmptyView().onAppear {
        logger.debug(message: "[CheckoutComponents] Init screen disabled - skipping loading view")
      }
    }
  }

  @ViewBuilder
  private func makePaymentMethodSelectionView() -> some View {
    if let customPaymentMethodSelectionScreen = scope.paymentMethodSelection.screen {
      AnyView(customPaymentMethodSelectionScreen(scope.paymentMethodSelection))
    } else if let customPaymentSelection = scope.paymentMethodSelectionScreen {
      AnyView(customPaymentSelection(scope.paymentMethodSelection))
    } else {
      PaymentMethodSelectionScreen(
        scope: scope.paymentMethodSelection
      )
    }
  }

  @ViewBuilder
  private func makeVaultedPaymentMethodsView() -> some View {
    VaultedPaymentMethodsListScreen(
      vaultedPaymentMethods: scope.vaultedPaymentMethods,
      selectedVaultedPaymentMethod: scope.selectedVaultedPaymentMethod,
      onSelect: { method in
        scope.setSelectedVaultedPaymentMethod(method)
        if let selectionScope = scope.paymentMethodSelection
          as? DefaultPaymentMethodSelectionScope {
          selectionScope.collapsePaymentMethods()
        }
        scope.checkoutNavigator.navigateBack()
      },
      onBack: {
        scope.checkoutNavigator.navigateBack()
      },
      onDeleteTapped: { method in
        scope.updateNavigationState(.deleteVaultedPaymentMethodConfirmation(method))
      }
    )
  }

  @ViewBuilder
  private func makeDeleteConfirmationView(
    method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  ) -> some View {
    if let selectionScope = scope.paymentMethodSelection as? DefaultPaymentMethodSelectionScope {
      DeleteVaultedPaymentMethodConfirmationScreen(
        vaultedPaymentMethod: method,
        navigator: scope.checkoutNavigator,
        scope: selectionScope
      )
    } else {
      EmptyView().onAppear {
        logger.error(
          message: "Cannot cast paymentMethodSelection to DefaultPaymentMethodSelectionScope")
        scope.checkoutNavigator.navigateBack()
      }
    }
  }

  @ViewBuilder
  private func makePaymentMethodView(type: String) -> some View {
    PaymentMethodScreen(
      paymentMethodType: type,
      checkoutScope: scope
    )
  }

  @ViewBuilder
  private func makeProcessingView() -> some View {
    if let customLoading = scope.loadingScreen {
      AnyView(customLoading())
    } else {
      DefaultLoadingScreen()
    }
  }

  @ViewBuilder
  private func makeSuccessView(result: PaymentResult) -> some View {
    if scope.isSuccessScreenEnabled {
      if let customSuccess = scope.successScreen {
        AnyView(customSuccess(result))
      } else {
        SuccessScreen(result: result) {
          logger.info(message: "Success screen auto-dismiss, calling completion callback")
          onCompletion?(scope.currentState)
        }
      }
    } else {
      EmptyView().onAppear {
        logger.debug(message: "[CheckoutComponents] Success screen disabled - auto-dismissing")
        DispatchQueue.main.async {
          onCompletion?(scope.currentState)
        }
      }
    }
  }

  @ViewBuilder
  private func makeFailureView(error: PrimerError) -> some View {
    if scope.isErrorScreenEnabled {
      if let customError = scope.errorScreen {
        AnyView(customError(error.localizedDescription))
      } else {
        ErrorScreen(
          error: error,
          onRetry: {
            logger.info(message: "Error screen retry tapped")
            scope.retryPayment()
          },
          onChooseOtherPaymentMethods: scope.availablePaymentMethods.count > 1 ? {
            logger.info(message: "Error screen choose other payment method tapped")
            scope.checkoutNavigator.handleOtherPaymentMethods()
          } : nil
        )
      }
    } else {
      EmptyView().onAppear {
        logger.debug(message: "[CheckoutComponents] Error screen disabled - auto-dismissing")
        DispatchQueue.main.async {
          onCompletion?(scope.currentState)
        }
      }
    }
  }

  @ViewBuilder
  private func makeDismissedView() -> some View {
    VStack {
      Text(CheckoutComponentsStrings.dismissingMessage)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .onAppear {
      logger.info(message: "Checkout dismissed, calling completion callback")
      DispatchQueue.main.async {
        onCompletion?(.dismissed)
      }
    }
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
