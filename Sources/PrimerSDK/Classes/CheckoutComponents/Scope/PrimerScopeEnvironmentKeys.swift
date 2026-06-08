//
//  PrimerScopeEnvironmentKeys.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Scope Environment Keys

@available(iOS 15.0, *)
private struct PrimerCheckoutScopeKey: EnvironmentKey {
  static let defaultValue: PrimerCheckoutScope? = nil
}

@available(iOS 15.0, *)
private struct PrimerCardFormScopeKey: EnvironmentKey {
  static let defaultValue: (any PrimerCardFormScope)? = nil
}

@available(iOS 15.0, *)
private struct PrimerPaymentMethodSelectionScopeKey: EnvironmentKey {
  static let defaultValue: PrimerPaymentMethodSelectionScope? = nil
}

@available(iOS 15.0, *)
private struct PrimerSelectCountryScopeKey: EnvironmentKey {
  static let defaultValue: PrimerSelectCountryScope? = nil
}

// MARK: - EnvironmentValues Extension

// These accessors are SDK-internal: the scope protocols are internal (mirroring Android v3),
// so the environment values are propagated only within the SDK's own view hierarchy.
@available(iOS 15.0, *)
extension EnvironmentValues {
  var primerCheckoutScope: PrimerCheckoutScope? {
    get { self[PrimerCheckoutScopeKey.self] }
    set { self[PrimerCheckoutScopeKey.self] = newValue }
  }

  var primerCardFormScope: (any PrimerCardFormScope)? {
    get { self[PrimerCardFormScopeKey.self] }
    set { self[PrimerCardFormScopeKey.self] = newValue }
  }

  var primerPaymentMethodSelectionScope: PrimerPaymentMethodSelectionScope? {
    get { self[PrimerPaymentMethodSelectionScopeKey.self] }
    set { self[PrimerPaymentMethodSelectionScopeKey.self] = newValue }
  }

  var primerSelectCountryScope: PrimerSelectCountryScope? {
    get { self[PrimerSelectCountryScopeKey.self] }
    set { self[PrimerSelectCountryScopeKey.self] = newValue }
  }
}
