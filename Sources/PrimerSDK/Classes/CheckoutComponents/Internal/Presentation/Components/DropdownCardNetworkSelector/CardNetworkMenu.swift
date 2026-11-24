//
//  CardNetworkMenu.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 15.0, *)
struct CardNetworkMenu: View {
  let networks: [CardNetwork]
  let selectedNetwork: CardNetwork
  let tokens: DesignTokens?
  let layoutDirection: LayoutDirection
  let onSelect: (CardNetwork) -> Void

  @Environment(\.displayScale) private var displayScale

  private static let shadowOpacity = 0.18
  private static let shadowRadius: CGFloat = 24
  private static let shadowOffsetY: CGFloat = 8

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
  }

  var body: some View {
    VStack(spacing: 0) {
      ForEach(networks, id: \.rawValue) { network in
        if network != networks.first { makeSeparator() }
        makeRow(network)
      }
    }
    .frame(width: PrimerCardNetworkSelector.menuWidth)
    .clipShape(shape)
    .overlay(
      shape.strokeBorder(
        CheckoutColors.borderDefault(tokens: tokens),
        lineWidth: PrimerBorderWidth.standard(tokens: tokens)
      )
    )
    .background(
      shape
        .fill(CheckoutColors.background(tokens: tokens))
        .shadow(color: .black.opacity(Self.shadowOpacity), radius: Self.shadowRadius, y: Self.shadowOffsetY)
    )
    .environment(\.layoutDirection, layoutDirection)
    .ignoresSafeArea()
  }

  private func makeRow(_ network: CardNetwork) -> some View {
    Button {
      onSelect(network)
    } label: {
      HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        Image(systemName: "checkmark")
          .opacity(network == selectedNetwork ? 1 : 0)
          .frame(width: PrimerSize.medium(tokens: tokens))
          .accessibilityHidden(true)
        Text(network.displayName)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .primerTypography(.bodyLarge, tokens: tokens)
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
      .contentShape(Rectangle())
    }
    .buttonStyle(RowStyle(pressedColor: CheckoutColors.backgroundSecondary(tokens: tokens)))
    .accessibilityAddTraits(network == selectedNetwork ? .isSelected : [])
  }

  private func makeSeparator() -> some View {
    Rectangle()
      .fill(CheckoutColors.borderDefault(tokens: tokens))
      .frame(height: 1 / displayScale)
      .padding(.leading, PrimerSpacing.large(tokens: tokens))
  }
}

@available(iOS 15.0, *)
private struct RowStyle: ButtonStyle {
  let pressedColor: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label.background(configuration.isPressed ? pressedColor : .clear)
  }
}
