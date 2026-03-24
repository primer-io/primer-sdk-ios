//
//  ApplePayScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import SwiftUI

@available(iOS 15.0, *)
struct ApplePayScreen: View {
  @ObservedObject private var scope: DefaultApplePayScope
  @Environment(\.designTokens) private var tokens

  private let presentationContext: PresentationContext

  init(
    scope: DefaultApplePayScope, presentationContext: PresentationContext = .fromPaymentSelection
  ) {
    self.scope = scope
    self.presentationContext = presentationContext
  }

  var body: some View {
    VStack(spacing: 0) {
      makeNavigationBar()
      makeContent()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(CheckoutColors.background(tokens: tokens))
  }

  private func makeNavigationBar() -> some View {
    HStack {
      if presentationContext.shouldShowBackButton {
        Button(action: scope.onBack) {
          Image(systemName: RTLIcon.backChevron)
            .font(PrimerFont.bodyMedium(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
        .padding(.leading, PrimerSpacing.large(tokens: tokens))
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.backButton,
            label: CheckoutComponentsStrings.a11yBack,
            traits: [.isButton]
          ))
      }

      Spacer()

      Text(CheckoutComponentsStrings.applePayTitle)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.title)
        .accessibilityAddTraits(.isHeader)

      Spacer()

      Button(action: scope.onDismiss) {
        Image(systemName: "xmark")
          .font(PrimerFont.bodyMedium(tokens: tokens))
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      }
      .padding(.trailing, PrimerSpacing.large(tokens: tokens))
      .accessibility(
        config: AccessibilityConfiguration(
          identifier: AccessibilityIdentifiers.Common.closeButton,
          label: CheckoutComponentsStrings.a11yCancel,
          traits: [.isButton]
        ))
    }
    .frame(height: 56)
    .background(CheckoutColors.background(tokens: tokens))
  }

  @ViewBuilder
  private func makeContent() -> some View {
    if scope.structuredState.isAvailable {
      makeAvailableContent()
    } else {
      makeUnavailableContent()
    }
  }

  private func makeAvailableContent() -> some View {
    VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
      Spacer()

      Image(systemName: "apple.logo")
        .font(PrimerFont.extraLargeIcon(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .accessibilityHidden(true)

      Text(CheckoutComponentsStrings.applePayDescription)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.description)

      Spacer()

      if scope.structuredState.isLoading {
        makeLoadingView()
      } else {
        makeApplePayButton()
      }

      Spacer()
        .frame(height: PrimerSpacing.xxlarge(tokens: tokens))
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
  }

  @ViewBuilder
  private func makeApplePayButton() -> some View {
    if let customButton = scope.applePayButton {
      AnyView(customButton(scope.submit))
        .frame(height: 50)
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.payButton)
    } else {
      scope.PrimerApplePayButton(action: scope.submit)
        .frame(height: 50)
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.payButton)
    }
  }

  private func makeLoadingView() -> some View {
    HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.processingIndicator)

      Text(CheckoutComponentsStrings.applePayProcessing)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.processingLabel)
    }
    .frame(height: 50)
  }

  private func makeUnavailableContent() -> some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Spacer()

      Image(systemName: "exclamationmark.triangle")
        .font(PrimerFont.largeIcon(tokens: tokens))
        .foregroundColor(CheckoutColors.orange(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.unavailableIcon)
        .accessibilityHidden(true)

      Text(CheckoutComponentsStrings.applePayUnavailable)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.unavailableTitle)
        .accessibilityAddTraits(.isHeader)

      if let error = scope.structuredState.availabilityError {
        Text(error)
          .font(PrimerFont.bodyMedium(tokens: tokens))
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
          .multilineTextAlignment(.center)
          .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
          .accessibilityIdentifier(AccessibilityIdentifiers.ApplePay.unavailableDescription)
      }

      Spacer()

      if presentationContext.shouldShowBackButton {
        Button(action: scope.onBack) {
          Text(CheckoutComponentsStrings.applePayChooseOther)
            .font(PrimerFont.bodyMedium(tokens: tokens))
            .fontWeight(.medium)
            .foregroundColor(CheckoutColors.white(tokens: tokens))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(CheckoutColors.blue(tokens: tokens))
            .cornerRadius(PrimerRadius.medium(tokens: tokens))
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.ApplePay.chooseOtherButton,
            label: CheckoutComponentsStrings.applePayChooseOther,
            traits: [.isButton]
          ))
      }

      Spacer()
        .frame(height: PrimerSpacing.xxlarge(tokens: tokens))
    }
  }
}

#if DEBUG
  @available(iOS 15.0, *)
  struct ApplePayScreen_Previews: PreviewProvider {
    static var previews: some View {
      Text("Apple Pay Screen Preview")
    }
  }
#endif
