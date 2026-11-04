//
//  DropdownCardNetworkSelector.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 15.0, *)
struct DropdownCardNetworkSelector: View {
  let availableNetworks: [CardNetwork]
  @Binding var selectedNetwork: CardNetwork
  let onNetworkSelected: ((CardNetwork) -> Void)?

  @State private var triggerAnchor = WeakBox<UIView>()
  @State private var menuController = WeakBox<CardNetworkMenuController>()
  @Environment(\.designTokens) private var tokens
  @Environment(\.inputFieldAnchor) private var fieldAnchor
  @Environment(\.layoutDirection) private var layoutDirection

  var body: some View {
    Button(action: openMenu) {
      HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
        CardNetworkBadge(network: selectedNetwork)

        Image(systemName: "chevron.down")
          .font(.system(size: PrimerCardNetworkSelector.chevronFontSize, weight: .medium))
          .frame(
            width: PrimerCardNetworkSelector.chevronSize,
            height: PrimerCardNetworkSelector.chevronSize,
            alignment: .center
          )
          .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .anchored(to: triggerAnchor)
    .accessibilityIdentifier(AccessibilityIdentifiers.CardForm.dropdownNetworkSelectorButton)
    .accessibilityLabel(CheckoutComponentsStrings.a11yDropdownNetworkSelectorLabel)
    .accessibilityHint(CheckoutComponentsStrings.a11yDropdownNetworkSelectorHint)
    .onChange(of: availableNetworks) { _ in menuController.instance?.close() }
    .onDisappear { menuController.instance?.close() }
  }

  private func openMenu() {
    guard let fieldView = fieldAnchor?.instance ?? triggerAnchor.instance else { return }
    let controller = CardNetworkMenuController(
      menu: CardNetworkMenu(
        networks: availableNetworks,
        selectedNetwork: selectedNetwork,
        tokens: tokens,
        layoutDirection: layoutDirection,
        onSelect: select
      ),
      fieldView: fieldView
    )
    menuController.instance = controller
    controller.show()
  }

  private func select(_ network: CardNetwork) {
    menuController.instance?.close()
    selectedNetwork = network
    onNetworkSelected?(network)
  }
}

// MARK: - Previews

#if DEBUG
  @available(iOS 15.0, *)
  private struct DropdownCardNetworkSelectorPreviewWrapper: View {
    let networks: [CardNetwork]
    @State private var selected: CardNetwork

    init(networks: [CardNetwork]) {
      self.networks = networks
      _selected = State(initialValue: networks.first ?? .unknown)
    }

    var body: some View {
      DropdownCardNetworkSelector(
        availableNetworks: networks,
        selectedNetwork: $selected,
        onNetworkSelected: { network in
          print("Selected: \(network.displayName)")
        }
      )
    }
  }

  @available(iOS 15.0, *)
  #Preview("Light Mode - Two Networks") {
    DropdownCardNetworkSelectorPreviewWrapper(networks: [.visa, .masterCard])
      .padding()
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode - Two Networks") {
    DropdownCardNetworkSelectorPreviewWrapper(networks: [.visa, .masterCard])
      .padding()
      .background(Color.black)
      .environment(\.designTokens, MockDesignTokens.dark)
      .preferredColorScheme(.dark)
  }

  @available(iOS 15.0, *)
  #Preview("Light Mode - Three Networks") {
    DropdownCardNetworkSelectorPreviewWrapper(networks: [.visa, .masterCard, .cartesBancaires])
      .padding()
      .environment(\.designTokens, MockDesignTokens.light)
  }
#endif
