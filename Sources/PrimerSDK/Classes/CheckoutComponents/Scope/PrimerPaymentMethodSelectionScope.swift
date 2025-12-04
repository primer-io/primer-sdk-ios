//
//  PrimerPaymentMethodSelectionScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Scope interface for payment method selection screen interactions and customization.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPaymentMethodSelectionScope: AnyObject {

    /// The current state of the payment method selection as an async stream.
    var state: AsyncStream<PrimerPaymentMethodSelectionState> { get }

    /// Available dismissal mechanisms (gestures, close button) from settings.
    /// Controls how users can dismiss the checkout modal.
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Navigation Methods

    /// Called when a payment method is selected by the user.
    /// - Parameter paymentMethod: The selected payment method.
    func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod)

    /// Cancels payment method selection and dismisses the screen.
    func onCancel()

    // MARK: - Customizable UI Components

    /// The entire payment method selection screen.
    /// Default implementation provides standard payment method grid/list.
    /// The closure receives the scope for full access to payment methods and navigation actions.
    var screen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)? { get set }

    /// Individual payment method item component.
    /// Default implementation shows payment method with selection state.
    var paymentMethodItem: ((_ paymentMethod: CheckoutPaymentMethod) -> AnyView)? { get set }

    /// Category header component for grouping payment methods.
    /// Default implementation shows category name in uppercase.
    var categoryHeader: ((_ category: String) -> AnyView)? { get set }

    /// Empty state view when no payment methods are available.
    /// Default implementation shows icon and message.
    var emptyStateView: (() -> AnyView)? { get set }

    // MARK: - State Definition

}

/// Represents the current state of available payment methods and loading status.
public struct PrimerPaymentMethodSelectionState: Equatable {
    /// List of available payment methods.
    public var paymentMethods: [CheckoutPaymentMethod] = []

    /// Indicates if payment methods are being loaded.
    public var isLoading: Bool = false

    /// The currently selected payment method.
    public var selectedPaymentMethod: CheckoutPaymentMethod?

    /// Current search query for filtering payment methods.
    public var searchQuery: String = ""

    /// Filtered payment methods based on search query.
    public var filteredPaymentMethods: [CheckoutPaymentMethod] = []

    /// Error message if any operation fails.
    public var error: String?

    public init(
        paymentMethods: [CheckoutPaymentMethod] = [],
        isLoading: Bool = false,
        selectedPaymentMethod: CheckoutPaymentMethod? = nil,
        searchQuery: String = "",
        filteredPaymentMethods: [CheckoutPaymentMethod] = [],
        error: String? = nil
    ) {
        self.paymentMethods = paymentMethods
        self.isLoading = isLoading
        self.selectedPaymentMethod = selectedPaymentMethod
        self.searchQuery = searchQuery
        self.filteredPaymentMethods = filteredPaymentMethods
        self.error = error
    }

    public static func == (lhs: PrimerPaymentMethodSelectionState, rhs: PrimerPaymentMethodSelectionState) -> Bool {
        lhs.paymentMethods == rhs.paymentMethods &&
            lhs.isLoading == rhs.isLoading &&
            lhs.selectedPaymentMethod == rhs.selectedPaymentMethod &&
            lhs.searchQuery == rhs.searchQuery &&
            lhs.filteredPaymentMethods == rhs.filteredPaymentMethods &&
            lhs.error == rhs.error
    }
}

// MARK: - Payment Method Model

/// Represents a payment method available for selection.
/// This is the public model exposed through the scope interface.
public struct CheckoutPaymentMethod: Equatable, Identifiable {
    /// Unique identifier for the payment method.
    public let id: String

    /// Payment method type (e.g., "PAYMENT_CARD", "PAYPAL", etc.).
    public let type: String

    /// Display name for the payment method.
    public let name: String

    /// Optional icon image for the payment method.
    public let icon: UIImage?

    /// Additional metadata about the payment method.
    public let metadata: [String: Any]?

    /// Raw surcharge amount in minor currency units (e.g., 500 for $5.00).
    public let surcharge: Int?

    /// Indicates if surcharge amount is unknown ("Fee may apply").
    public let hasUnknownSurcharge: Bool

    /// Pre-formatted surcharge display string (e.g., "+$5.00", "No additional fee").
    public let formattedSurcharge: String?

    /// Dynamic background color from server configuration.
    public let backgroundColor: UIColor?

    public init(
        id: String,
        type: String,
        name: String,
        icon: UIImage? = nil,
        metadata: [String: Any]? = nil,
        surcharge: Int? = nil,
        hasUnknownSurcharge: Bool = false,
        formattedSurcharge: String? = nil,
        backgroundColor: UIColor? = nil
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
    }

    public static func == (lhs: CheckoutPaymentMethod, rhs: CheckoutPaymentMethod) -> Bool {
        lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.name == rhs.name &&
            lhs.surcharge == rhs.surcharge &&
            lhs.hasUnknownSurcharge == rhs.hasUnknownSurcharge &&
            lhs.formattedSurcharge == rhs.formattedSurcharge &&
            lhs.backgroundColor == rhs.backgroundColor
    }
}
