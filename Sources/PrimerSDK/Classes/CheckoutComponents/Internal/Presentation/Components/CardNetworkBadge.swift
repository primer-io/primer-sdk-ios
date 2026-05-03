//
//  CardNetworkBadge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CardNetworkBadge: View, LogReporter {
  let network: CardNetwork

  @Environment(\.designTokens) private var tokens

  @ViewBuilder
  var body: some View {
    if let icon = network.icon {
      Image(uiImage: icon)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(
          width: PrimerCardNetworkSelector.badgeWidth, height: PrimerCardNetworkSelector.badgeHeight
        )
        .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
    } else {
      Text(network.displayName.prefix(2).uppercased())
        .font(PrimerFont.smallBadge(tokens: tokens))
        .foregroundColor(CheckoutColors.primary(tokens: tokens))
        .frame(
          width: PrimerCardNetworkSelector.badgeWidth, height: PrimerCardNetworkSelector.badgeHeight
        )
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.xsmall(tokens: tokens))
            .stroke(CheckoutColors.borderDefault(tokens: tokens), lineWidth: PrimerBorderWidth.thin)
        )
    }
  }
}

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("Light Mode") {
    VStack(spacing: 16) {
      HStack(spacing: 8) {
        CardNetworkBadge(network: .visa)
        CardNetworkBadge(network: .masterCard)
        CardNetworkBadge(network: .amex)
        CardNetworkBadge(network: .discover)
      }

      HStack(spacing: 8) {
        CardNetworkBadge(network: .cartesBancaires)
        CardNetworkBadge(network: .diners)
        CardNetworkBadge(network: .jcb)
        CardNetworkBadge(network: .unknown)
      }
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    VStack(spacing: 16) {
      HStack(spacing: 8) {
        CardNetworkBadge(network: .visa)
        CardNetworkBadge(network: .masterCard)
        CardNetworkBadge(network: .amex)
        CardNetworkBadge(network: .discover)
      }

      HStack(spacing: 8) {
        CardNetworkBadge(network: .cartesBancaires)
        CardNetworkBadge(network: .diners)
        CardNetworkBadge(network: .jcb)
        CardNetworkBadge(network: .unknown)
      }
    }
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .preferredColorScheme(.dark)
  }
#endif
