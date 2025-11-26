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

    /// Controls how users can dismiss the checkout modal.
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Navigation Methods

    /// Called when a payment method is selected by the user.
    /// - Parameter paymentMethod: The selected payment method.
    func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod)

    func onCancel()

    // MARK: - Customizable UI Components

    /// Default implementation provides standard payment method grid/list.
    /// The closure receives the scope for full access to payment methods and navigation actions.
    var screen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)? { get set }

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
    public var paymentMethods: [CheckoutPaymentMethod] = []
    public var isLoading: Bool = false
    public var selectedPaymentMethod: CheckoutPaymentMethod?
    public var searchQuery: String = ""
    public var filteredPaymentMethods: [CheckoutPaymentMethod] = []
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

public struct CheckoutPaymentMethod: Equatable, Identifiable {
    public let id: String
    public let type: String
    public let name: String
    public let icon: UIImage?
    public let metadata: [String: Any]?
    public let surcharge: Int?
    public let hasUnknownSurcharge: Bool
    public let formattedSurcharge: String?
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
