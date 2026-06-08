//
//  FlowScreenFactory.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Single source of truth that maps a ``CheckoutNavigationState`` to its SwiftUI screen.
///
/// Both the modal host (``CheckoutScopeObserver``) and the inline host (``InlineFlowHost``) render
/// through this factory, so flow screens (payment method, processing, success, failure) look and
/// behave identically regardless of how the checkout is embedded. The `isInlineFlow` flag tunes the
/// few places where inline embedding must differ (e.g. hiding the "choose other payment methods"
/// affordance on the failure screen).
@available(iOS 15.0, *)
@MainActor
struct FlowScreenFactory: LogReporter {
  let scope: any CheckoutScopeInternal
  let theme: PrimerCheckoutTheme
  let onCompletion: ((PrimerCheckoutState) -> Void)?
  let isInlineFlow: Bool

  @ViewBuilder
  func view(for state: CheckoutNavigationState) -> some View {
    switch state {
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
      SplashScreen()
    } else {
      EmptyView().onAppear {
        logger.debug(message: "[CheckoutComponents] Init screen disabled - skipping loading view")
      }
    }
  }

  @ViewBuilder
  private func makePaymentMethodSelectionView() -> some View {
    if let customPaymentSelection = scope.paymentMethodSelectionScreen {
      AnyView(customPaymentSelection(scope.paymentMethodSelection))
    } else {
      PaymentMethodSelectionScreen(
        scope: scope.paymentMethodSelection
      )
    }
  }

  private func makeVaultedPaymentMethodsView() -> some View {
    VaultedPaymentMethodsListScreen(
      vaultedPaymentMethods: scope.vaultedPaymentMethods,
      selectedVaultedPaymentMethod: scope.selectedVaultedPaymentMethod,
      onSelect: { method in
        scope.setSelectedVaultedPaymentMethod(method)
        scope.paymentMethodSelectionInternal.collapsePaymentMethods()
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

  private func makeDeleteConfirmationView(
    method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  ) -> some View {
    DeleteVaultedPaymentMethodConfirmationScreen(
      vaultedPaymentMethod: method,
      navigator: scope.checkoutNavigator,
      scope: scope.paymentMethodSelectionInternal
    )
  }

  private func makePaymentMethodView(type: String) -> some View {
    PaymentMethodScreen(
      paymentMethodType: type,
      checkoutScope: scope
    )
  }

  private func makeProcessingView() -> some View {
    DefaultLoadingScreen()
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
        Task { @MainActor in
          onCompletion?(scope.currentState)
        }
      }
    }
  }

  @ViewBuilder
  private func makeFailureView(error: PrimerError) -> some View {
    if scope.isErrorScreenEnabled {
      ErrorScreen(
        error: error,
        onRetry: {
          logger.info(message: "Error screen retry tapped")
          scope.retryPayment()
        },
        onChooseOtherPaymentMethods: showOtherMethodsAction
      )
    } else {
      EmptyView().onAppear {
        logger.debug(message: "[CheckoutComponents] Error screen disabled - auto-dismissing")
        Task { @MainActor in
          onCompletion?(scope.currentState)
        }
      }
    }
  }

  /// Inline embedding nulls the "choose other payment methods" affordance: the
  /// merchant owns method selection, so the inline failure sheet only offers retry.
  private var showOtherMethodsAction: (() -> Void)? {
    // Counts total methods (the failed one is still present), so >1 means at least one alternative exists.
    guard !isInlineFlow, scope.availablePaymentMethods.count > 1 else { return nil }
    return {
      logger.info(message: "Error screen choose other payment method tapped")
      scope.checkoutNavigator.handleOtherPaymentMethods()
    }
  }

  private func makeDismissedView() -> some View {
    VStack {
      Text(CheckoutComponentsStrings.dismissingMessage)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .onAppear {
      logger.info(message: "Checkout dismissed, calling completion callback")
      Task { @MainActor in
        onCompletion?(.dismissed)
      }
    }
  }
}
