//
//  CardFormDefaults.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default content for ``PrimerCardForm``'s slots, and building blocks for recomposing the form.
///
/// Section helpers (`cardDetails`, `billingAddress`, `submitButton`) return concrete view types so the
/// `@ViewBuilder` default arguments can bind `PrimerCardForm`'s generic view parameters (`CardDetails`,
/// `Billing`, `Submit`) at the default-value site; an opaque `some View` return cannot satisfy a
/// generic placeholder there.
///
/// Field-level helpers (`cardNumber`, `cvv`, …) mirror Android's per-field composables. Android also
/// exposes per-field slot lambdas on its section composables; Swift default arguments cannot reference
/// the `session` init parameter at the default-value site, so rather than force awkward per-field
/// closure inits we keep the no-arg `cardDetails`/`billingAddress` shared renderer as the default.
/// Merchants get full field recomposition by composing these 15 building blocks inside the existing
/// `PrimerCardForm(cardDetails:)` / `PrimerCardForm(billingAddress:)` section slots.
@available(iOS 15.0, *)
public enum CardFormDefaults {

  // MARK: - Section content

  /// Default card-details section (number, expiry, CVV, cardholder name).
  public static func cardDetails(_ session: PrimerCardFormSession) -> CardDetailsContent {
    CardDetailsContent(session: session)
  }

  /// Default billing-address section. Renders only when the configuration requires billing fields.
  public static func billingAddress(_ session: PrimerCardFormSession) -> BillingAddressContent {
    BillingAddressContent(session: session)
  }

  /// Default submit button, enabled when the form is valid and not loading.
  public static func submitButton(_ session: PrimerCardFormSession) -> CardSubmitButton {
    CardSubmitButton(session: session)
  }

  /// Placeholder shown when no checkout session is present in the environment (the
  /// `.primerCheckoutSession(_:)` modifier was not applied, or the session is not yet ready).
  public static func unavailable() -> some View {
    EmptyView()
  }

  // MARK: - Card field building blocks

  /// Card number field. Renders nothing unless the configuration requires it.
  public static func cardNumber(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .cardNumber)
  }

  /// Expiry date field. Renders nothing unless the configuration requires it.
  public static func expiryDate(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .expiryDate)
  }

  /// CVV field. Renders nothing unless the configuration requires it.
  public static func cvv(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .cvv)
  }

  /// Cardholder name field. Renders nothing unless the configuration requires it.
  public static func cardholderName(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .cardholderName)
  }

  /// Co-badged card network selector. Renders nothing unless more than one network is available.
  ///
  /// Intended for layouts that recompose the individual card fields (which suppress the built-in
  /// selector). Do not use alongside the full `cardDetails(_:)` section, which already renders the
  /// selector when multiple networks are detected, or two selectors will appear.
  public static func cardNetwork(_ session: PrimerCardFormSession) -> CardNetworkFieldContent {
    CardNetworkFieldContent(session: session)
  }

  // MARK: - Billing field building blocks

  /// Country selector field. Renders nothing unless the configuration requires it.
  public static func countryCode(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .countryCode)
  }

  /// First name field. Renders nothing unless the configuration requires it.
  public static func firstName(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .firstName)
  }

  /// Last name field. Renders nothing unless the configuration requires it.
  public static func lastName(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .lastName)
  }

  /// First address-line field. Renders nothing unless the configuration requires it.
  public static func addressLine1(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .addressLine1)
  }

  /// Second address-line field. Renders nothing unless the configuration requires it.
  public static func addressLine2(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .addressLine2)
  }

  /// City field. Renders nothing unless the configuration requires it.
  public static func city(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .city)
  }

  /// State field. Renders nothing unless the configuration requires it.
  public static func state(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .state)
  }

  /// Postal code field. Renders nothing unless the configuration requires it.
  public static func postalCode(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .postalCode)
  }

  /// Phone number field. Renders nothing unless the configuration requires it.
  public static func phoneNumber(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .phoneNumber)
  }

  /// Email field. Renders nothing unless the configuration requires it.
  public static func email(_ session: PrimerCardFormSession) -> CardFieldContent {
    CardFieldContent(session: session, field: .email)
  }
}

// MARK: - Concrete section views

@available(iOS 15.0, *)
public struct CardDetailsContent: View {
  let session: PrimerCardFormSession

  public var body: some View {
    if let internalScope = session.scope as? any CardFormFieldScopeInternal {
      // Shared, config-aware renderer — same one the modal CardFormScreen uses (single render path).
      CardFormFieldsView(scope: internalScope, section: .card)
    } else {
      EmptyView()
    }
  }
}

@available(iOS 15.0, *)
public struct BillingAddressContent: View {
  let session: PrimerCardFormSession

  public var body: some View {
    if let internalScope = session.scope as? any CardFormFieldScopeInternal {
      // Renders only when the API-driven configuration includes billing fields (handled internally).
      CardFormFieldsView(scope: internalScope, section: .billing)
    } else {
      EmptyView()
    }
  }
}

/// A single card-form field, rendered through the shared config-aware renderer.
///
/// Renders nothing unless the field is part of the API-driven form configuration (matching Android's
/// per-field `isFieldRequired` gating), so merchants can drop every building block into a custom
/// layout without worrying about which fields the current session actually requires.
@available(iOS 15.0, *)
public struct CardFieldContent: View {
  let session: PrimerCardFormSession
  let field: PrimerInputElementType

  public var body: some View {
    if let internalScope = session.scope as? any CardFormFieldScopeInternal, isFieldRequired(internalScope) {
      CardFormFieldsView(scope: internalScope, section: .single(field))
    } else {
      EmptyView()
    }
  }

  private func isFieldRequired(_ scope: any CardFormFieldScopeInternal) -> Bool {
    let configuration = scope.getFormConfiguration()
    return configuration.cardFields.contains(field) || configuration.billingFields.contains(field)
  }
}

/// Co-badged card network selector. Mirrors Android's standalone `CardNetworkField`: renders only when
/// more than one network is available, reusing the SDK's `DropdownCardNetworkSelector`.
@available(iOS 15.0, *)
public struct CardNetworkFieldContent: View {
  @ObservedObject var session: PrimerCardFormSession

  private var availableNetworks: [CardNetwork] {
    session.state.availableNetworks.map(\.network)
  }

  // Single source of truth: reads the scope's committed selection and writes back through it, so the
  // dropdown can never display a network the scope did not accept.
  private var selectedNetwork: Binding<CardNetwork> {
    Binding(
      get: { session.state.selectedNetwork?.network ?? availableNetworks.first ?? .unknown },
      set: { network in
        if let primerNetwork = session.state.availableNetworks.first(where: { $0.network == network }) {
          session.selectCardNetwork(primerNetwork)
        }
      }
    )
  }

  public var body: some View {
    if availableNetworks.count > 1 {
      DropdownCardNetworkSelector(
        availableNetworks: availableNetworks,
        selectedNetwork: selectedNetwork,
        onNetworkSelected: nil
      )
    } else {
      EmptyView()
    }
  }
}

@available(iOS 15.0, *)
public struct CardSubmitButton: View {
  @ObservedObject var session: PrimerCardFormSession
  @Environment(\.designTokens) private var tokens

  public var body: some View {
    Button(action: session.submit) {
      Text(CheckoutComponentsStrings.payButton)
        .frame(maxWidth: .infinity)
        .padding(PrimerSpacing.medium(tokens: tokens))
    }
    .disabled(!session.state.isValid || session.state.isLoading)
  }
}
