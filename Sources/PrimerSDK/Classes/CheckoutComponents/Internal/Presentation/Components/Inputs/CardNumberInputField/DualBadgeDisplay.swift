//
//  DualBadgeDisplay.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct DualBadgeDisplay: View {
  let networks: [CardNetwork]

  @Environment(\.designTokens) private var tokens

  // MARK: - Body

  var body: some View {
    HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      ForEach(networks, id: \.self) { network in
        CardNetworkBadge(network: network)
      }
    }
    .allowsHitTesting(false)
  }
}

// MARK: - Previews

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("Light Mode") {
    VStack(spacing: 16) {
      DualBadgeDisplay(networks: [.visa, .eftpos])
      DualBadgeDisplay(networks: [.masterCard, .eftpos])
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    VStack(spacing: 16) {
      DualBadgeDisplay(networks: [.visa, .eftpos])
      DualBadgeDisplay(networks: [.masterCard, .eftpos])
    }
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .preferredColorScheme(.dark)
  }
#endif
