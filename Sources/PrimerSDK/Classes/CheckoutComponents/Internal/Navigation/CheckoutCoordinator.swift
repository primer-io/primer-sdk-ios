//
//  CheckoutCoordinator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class CheckoutCoordinator: ObservableObject, LogReporter {

  @Published var navigationStack: [CheckoutRoute] = []
  private(set) var lastPaymentMethodRoute: CheckoutRoute?

  var currentRoute: CheckoutRoute {
    navigationStack.last ?? .splash
  }

  func navigate(to route: CheckoutRoute) {
    guard currentRoute != route else { return }

    let previousRoute = currentRoute

    if case .paymentMethod = previousRoute {
      lastPaymentMethodRoute = previousRoute
    }

    switch route.navigationBehavior {
    case .push:
      navigationStack.append(route)
    case .reset:
      navigationStack = route == .splash ? [] : [route]
    case .replace:
      if !navigationStack.isEmpty {
        navigationStack[navigationStack.count - 1] = route
      } else {
        navigationStack = [route]
      }
    }

    logger.debug(message: "[CheckoutCoordinator] \(previousRoute) -> \(route)")
  }

  func goBack() {
    guard !navigationStack.isEmpty else { return }
    navigationStack.removeLast()
  }

  func dismiss() {
    navigationStack = []
  }

  func handlePaymentFailure(_ error: PrimerError) {
    navigate(to: .failure(error))
  }
}
