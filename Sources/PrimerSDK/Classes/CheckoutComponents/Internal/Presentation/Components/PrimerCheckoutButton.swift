//
//  PrimerCheckoutButton.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// The one button in the checkout. Android, React Native and web each have one already, so a merchant
/// moving a token moves every button together. iOS had eleven written inline in five different shapes.
///
/// Measured from the design: 44 minimum height, medium radius, `titleLarge` label.
///
/// Disabled means grey. Loading keeps the button's own resting look and adds a spinner, so a shopper
/// never sees the disabled colour on a button that is taking their money.
@available(iOS 15.0, *)
struct PrimerCheckoutButton<Label: View>: View {

  /// Filled is the pay button. Outlined is the same shape with a border and no fill.
  enum Style {
    case filled
    case outlined
  }

  private let style: Style
  private let isEnabled: Bool
  private let isLoading: Bool
  private let action: () -> Void
  private let accessibilityConfiguration: AccessibilityConfiguration?
  private let label: () -> Label

  @Environment(\.designTokens) private var tokens

  init(
    style: Style = .filled,
    isEnabled: Bool = true,
    isLoading: Bool = false,
    accessibilityConfiguration: AccessibilityConfiguration? = nil,
    action: @escaping () -> Void,
    @ViewBuilder label: @escaping () -> Label
  ) {
    self.style = style
    self.isEnabled = isEnabled
    self.isLoading = isLoading
    self.accessibilityConfiguration = accessibilityConfiguration
    self.action = action
    self.label = label
  }

  /// A loading button is still live to look at, so it keeps the enabled colours.
  private var showsEnabledColors: Bool { isEnabled || isLoading }

  private var foregroundColor: Color {
    switch (style, showsEnabledColors) {
    case let (.filled, isActive): CheckoutColors.onBrand(tokens: tokens, isEnabled: isActive)
    case (.outlined, true): CheckoutColors.textPrimary(tokens: tokens)
    case (.outlined, false): CheckoutColors.textDisabled(tokens: tokens)
    }
  }

  private var backgroundColor: Color {
    switch (style, showsEnabledColors) {
    case (.filled, true): CheckoutColors.buttonPrimary(tokens: tokens)
    case (.filled, false): CheckoutColors.buttonDisabled(tokens: tokens)
    case (.outlined, _): .clear
    }
  }

  private var borderColor: Color {
    guard style == .outlined else { return .clear }
    return showsEnabledColors
      ? CheckoutColors.borderDefault(tokens: tokens)
      : CheckoutColors.borderDisabled(tokens: tokens)
  }

  private var borderWidth: CGFloat { style == .outlined ? PrimerBorderWidth.standard : 0 }

  var body: some View {
    Button(action: action) {
      content
    }
    .disabled(!isEnabled || isLoading)
  }

  @ViewBuilder
  private var content: some View {
    let radius = PrimerRadius.medium(tokens: tokens)

    Group {
      if isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
          .scaleEffect(PrimerScale.small)
      } else {
        label()
      }
    }
    .font(PrimerFont.titleLarge(tokens: tokens))
    .foregroundColor(foregroundColor)
    .frame(maxWidth: .infinity)
    .frame(minHeight: PrimerComponentHeight.interactive)
    .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
    .background(backgroundColor)
    .cornerRadius(radius)
    .overlay(
      RoundedRectangle(cornerRadius: radius)
        .stroke(borderColor, lineWidth: borderWidth)
    )
    .accessibilityIfPresent(accessibilityConfiguration)
  }
}

@available(iOS 15.0, *)
extension PrimerCheckoutButton where Label == Text {
  /// The common case: a button whose label is a single string.
  init(
    _ title: String,
    style: Style = .filled,
    isEnabled: Bool = true,
    isLoading: Bool = false,
    accessibilityConfiguration: AccessibilityConfiguration? = nil,
    action: @escaping () -> Void
  ) {
    self.init(
      style: style,
      isEnabled: isEnabled,
      isLoading: isLoading,
      accessibilityConfiguration: accessibilityConfiguration,
      action: action,
      label: { Text(title) }
    )
  }
}

@available(iOS 15.0, *)
private extension View {
  @ViewBuilder
  func accessibilityIfPresent(_ config: AccessibilityConfiguration?) -> some View {
    if let config {
      accessibility(config: config)
    } else {
      self
    }
  }
}
