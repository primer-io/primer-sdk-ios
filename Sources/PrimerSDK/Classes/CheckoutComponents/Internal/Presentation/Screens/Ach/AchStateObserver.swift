//
//  AchStateObserver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class AchStateObserver: ObservableObject {
  @Published var achState: PrimerAchState = .init()
  @Published var showBankCollector: Bool = false

  private var stripeFlowCompleted: Bool = false
  private let scope: any PrimerAchScope
  private var observationTask: Task<Void, Never>?

  private var shouldShowBankCollector: Bool {
    achState.step == .bankAccountCollection && scope.bankCollectorViewController != nil && !stripeFlowCompleted
  }

  private var shouldHideBankCollector: Bool {
    achState.step != .bankAccountCollection && achState.step != .processing
  }

  init(scope: any PrimerAchScope) {
    self.scope = scope
  }

  deinit {
    observationTask?.cancel()
  }

  func startObserving() {
    guard observationTask == nil else { return }

    observationTask = Task { [self] in
      for await state in scope.state {
        if Task.isCancelled { break }

        achState = state

        if shouldShowBankCollector {
          showBankCollector = true
        } else if state.step == .mandateAcceptance {
          stripeFlowCompleted = true
        } else if shouldHideBankCollector {
          showBankCollector = false
        }
      }
    }
  }

  func stopObserving() {
    observationTask?.cancel()
    observationTask = nil
  }
}
