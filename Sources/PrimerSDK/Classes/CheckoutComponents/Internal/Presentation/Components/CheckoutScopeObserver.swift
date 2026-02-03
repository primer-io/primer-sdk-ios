//
//  CheckoutScopeObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity function_body_length
// TODO: Refactor CheckoutScopeObserver to reduce complexity (currently 21, max 12) and function length (101 lines, max 100)
//
//  CheckoutScopeObserver.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Checkout Scope Observer

/// Wrapper view that properly observes the DefaultCheckoutScope as an ObservableObject
@available(iOS 15.0, *)
struct CheckoutScopeObserver: View, LogReporter {
  @ObservedObject private var scope: DefaultCheckoutScope
  private let theme: PrimerCheckoutTheme
  private let onCompletion: ((PrimerCheckoutState) -> Void)?
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.bridgeController) private var bridgeController

  // Design tokens state
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
    Group {
      if bridgeController != nil {
        makeContentView()  // NO navigation wrapper - for UIKit bridge (prevents sizing issues)
      } else {
        // Pure SwiftUI - use BackportedNavigationStack for iOS 16+ NavigationStack
        BackportedNavigationStack {
          makeContentView()
        }
      }
    }
    .background(CheckoutColors.background(tokens: designTokensManager.tokens))
  }

  private func makeContentView() -> some View {
    VStack(spacing: 0) {
      // MARK: - Navigation Content
      // Simple fade transition between screens
      // TODO: Future improvements could include:
      // - Respect UIAccessibility.isReduceMotionEnabled for users with motion sensitivity
      // - Add directional transitions (slide left/right) based on navigation direction
      // - Implement custom per-route transitions (e.g., scale for success screen)
      // - Add interactive gesture-based navigation
      getCurrentView()
        .animation(.easeInOut(duration: 0.3), value: scope.navigationState)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .environmentObject(scope)
    .environment(\.diContainer, DIContainer.currentSync)
    .environment(\.designTokens, designTokensManager.tokens)
    .environment(\.primerCheckoutScope, scope)
    .onAppear {
      Task {
        await setupDesignTokens()
      }
    }
    .onChange(of: colorScheme) { newColorScheme in
      // Reload design tokens when color scheme changes
      Task {
        await loadDesignTokens(for: newColorScheme)
      }
    }
  }

  // MARK: - View Builder

  private func getCurrentView() -> AnyView {
    switch scope.navigationState {
    case .loading:
      // Check if init screen is enabled in settings (UI Options integration)
      if scope.isInitScreenEnabled {
        if let customSplash = scope.splashScreen {
          return AnyView(customSplash())
        } else {
          return AnyView(SplashScreen())
        }
      } else {
        // Skip loading screen, show empty view or proceed to next state
        logger.debug(message: "⏭️ [CheckoutComponents] Init screen disabled - skipping loading view")
        return AnyView(EmptyView())
      }

    case .paymentMethodSelection:
      // Check if the payment method selection scope has a custom screen
      if let customPaymentMethodSelectionScreen = scope.paymentMethodSelection.screen {
        return AnyView(customPaymentMethodSelectionScreen(scope.paymentMethodSelection))
      }
      // Then check if the checkout scope has a custom payment selection screen (legacy)
      else if let customPaymentSelection = scope.paymentMethodSelectionScreen {
        return AnyView(customPaymentSelection(scope.paymentMethodSelection))
      } else {
        return AnyView(
          PaymentMethodSelectionScreen(
            scope: scope.paymentMethodSelection
          ))
      }

    case .vaultedPaymentMethods:
      return AnyView(
        VaultedPaymentMethodsListScreen(
          vaultedPaymentMethods: scope.vaultedPaymentMethods,
          selectedVaultedPaymentMethod: scope.selectedVaultedPaymentMethod,
          onSelect: { method in
            scope.setSelectedVaultedPaymentMethod(method)
            if let selectionScope = scope.paymentMethodSelection
              as? DefaultPaymentMethodSelectionScope
            {
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
        ))

    case let .deleteVaultedPaymentMethodConfirmation(method):
      guard let selectionScope = scope.paymentMethodSelection as? DefaultPaymentMethodSelectionScope
      else {
        logger.error(
          message: "Cannot cast paymentMethodSelection to DefaultPaymentMethodSelectionScope")
        scope.checkoutNavigator.navigateBack()
        return AnyView(EmptyView())
      }
      return AnyView(
        DeleteVaultedPaymentMethodConfirmationScreen(
          vaultedPaymentMethod: method,
          navigator: scope.checkoutNavigator,
          scope: selectionScope
        ))

    case let .paymentMethod(paymentMethodType):
      // Handle all payment method types using truly unified dynamic approach
      return AnyView(
        PaymentMethodScreen(
          paymentMethodType: paymentMethodType,
          checkoutScope: scope
        ))

    case .processing:
      // Show loading screen during payment processing
      if let customLoading = scope.loading {
        return AnyView(customLoading())
      } else {
        return AnyView(DefaultLoadingScreen())
      }

    case let .success(result):
      // Check if success screen is enabled in settings (UI Options integration)
      if scope.isSuccessScreenEnabled {
        if let customSuccess = scope.successScreen {
          return AnyView(customSuccess(result))
        } else {
          return AnyView(
            SuccessScreen(result: result) {
              logger.info(message: "Success screen auto-dismiss, calling completion callback")
              onCompletion?(scope.currentState)
            })
        }
      } else {
        // Skip success screen, immediately call completion (UI Options integration)
        logger.debug(message: "⏭️ [CheckoutComponents] Success screen disabled - auto-dismissing")
        return AnyView(
          EmptyView().onAppear {
            DispatchQueue.main.async {
              onCompletion?(scope.currentState)
            }
          })
      }

    case let .failure(error):
      // Check if error screen is enabled in settings (UI Options integration)
      if scope.isErrorScreenEnabled {
        if let customError = scope.errorScreen {
          return AnyView(customError(error.localizedDescription))
        } else {
          return AnyView(
            ErrorScreen(
              error: error,
              onRetry: {
                logger.info(message: "Error screen retry tapped")
                scope.retryPayment()
              },
              onChooseOtherPaymentMethods: {
                logger.info(message: "Error screen choose other payment method tapped")
                scope.checkoutNavigator.handleOtherPaymentMethods()
              }
            ))
        }
      } else {
        // Skip error screen, immediately call completion (UI Options integration)
        logger.debug(message: "⏭️ [CheckoutComponents] Error screen disabled - auto-dismissing")
        return AnyView(
          EmptyView().onAppear {
            DispatchQueue.main.async {
              onCompletion?(scope.currentState)
            }
          })
      }

    case .dismissed:
      // Handle dismissal - call completion callback to properly dismiss SwiftUI sheets
      return AnyView(
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
        })
    }
  }

  // MARK: - Design Token Management

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
// swiftlint:enable cyclomatic_complexity function_body_length
