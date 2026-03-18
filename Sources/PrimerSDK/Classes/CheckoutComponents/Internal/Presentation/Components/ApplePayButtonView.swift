//
//  ApplePayButtonView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import SwiftUI

/// SwiftUI wrapper for PKPaymentButton.
/// Provides a native Apple Pay button with customizable style, type, and corner radius.
@available(iOS 15.0, *)
public struct ApplePayButtonView: View {

  // MARK: - Properties

  private let style: PKPaymentButtonStyle
  private let type: PKPaymentButtonType
  private let cornerRadius: CGFloat
  private let action: () -> Void

  // MARK: - Initialization

  /// Creates an Apple Pay button view.
  /// - Parameters:
  ///   - style: The button style (.black, .white, .whiteOutline, .automatic)
  ///   - type: The button type (.plain, .buy, .setUp, .checkout, etc.)
  ///   - cornerRadius: The corner radius of the button
  ///   - action: The action to perform when the button is tapped
  public init(
    style: PKPaymentButtonStyle = .black,
    type: PKPaymentButtonType = .plain,
    cornerRadius: CGFloat = 8.0,
    action: @escaping () -> Void
  ) {
    self.style = style
    self.type = type
    self.cornerRadius = cornerRadius
    self.action = action
  }

  // MARK: - Body

  public var body: some View {
    ApplePayButtonRepresentable(
      style: style,
      type: type,
      cornerRadius: cornerRadius,
      action: action
    )
    .frame(height: 50)
    .accessibilityLabel("Pay with Apple Pay")
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - UIViewRepresentable

@available(iOS 15.0, *)
private struct ApplePayButtonRepresentable: UIViewRepresentable {

  let style: PKPaymentButtonStyle
  let type: PKPaymentButtonType
  let cornerRadius: CGFloat
  let action: () -> Void

  func makeUIView(context: Context) -> PKPaymentButton {
    let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
    button.cornerRadius = cornerRadius
    button.addTarget(
      context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
    return button
  }

  func updateUIView(_ uiView: PKPaymentButton, context: Context) {
    // PKPaymentButton doesn't support updating style/type after creation
    // Corner radius can be updated
    uiView.cornerRadius = cornerRadius
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(action: action)
  }

  // MARK: - Coordinator

  class Coordinator: NSObject {
    let action: () -> Void

    init(action: @escaping () -> Void) {
      self.action = action
    }

    @objc func buttonTapped() {
      action()
    }
  }
}

// MARK: - Preview

#if DEBUG
  @available(iOS 15.0, *)
  struct ApplePayButtonView_Previews: PreviewProvider {
    static var previews: some View {
      VStack(spacing: 16) {
        ApplePayButtonView(style: .black, type: .plain) {
          print("Apple Pay tapped")
        }

        ApplePayButtonView(style: .white, type: .buy) {
          print("Apple Pay tapped")
        }

        ApplePayButtonView(style: .whiteOutline, type: .checkout) {
          print("Apple Pay tapped")
        }

        ApplePayButtonView(style: .automatic, type: .inStore, cornerRadius: 16) {
          print("Apple Pay tapped")
        }
      }
      .padding()
      .background(Color.gray.opacity(0.2))
    }
  }
#endif
