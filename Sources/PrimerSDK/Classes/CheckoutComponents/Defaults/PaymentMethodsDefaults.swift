//
//  PaymentMethodsDefaults.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default content for ``PrimerPaymentMethods``' slots. Section helpers return concrete view types
/// so they can serve as `@ViewBuilder` default arguments.
@available(iOS 15.0, *)
public enum PaymentMethodsDefaults {

  // `session` is accepted only to match the slot closure signature; the default header is static.
  public static func header(_ session: PrimerSelectionSession) -> PaymentMethodsHeaderContent {
    PaymentMethodsHeaderContent()
  }

  public static func method(
    _ method: CheckoutPaymentMethod,
    onSelect: @escaping () -> Void
  ) -> PaymentMethodRowContent {
    PaymentMethodRowContent(method: method, onSelect: onSelect)
  }

  public static func emptyState(_ session: PrimerSelectionSession) -> PaymentMethodsEmptyContent {
    PaymentMethodsEmptyContent()
  }

  public static func unavailable() -> some View {
    EmptyView()
  }
}

/// Default content for ``PrimerVaultedPaymentMethods``' slots. The view AnyView-erases these slots,
/// so the helpers return `some View` rather than concrete public types.
@available(iOS 15.0, *)
public enum VaultedPaymentMethodsDefaults {

  // `session` is accepted only to match the slot closure signature; the default header is static.
  public static func header(_ session: PrimerSelectionSession) -> some View {
    VaultedHeaderContent()
  }

  public static func item(
    _ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod,
    isSelected: Bool,
    onSelect: @escaping () -> Void
  ) -> some View {
    VaultedMethodRowContent(method: method, isSelected: isSelected, onSelect: onSelect)
  }

  public static func submitButton(
    isLoading: Bool,
    isEnabled: Bool,
    onSubmit: @escaping () -> Void
  ) -> some View {
    VaultedSubmitContent(isLoading: isLoading, isEnabled: isEnabled, onSubmit: onSubmit)
  }

  /// CVV recapture field, shown only when the selected vaulted card requires CVV. Empty otherwise.
  @MainActor
  @ViewBuilder
  public static func cvvInput(_ session: PrimerSelectionSession) -> some View {
    if session.state.requiresCvvInput {
      VaultedCVVContent(session: session)
    }
  }

  public static func unavailable() -> some View {
    PaymentMethodsDefaults.unavailable()
  }
}

@available(iOS 15.0, *)
private struct VaultedCVVContent: View {
  @ObservedObject var session: PrimerSelectionSession
  // Local mirror of the field text so typing renders immediately instead of waiting on the
  // scope's async state round-trip; validation/error are read back from the session state.
  @State private var cvv: String = ""

  var body: some View {
    VaultedCardCVVInput(
      cvv: $cvv,
      isValid: Binding(get: { session.state.isCvvValid }, set: { _ in }),
      errorMessage: Binding(get: { session.state.cvvError }, set: { _ in }),
      cardNetwork: cardNetwork,
      onCvvChange: session.updateCvvInput
    )
  }

  private var cardNetwork: CardNetwork {
    guard let method = session.state.selectedVaultedPaymentMethod else { return .unknown }
    let network =
      method.paymentInstrumentData.network
      ?? method.paymentInstrumentData.binData?.network ?? "Card"
    return CardNetwork(rawValue: network.uppercased()) ?? .unknown
  }
}

// MARK: - Concrete default views

@available(iOS 15.0, *)
public struct PaymentMethodsHeaderContent: View {
  @Environment(\.designTokens) private var tokens
  public var body: some View {
    Text(CheckoutComponentsStrings.choosePaymentMethod)
      .font(PrimerFont.titleLarge(tokens: tokens))
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }
}

@available(iOS 15.0, *)
public struct PaymentMethodRowContent: View {
  let method: CheckoutPaymentMethod
  let onSelect: () -> Void
  public var body: some View {
    PaymentMethodButton(method: method, onSelect: onSelect)
  }
}

@available(iOS 15.0, *)
public struct PaymentMethodsEmptyContent: View {
  @Environment(\.designTokens) private var tokens
  public var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Image(systemName: "creditcard.and.123")
        .font(PrimerFont.largeIcon(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      Text(CheckoutComponentsStrings.noPaymentMethodsAvailable)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
    }
    .frame(maxWidth: .infinity)
  }
}

@available(iOS 15.0, *)
private struct VaultedHeaderContent: View {
  @Environment(\.designTokens) private var tokens
  var body: some View {
    Text(CheckoutComponentsStrings.allSavedPaymentMethods)
      .font(PrimerFont.titleLarge(tokens: tokens))
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }
}

@available(iOS 15.0, *)
private struct VaultedMethodRowContent: View {
  let method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  let isSelected: Bool
  let onSelect: () -> Void
  @Environment(\.designTokens) private var tokens

  // Falls back to the brand name when no masked value is available, so a row with sparse display data
  // is never blank or unlabelled to VoiceOver.
  private var label: String {
    let displayData = method.displayData
    return displayData.primaryValue ?? displayData.brandName
  }

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        if let brandIcon = method.displayData.brandIcon {
          Image(uiImage: brandIcon)
            .resizable()
            .scaledToFit()
            .frame(width: PrimerSize.large(tokens: tokens), height: PrimerSize.large(tokens: tokens))
        }
        Text(label)
          .font(PrimerFont.bodyLarge(tokens: tokens))
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        Spacer()
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
      }
      .padding(PrimerSpacing.medium(tokens: tokens))
      .frame(maxWidth: .infinity)
      .overlay(
        RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
          .stroke(
            CheckoutColors.borderDefault(tokens: tokens), lineWidth: PrimerBorderWidth.standard(tokens: tokens))
      )
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(method.displayData.accessibilityLabel)
  }
}

@available(iOS 15.0, *)
private struct VaultedSubmitContent: View {
  let isLoading: Bool
  let isEnabled: Bool
  let onSubmit: () -> Void
  @Environment(\.designTokens) private var tokens

  var body: some View {
    Button(action: onSubmit) {
      Group {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.white(tokens: tokens)))
        } else {
          Text(CheckoutComponentsStrings.payButton)
        }
      }
      .font(PrimerFont.body(tokens: tokens))
      .foregroundColor(CheckoutColors.white(tokens: tokens))
      .frame(maxWidth: .infinity)
      .padding(.vertical, PrimerSpacing.large(tokens: tokens))
      .background(
        isEnabled && !isLoading
          ? CheckoutColors.textPrimary(tokens: tokens)
          : CheckoutColors.gray300(tokens: tokens)
      )
      .cornerRadius(PrimerRadius.small(tokens: tokens))
    }
    .disabled(!isEnabled || isLoading)
  }
}
