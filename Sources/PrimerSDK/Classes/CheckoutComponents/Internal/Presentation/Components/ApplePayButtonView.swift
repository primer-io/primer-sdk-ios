//
//  ApplePayButtonView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import SwiftUI

@available(iOS 15.0, *)
public struct ApplePayButtonView: View {
  private let style: PKPaymentButtonStyle
  private let type: PKPaymentButtonType
  private let cornerRadius: CGFloat
  private let action: () -> Void

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
      context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside
    )
    return button
  }

  func updateUIView(_ uiView: PKPaymentButton, context: Context) {
    uiView.cornerRadius = cornerRadius
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(action: action)
  }

  final class Coordinator: NSObject {
    let action: () -> Void

    init(action: @escaping () -> Void) {
      self.action = action
    }

    @objc func buttonTapped() {
      action()
    }
  }
}

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
