//
//  PrimerCardForm.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// The card payment form, composed from three section slots.
///
/// Resolves its ``PrimerCardFormSession`` from the environment (provided by
/// `.primerCheckoutSession(_:onCompletion:)`), so it can be embedded anywhere — inside the modal
/// ``PrimerCheckout`` or inline in the merchant's own layout.
///
/// ```swift
/// // Defaults
/// PrimerCardForm()
///
/// // Custom submit button (label the slot — a bare trailing closure binds to the last slot)
/// PrimerCardForm(submitButton: { session in
///   MyPayButton(isLoading: session.state.isLoading) { session.submit() }
/// })
///
/// // Recomposed card section
/// PrimerCardForm(cardDetails: { session in
///   VStack { CardFormDefaults.cardDetails(session); MyPromoBanner() }
/// })
/// ```
@available(iOS 15.0, *)
public struct PrimerCardForm<CardDetails: View, Billing: View, Submit: View>: View {

  @Environment(\.primerCardFormSession) private var session

  private let cardDetails: (PrimerCardFormSession) -> CardDetails
  private let billingAddress: (PrimerCardFormSession) -> Billing
  private let submitButton: (PrimerCardFormSession) -> Submit

  public init(
    @ViewBuilder cardDetails: @escaping (PrimerCardFormSession) -> CardDetails = { CardFormDefaults.cardDetails($0) },
    @ViewBuilder billingAddress: @escaping (PrimerCardFormSession) -> Billing = { CardFormDefaults.billingAddress($0) },
    @ViewBuilder submitButton: @escaping (PrimerCardFormSession) -> Submit = { CardFormDefaults.submitButton($0) }
  ) {
    self.cardDetails = cardDetails
    self.billingAddress = billingAddress
    self.submitButton = submitButton
  }

  public var body: some View {
    if let session {
      Bound(
        session: session,
        cardDetails: cardDetails,
        billingAddress: billingAddress,
        submitButton: submitButton
      )
    } else {
      CardFormDefaults.unavailable()
    }
  }

  // Observes the session's published state and lays out the three slots. Each slot is erased once at
  // this layout boundary so the view's generic parameters don't propagate into the navigation host.
  private struct Bound: View {
    @ObservedObject var session: PrimerCardFormSession
    let cardDetails: (PrimerCardFormSession) -> CardDetails
    let billingAddress: (PrimerCardFormSession) -> Billing
    let submitButton: (PrimerCardFormSession) -> Submit
    @Environment(\.designTokens) private var tokens

    var body: some View {
      VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
        AnyView(cardDetails(session))
        AnyView(billingAddress(session))
        AnyView(submitButton(session))
      }
    }
  }
}
