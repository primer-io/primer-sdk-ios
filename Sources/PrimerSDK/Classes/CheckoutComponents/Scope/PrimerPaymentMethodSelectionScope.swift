//
//  PrimerPaymentMethodSelectionScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// Scope interface for payment method selection screen interactions and customization.
/// This protocol matches the Android Composable API exactly.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPaymentMethodSelectionScope: AnyObject {

    /// The current state of the payment method selection as an async stream.
    var state: AsyncStream<PrimerPaymentMethodSelectionState> { get }

    // MARK: - Navigation Methods

    /// Called when a payment method is selected by the user.
    /// - Parameter paymentMethod: The selected payment method.
    func onPaymentMethodSelected(paymentMethod: PrimerComposablePaymentMethod)

    /// Cancels payment method selection and dismisses the screen.
    func onCancel()

    // MARK: - Customizable UI Components

    /// The entire payment method selection screen.
    /// Default implementation provides standard payment method grid/list.
    var screen: (() -> AnyView)? { get set }

    /// Individual payment method item component.
    /// Default implementation shows payment method with selection state.
    var paymentMethodItem: ((_ paymentMethod: PrimerComposablePaymentMethod) -> AnyView)? { get set }

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
    public var paymentMethods: [PrimerComposablePaymentMethod] = []

    /// Indicates if payment methods are being loaded.
    public var isLoading: Bool = false

    /// The currently selected payment method.
    public var selectedPaymentMethod: PrimerComposablePaymentMethod?

    /// Current search query for filtering payment methods.
    public var searchQuery: String = ""

    /// Filtered payment methods based on search query.
    public var filteredPaymentMethods: [PrimerComposablePaymentMethod] = []

    /// Payment methods organized by category.
    public var categorizedPaymentMethods: [(category: String, methods: [PrimerComposablePaymentMethod])] = []

    /// Error message if any operation fails.
    public var error: String?

    public init(
        paymentMethods: [PrimerComposablePaymentMethod] = [],
        isLoading: Bool = false,
        selectedPaymentMethod: PrimerComposablePaymentMethod? = nil,
        searchQuery: String = "",
        filteredPaymentMethods: [PrimerComposablePaymentMethod] = [],
        categorizedPaymentMethods: [(category: String, methods: [PrimerComposablePaymentMethod])] = [],
        error: String? = nil
    ) {
        self.paymentMethods = paymentMethods
        self.isLoading = isLoading
        self.selectedPaymentMethod = selectedPaymentMethod
        self.searchQuery = searchQuery
        self.filteredPaymentMethods = filteredPaymentMethods
        self.categorizedPaymentMethods = categorizedPaymentMethods
        self.error = error
    }

    public static func == (lhs: PrimerPaymentMethodSelectionState, rhs: PrimerPaymentMethodSelectionState) -> Bool {
        return lhs.paymentMethods == rhs.paymentMethods &&
            lhs.isLoading == rhs.isLoading &&
            lhs.selectedPaymentMethod == rhs.selectedPaymentMethod &&
            lhs.searchQuery == rhs.searchQuery &&
            lhs.filteredPaymentMethods == rhs.filteredPaymentMethods &&
            lhs.error == rhs.error &&
            lhs.categorizedPaymentMethods.count == rhs.categorizedPaymentMethods.count &&
            zip(lhs.categorizedPaymentMethods, rhs.categorizedPaymentMethods).allSatisfy { left, right in
                left.category == right.category && left.methods == right.methods
            }
    }
}

// MARK: - Payment Method Model

/// Represents a payment method available for selection.
/// This is the public model exposed through the scope interface.
public struct PrimerComposablePaymentMethod: Equatable, Identifiable {
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

    // Android parity: Surcharge support
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

    public static func == (lhs: PrimerComposablePaymentMethod, rhs: PrimerComposablePaymentMethod) -> Bool {
        lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.name == rhs.name &&
            lhs.surcharge == rhs.surcharge &&
            lhs.hasUnknownSurcharge == rhs.hasUnknownSurcharge &&
            lhs.formattedSurcharge == rhs.formattedSurcharge &&
            lhs.backgroundColor == rhs.backgroundColor
    }
}
