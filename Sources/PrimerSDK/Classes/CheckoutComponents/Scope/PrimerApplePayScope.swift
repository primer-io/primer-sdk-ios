//
//  PrimerApplePayScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import SwiftUI

/// Protocol defining the Apple Pay scope interface for CheckoutComponents.
/// Provides access to Apple Pay state, button customization, and payment flow control.
/// Access availability and button configuration through the `state` async stream.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerApplePayScope: PrimerPaymentMethodScope where State == PrimerApplePayState {

  // MARK: - State

  /// The current state of the Apple Pay scope as an async stream.
  var state: AsyncStream<PrimerApplePayState> { get }

  // MARK: - UI Customization

  /// Custom Apple Pay screen override
  var screen: ((_ scope: any PrimerApplePayScope) -> any View)? { get set }

  /// Custom Apple Pay button override
  var applePayButton: ((_ action: @escaping () -> Void) -> any View)? { get set }

  // MARK: - ViewBuilder Components
  // swiftlint:disable identifier_name
  /// Returns the default Apple Pay button view
  /// - Parameter action: The action to perform when the button is tapped
  /// - Returns: A SwiftUI view containing the Apple Pay button
  func PrimerApplePayButton(action: @escaping () -> Void) -> AnyView
  // swiftlint:enable identifier_name
}
