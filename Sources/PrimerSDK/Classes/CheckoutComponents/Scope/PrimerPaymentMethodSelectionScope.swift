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

    /// The currently selected vaulted payment method, if any.
    var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? { get }

    // MARK: - Navigation Methods

    /// Called when a payment method is selected by the user.
    /// - Parameter paymentMethod: The selected payment method.
    func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod)

    func onCancel()

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
    public var paymentMethods: [CheckoutPaymentMethod] = []
    public var isLoading: Bool = false
    public var selectedPaymentMethod: CheckoutPaymentMethod?
    public var searchQuery: String = ""
    public var filteredPaymentMethods: [CheckoutPaymentMethod] = []
    public var error: String?
    public var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
    public var isVaultPaymentLoading: Bool = false

    // MARK: - CVV Recapture State

    /// Indicates whether CVV input is required for the selected vaulted card
    public var requiresCvvInput: Bool = false

    /// The CVV value entered by the user
    public var cvvInput: String = ""

    /// CVV validation state
    public var isCvvValid: Bool = false

    /// CVV validation error message
    public var cvvError: String?

    // MARK: - Payment Methods Expansion State

    /// Whether the payment methods section is expanded (showing all methods).
    /// Default is true. Set to false when user selects vaulted method or CVV input opens.
    public var isPaymentMethodsExpanded: Bool = true

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

    public static func == (lhs: PrimerPaymentMethodSelectionState, rhs: PrimerPaymentMethodSelectionState) -> Bool {
        lhs.paymentMethods == rhs.paymentMethods &&
            lhs.isLoading == rhs.isLoading &&
            lhs.selectedPaymentMethod == rhs.selectedPaymentMethod &&
            lhs.searchQuery == rhs.searchQuery &&
            lhs.filteredPaymentMethods == rhs.filteredPaymentMethods &&
            lhs.error == rhs.error &&
            lhs.selectedVaultedPaymentMethod?.id == rhs.selectedVaultedPaymentMethod?.id &&
            lhs.isVaultPaymentLoading == rhs.isVaultPaymentLoading &&
            lhs.requiresCvvInput == rhs.requiresCvvInput &&
            lhs.cvvInput == rhs.cvvInput &&
            lhs.isCvvValid == rhs.isCvvValid &&
            lhs.cvvError == rhs.cvvError &&
            lhs.isPaymentMethodsExpanded == rhs.isPaymentMethodsExpanded
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
