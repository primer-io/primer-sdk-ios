//
//  PaymentMethodButton.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A button component for displaying a payment method in the selection list
@available(iOS 15.0, *)
struct PaymentMethodButton: View {
  let method: CheckoutPaymentMethod
  let customItem: PaymentMethodItemComponent?
  let onSelect: () -> Void

  @Environment(\.designTokens) private var tokens

  var body: some View {
    if let customItem {
      AnyView(customItem(method))
        .onTapGesture { onSelect() }
    } else {
      let radius = method.cornerRadius ?? PrimerRadius.medium(tokens: tokens)
      Button(action: onSelect) {
        HStack(spacing: PrimerSpacing.large(tokens: tokens)) {
          icon
          if let text = method.buttonText ?? method.name as String? {
            Text(text)
              .font(PrimerFont.bodyLarge(tokens: tokens))
              .foregroundColor(
                method.textColor.map(Color.init) ?? CheckoutColors.textPrimary(tokens: tokens))
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .frame(minHeight: PrimerComponentHeight.paymentMethodCard)
        .background(
          RoundedRectangle(cornerRadius: radius)
            .fill(
              method.backgroundColor.map(Color.init) ?? CheckoutColors.background(tokens: tokens))
        )
        .overlay(
          RoundedRectangle(cornerRadius: radius)
            .strokeBorder(
              borderColor(for: method),
              lineWidth: borderWidth(for: method))
        )
      }
      .buttonStyle(PaymentMethodButtonStyle())
    }
  }

  private var hasVisibleBackground: Bool {
    guard let bg = method.backgroundColor else { return false }
    var white: CGFloat = 0
    var alpha: CGFloat = 0
    bg.getWhite(&white, alpha: &alpha)
    return alpha > 0.1 && white < 0.95
  }

  private func borderColor(for method: CheckoutPaymentMethod) -> Color {
    if let color = method.borderColor, color != .clear {
      return Color(color)
    }
    guard !hasVisibleBackground else { return .clear }
    return CheckoutColors.borderDefault(tokens: tokens)
  }

  private func borderWidth(for method: CheckoutPaymentMethod) -> CGFloat {
    if let width = method.borderWidth, width > 0 {
      return width
    }
    guard !hasVisibleBackground else { return 0 }
    return PrimerBorderWidth.standard
  }

  @ViewBuilder
  private var icon: some View {
    let image =
      method.icon ?? PrimerPaymentMethodType(rawValue: method.type)?.defaultImageName.image
    if let image {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(
          width: PrimerComponentWidth.paymentMethodIcon, height: PrimerSize.large(tokens: tokens))
    }
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
