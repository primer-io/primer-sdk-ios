//
//  PaymentMethodButton.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct PaymentMethodButton: View {
  let method: CheckoutPaymentMethod
  let onSelect: () -> Void

  @Environment(\.designTokens) private var tokens
  @Environment(\.colorScheme) private var colorScheme

  private static let klarnaWordmarkName = "klarna-logo-light"

  private var isDark: Bool { colorScheme == .dark }

  var body: some View {
    switch PrimerPaymentMethodType(rawValue: method.type) {
    case .paymentCard: makeCardButton()
    case .applePay: makeApplePayButton()
    case .klarna: makeKlarnaButton()
    default: makePartnerButton()
    }
  }

  private func makeButton<Content: View>(
    fill: Color,
    border: Color? = nil,
    label: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    let shape = RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
    return Button(action: onSelect) {
      content()
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.small(tokens: tokens))
        .frame(minHeight: PrimerComponentHeight.paymentMethodCard)
        .background(shape.fill(fill))
        .overlay {
          if let border {
            shape.strokeBorder(border, lineWidth: PrimerBorderWidth.standard(tokens: tokens))
          }
        }
    }
    .buttonStyle(PaymentMethodButtonStyle())
    .accessibility(config: AccessibilityConfiguration(
      identifier: AccessibilityIdentifiers.PaymentSelection.paymentMethodItem(method.type),
      label: label,
      traits: [.isButton]
    ))
  }

  private func makePartnerButton() -> some View {
    let variant = PaymentMethodAssetVariant.forBackground(method.backgroundColorVariants, isDark: isDark)
    let background = method.backgroundColorVariants.flatMap {
      variant.value(colored: $0.coloredHex, light: $0.lightHex, dark: $0.darkHex)?.hexToUIColor()
    } ?? method.backgroundColor
    let logo = method.logoVariants.flatMap {
      variant.valueOrAny(colored: $0.colored, light: $0.light, dark: $0.dark, isDark: isDark)
    } ?? method.icon
    return makeButton(
      fill: background.map(Color.init) ?? CheckoutColors.background(tokens: tokens),
      label: CheckoutComponentsStrings.a11yPaymentMethodButton(method.buttonText ?? method.name)
    ) {
      if let logo {
        Image(uiImage: logo)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: PrimerComponentHeight.paymentMethodLogo)
      } else {
        Text(method.buttonText ?? method.name)
          .primerTypography(.titleLarge, tokens: tokens)
          .foregroundColor(partnerTextColor(for: variant))
      }
    }
  }

  private func makeCardButton() -> some View {
    makeButton(
      fill: CheckoutColors.inputBackground(tokens: tokens),
      border: CheckoutColors.borderDefault(tokens: tokens),
      label: CheckoutComponentsStrings.a11yPayWithCard
    ) {
      HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        if let icon = ImageName.creditCard.image {
          Image(uiImage: icon)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: PrimerSize.small(tokens: tokens), height: PrimerSize.small(tokens: tokens))
            .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
        }
        Text(CheckoutComponentsStrings.cardPaymentTitle)
          .primerTypography(.titleLarge, tokens: tokens)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      }
    }
  }

  private func makeApplePayButton() -> some View {
    ApplePayButtonView(
      style: .automatic,
      cornerRadius: PrimerRadius.medium(tokens: tokens),
      height: PrimerComponentHeight.paymentMethodCard,
      accessibilityIdentifier: AccessibilityIdentifiers.PaymentSelection.paymentMethodItem(method.type),
      action: onSelect
    )
    .frame(maxWidth: .infinity)
  }

  private func makeKlarnaButton() -> some View {
    let label = CheckoutComponentsStrings.a11yPayWithKlarna
    let text = KlarnaButtonText(label)
    return makeButton(fill: PaymentMethodColors.klarnaBlack, label: label) {
      HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        if let before = text.before {
          makeKlarnaText(before)
        }
        if let wordmark = UIImage(primerResource: Self.klarnaWordmarkName) {
          Image(uiImage: wordmark)
            .renderingMode(.template)
            .foregroundColor(PaymentMethodColors.klarnaBlack)
            .padding(PrimerSpacing.small(tokens: tokens))
            .background(
              RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                .fill(PaymentMethodColors.klarnaPink)
            )
        }
        if let after = text.after {
          makeKlarnaText(after)
        }
      }
    }
  }

  private func makeKlarnaText(_ text: String) -> some View {
    Text(text)
      .primerTypography(.titleLarge, tokens: tokens)
      .foregroundColor(PaymentMethodColors.klarnaOnBlack)
  }

  private func partnerTextColor(for variant: PaymentMethodAssetVariant) -> Color {
    let textColor = method.textColorVariants.flatMap {
      variant.valueOrAny(colored: $0.coloredHex, light: $0.lightHex, dark: $0.darkHex, isDark: isDark)?.hexToUIColor()
    } ?? method.textColor
    return textColor.map(Color.init) ?? CheckoutColors.textPrimary(tokens: tokens)
  }
}

// MARK: - Button Style

@available(iOS 15.0, *)
struct PaymentMethodButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}
