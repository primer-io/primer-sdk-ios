//
//  PrimerSessionEnvironment.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

// Environment keys carrying the observable session objects. Distinct from the scope-carrying keys in
// `PrimerScopeEnvironmentKeys.swift`: those expose raw scopes for ad-hoc access, these expose the
// observable sessions the composable views bind to.

@available(iOS 15.0, *)
private struct PrimerCheckoutSessionKey: EnvironmentKey {
  static let defaultValue: PrimerCheckoutSession? = nil
}

@available(iOS 15.0, *)
private struct PrimerCardFormSessionKey: EnvironmentKey {
  static let defaultValue: PrimerCardFormSession? = nil
}

@available(iOS 15.0, *)
private struct PrimerSelectionSessionKey: EnvironmentKey {
  static let defaultValue: PrimerSelectionSession? = nil
}

@available(iOS 15.0, *)
public extension EnvironmentValues {

  /// The active checkout session, injected by `.primerCheckoutSession(_:onCompletion:)`.
  var primerCheckoutSession: PrimerCheckoutSession? {
    get { self[PrimerCheckoutSessionKey.self] }
    set { self[PrimerCheckoutSessionKey.self] = newValue }
  }

  /// The card-form session derived from the active checkout session. Non-nil once the session is ready.
  var primerCardFormSession: PrimerCardFormSession? {
    get { self[PrimerCardFormSessionKey.self] }
    set { self[PrimerCardFormSessionKey.self] = newValue }
  }

  /// The payment-method-selection session derived from the active checkout session.
  var primerSelectionSession: PrimerSelectionSession? {
    get { self[PrimerSelectionSessionKey.self] }
    set { self[PrimerSelectionSessionKey.self] = newValue }
  }
}
