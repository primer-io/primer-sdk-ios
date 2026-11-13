//
//  SurchargeGroupCard.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 15.0, *)
struct SurchargeGroupCard<Row: View>: View {
  let group: SurchargeGroup
  @ViewBuilder let row: (CheckoutPaymentMethod) -> Row

  @Environment(\.designTokens) private var tokens
  @Environment(\.diContainer) private var container

  var body: some View {
    if let title = group.title {
      VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        makeTitle(title)
          .accessibilityElement(children: .combine)
          .accessibilityAddTraits(.isHeader)
        makeRows()
      }
      .padding(PrimerSpacing.small(tokens: tokens))
      .background(
        RoundedRectangle(cornerRadius: PrimerRadius.large(tokens: tokens))
          .fill(CheckoutColors.backgroundSecondary(tokens: tokens))
      )
    } else {
      makeRows()
    }
  }

  private func makeRows() -> some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      ForEach(group.methods, content: row)
    }
  }

  @ViewBuilder
  private func makeTitle(_ title: SurchargeGroup.Title) -> some View {
    switch title {
    case let .fee(amount):
      HStack {
        makeLabel(CheckoutComponentsStrings.surchargeFee, color: CheckoutColors.textSecondary(tokens: tokens))
        Spacer()
        if let formattedFee = formattedFee(amount) {
          Text(formattedFee)
            .primerTypography(.titleLarge, tokens: tokens)
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
      }
    case .noFee, .mayApply:
      let text = title == .noFee ? CheckoutComponentsStrings.noAdditionalFee : CheckoutComponentsStrings.additionalFeeMayApply
      makeLabel(text, color: CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }

  private func makeLabel(_ text: String, color: Color) -> some View {
    Text(text)
      .primerTypography(.bodyMedium, tokens: tokens)
      .foregroundColor(color)
  }

  private func formattedFee(_ amount: Int) -> String? {
    let configurationService = try? container?.resolveSync(ConfigurationService.self)
    return configurationService?.formattedAmount(amount).map { "+ \($0)" }
  }
}
