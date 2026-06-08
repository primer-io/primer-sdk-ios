//
//  PrimerCardFormSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Observable wrapper around a card-form scope.
///
/// Bridges the scope's `AsyncStream<PrimerCardFormState>` into a `@Published` property exactly once,
/// so SwiftUI views observe via `@ObservedObject` without each opening its own stream. Slot closures
/// receive this session: read `state` for rendering, call into `scope` for mutations and submission.
@available(iOS 15.0, *)
@MainActor
public final class PrimerCardFormSession: ObservableObject {

  /// The latest card-form state, bridged from `scope.state`.
  @Published public private(set) var state: PrimerCardFormState

  /// The full card-form behavior surface (field updates, submit, network selection).
  let scope: any PrimerCardFormScope

  private let fieldScope: (any CardFormFieldScopeInternal)?
  private var observationTask: Task<Void, Never>?

  init(scope: any PrimerCardFormScope) {
    self.scope = scope
    fieldScope = scope as? any CardFormFieldScopeInternal
    state = fieldScope?.currentState ?? PrimerCardFormState()
    if fieldScope == nil {
      PrimerLogging.shared.logger.warn(
        message: "[PrimerCardFormSession] scope does not conform to CardFormFieldScopeInternal; "
          + "field updates and network selection will be inert."
      )
    }
    scope.start()
    observationTask = Task { @MainActor [weak self] in
      for await newState in scope.state {
        self?.state = newState
      }
    }
  }

  deinit {
    observationTask?.cancel()
  }

  // MARK: - Field Updates

  public func updateCardNumber(_ value: String) { fieldScope?.updateCardNumber(value) }
  public func updateCvv(_ value: String) { fieldScope?.updateCvv(value) }
  public func updateExpiryDate(_ value: String) { fieldScope?.updateExpiryDate(value) }
  public func updateCardholderName(_ value: String) { fieldScope?.updateCardholderName(value) }
  public func updatePostalCode(_ value: String) { fieldScope?.updatePostalCode(value) }
  public func updateCountryCode(_ value: String) { fieldScope?.updateCountryCode(value) }
  public func updateCity(_ value: String) { fieldScope?.updateCity(value) }
  public func updateState(_ value: String) { fieldScope?.updateState(value) }
  public func updateAddressLine1(_ value: String) { fieldScope?.updateAddressLine1(value) }
  public func updateAddressLine2(_ value: String) { fieldScope?.updateAddressLine2(value) }
  public func updatePhoneNumber(_ value: String) { fieldScope?.updatePhoneNumber(value) }
  public func updateFirstName(_ value: String) { fieldScope?.updateFirstName(value) }
  public func updateLastName(_ value: String) { fieldScope?.updateLastName(value) }

  /// Selects a co-badged card network. Mirrors Android's `selectCardNetwork(network:)`.
  public func selectCardNetwork(_ network: PrimerCardNetwork) {
    fieldScope?.updateSelectedCardNetwork(network.network.rawValue)
  }

  // MARK: - Lifecycle

  public func submit() { scope.submit() }
  public func cancel() { scope.cancel() }
}
