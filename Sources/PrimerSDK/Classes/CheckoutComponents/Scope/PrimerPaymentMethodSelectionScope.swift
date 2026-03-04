//
//  PrimerPaymentMethodSelectionScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Scope interface for payment method selection screen interactions and customization.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPaymentMethodSelectionScope: AnyObject {

  /// The current state of the payment method selection as an async stream.
  var state: AsyncStream<PrimerPaymentMethodSelectionState> { get }

  /// Controls how users can dismiss the checkout modal.
  var dismissalMechanism: [DismissalMechanism] { get }

  // MARK: - Navigation Methods

  /// Called when a payment method is selected by the user.
  /// - Parameter paymentMethod: The selected payment method.
  func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod)

  func cancel()

  // MARK: - Vault Payment Methods

  /// Initiates payment with the currently selected vaulted payment method.
  func payWithVaultedPaymentMethod() async

  /// Initiates payment with the currently selected vaulted payment method and CVV.
  /// - Parameter cvv: The CVV entered by the user
  func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async

  /// Updates the CVV input value and validates it.
  /// - Parameter cvv: The CVV value to update
  func updateCvvInput(_ cvv: String)

  /// Navigates to the screen showing all vaulted payment methods.
  func showAllVaultedPaymentMethods()

  /// Expands the payment methods section to show all available payment methods.
  /// Called when user taps "Show other ways to pay" button.
  func showOtherWaysToPay()

  // MARK: - Customizable UI Components

  /// Default implementation provides standard payment method grid/list.
  /// The closure receives the scope for full access to payment methods and navigation actions.
  var screen: PaymentMethodSelectionScreenComponent? { get set }

  /// Default implementation shows payment method with selection state.
  var paymentMethodItem: PaymentMethodItemComponent? { get set }

  /// Category header component for grouping payment methods.
  /// Default implementation shows category name in uppercase.
  var categoryHeader: CategoryHeaderComponent? { get set }

  /// Empty state view when no payment methods are available.
  /// Default implementation shows icon and message.
  var emptyStateView: Component? { get set }

  // MARK: - State Definition

}

/// Represents the current state of available payment methods and loading status.
public struct PrimerPaymentMethodSelectionState: Equatable {
  public internal(set) var paymentMethods: [CheckoutPaymentMethod] = []
  public internal(set) var isLoading: Bool = false
  public internal(set) var selectedPaymentMethod: CheckoutPaymentMethod?
  public internal(set) var searchQuery: String = ""
  public internal(set) var filteredPaymentMethods: [CheckoutPaymentMethod] = []
  public internal(set) var error: String?
  public internal(set) var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  public internal(set) var isVaultPaymentLoading: Bool = false

  // MARK: - CVV Recapture State

  /// Indicates whether CVV input is required for the selected vaulted card
  public internal(set) var requiresCvvInput: Bool = false

  /// The CVV value entered by the user
  public internal(set) var cvvInput: String = ""

  /// CVV validation state
  public internal(set) var isCvvValid: Bool = false

  /// CVV validation error message
  public internal(set) var cvvError: String?

  // MARK: - Payment Methods Expansion State

  /// Whether the payment methods section is expanded (showing all methods).
  /// Default is true. Set to false when user selects vaulted method or CVV input opens.
  public internal(set) var isPaymentMethodsExpanded: Bool = true

  public init(
    paymentMethods: [CheckoutPaymentMethod] = [],
    isLoading: Bool = false,
    selectedPaymentMethod: CheckoutPaymentMethod? = nil,
    searchQuery: String = "",
    filteredPaymentMethods: [CheckoutPaymentMethod] = [],
    error: String? = nil,
    selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? = nil,
    isVaultPaymentLoading: Bool = false,
    requiresCvvInput: Bool = false,
    cvvInput: String = "",
    isCvvValid: Bool = false,
    cvvError: String? = nil,
    isPaymentMethodsExpanded: Bool = true
  ) {
    self.paymentMethods = paymentMethods
    self.isLoading = isLoading
    self.selectedPaymentMethod = selectedPaymentMethod
    self.searchQuery = searchQuery
    self.filteredPaymentMethods = filteredPaymentMethods
    self.error = error
    self.selectedVaultedPaymentMethod = selectedVaultedPaymentMethod
    self.isVaultPaymentLoading = isVaultPaymentLoading
    self.requiresCvvInput = requiresCvvInput
    self.cvvInput = cvvInput
    self.isCvvValid = isCvvValid
    self.cvvError = cvvError
    self.isPaymentMethodsExpanded = isPaymentMethodsExpanded
  }

  public static func == (
    lhs: PrimerPaymentMethodSelectionState, rhs: PrimerPaymentMethodSelectionState
  ) -> Bool {
    lhs.paymentMethods == rhs.paymentMethods && lhs.isLoading == rhs.isLoading
      && lhs.selectedPaymentMethod == rhs.selectedPaymentMethod
      && lhs.searchQuery == rhs.searchQuery
      && lhs.filteredPaymentMethods == rhs.filteredPaymentMethods && lhs.error == rhs.error
      && lhs.selectedVaultedPaymentMethod?.id == rhs.selectedVaultedPaymentMethod?.id
      && lhs.isVaultPaymentLoading == rhs.isVaultPaymentLoading
      && lhs.requiresCvvInput == rhs.requiresCvvInput && lhs.cvvInput == rhs.cvvInput
      && lhs.isCvvValid == rhs.isCvvValid && lhs.cvvError == rhs.cvvError
      && lhs.isPaymentMethodsExpanded == rhs.isPaymentMethodsExpanded
  }
}

// MARK: - Payment Method Model

/// Represents a payment method available for selection in the checkout flow.
///
/// `CheckoutPaymentMethod` contains display information and metadata for payment methods
/// shown in the payment method selection screen. This includes the method's name, icon,
/// any applicable surcharges, and custom styling.
///
/// Use this struct when customizing the payment method selection UI or when handling
/// user selection events.
///
/// Example usage:
/// ```swift
/// for await state in selectionScope.state {
///     for method in state.paymentMethods {
///         print("\(method.name) - Surcharge: \(method.formattedSurcharge ?? "None")")
///     }
/// }
/// ```
public struct CheckoutPaymentMethod: Equatable, Identifiable {
  /// Unique identifier for this payment method instance.
  public let id: String

  /// The payment method type identifier (e.g., "PAYMENT_CARD", "PAYPAL", "APPLE_PAY").
  public let type: String

  /// Human-readable display name for the payment method.
  public let name: String

  /// Icon image to display for this payment method.
  public let icon: UIImage?

  /// Additional metadata associated with this payment method.
  public let metadata: [String: Any]?

  /// Surcharge amount in minor currency units (e.g., cents), if applicable.
  public let surcharge: Int?

  /// Indicates whether the surcharge amount is unknown (e.g., varies by card network).
  public let hasUnknownSurcharge: Bool

  /// Pre-formatted surcharge string for display (e.g., "+ $0.50").
  public let formattedSurcharge: String?

  /// Custom background color for the payment method button.
  public let backgroundColor: UIColor?

  /// Custom button text from display metadata (e.g., "Pay with Klarna").
  public let buttonText: String?

  /// Custom text color for the payment method button.
  public let textColor: UIColor?

  /// Custom border color for the payment method button.
  public let borderColor: UIColor?

  /// Custom border width for the payment method button.
  public let borderWidth: CGFloat?

  /// Custom corner radius for the payment method button.
  public let cornerRadius: CGFloat?

  public init(
    id: String,
    type: String,
    name: String,
    icon: UIImage? = nil,
    metadata: [String: Any]? = nil,
    surcharge: Int? = nil,
    hasUnknownSurcharge: Bool = false,
    formattedSurcharge: String? = nil,
    backgroundColor: UIColor? = nil,
    buttonText: String? = nil,
    textColor: UIColor? = nil,
    borderColor: UIColor? = nil,
    borderWidth: CGFloat? = nil,
    cornerRadius: CGFloat? = nil
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.icon = icon
    self.metadata = metadata
    self.surcharge = surcharge
    self.hasUnknownSurcharge = hasUnknownSurcharge
    self.formattedSurcharge = formattedSurcharge
    self.backgroundColor = backgroundColor
    self.buttonText = buttonText
    self.textColor = textColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.cornerRadius = cornerRadius
  }

  public static func == (lhs: CheckoutPaymentMethod, rhs: CheckoutPaymentMethod) -> Bool {
    lhs.id == rhs.id && lhs.type == rhs.type && lhs.name == rhs.name
      && lhs.surcharge == rhs.surcharge && lhs.hasUnknownSurcharge == rhs.hasUnknownSurcharge
      && lhs.formattedSurcharge == rhs.formattedSurcharge
      && lhs.backgroundColor == rhs.backgroundColor
  }
}
