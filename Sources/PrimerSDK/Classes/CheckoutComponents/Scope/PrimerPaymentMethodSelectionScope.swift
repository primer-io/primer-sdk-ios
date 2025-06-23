//
//  PrimerPaymentMethodSelectionScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Scope interface for payment method selection screen interactions and customization.
/// This protocol matches the Android Composable API exactly.
@MainActor
public protocol PrimerPaymentMethodSelectionScope: AnyObject {
    
    /// The current state of the payment method selection as an async stream.
    var state: AsyncStream<State> { get }
    
    // MARK: - Navigation Methods
    
    /// Called when a payment method is selected by the user.
    /// - Parameter paymentMethod: The selected payment method.
    func onPaymentMethodSelected(paymentMethod: PrimerComposablePaymentMethod)
    
    /// Cancels payment method selection and dismisses the screen.
    func onCancel()
    
    // MARK: - Customizable UI Components
    
    /// The entire payment method selection screen.
    /// Default implementation provides standard payment method grid/list.
    var screen: (@ViewBuilder () -> any View)? { get set }
    
    /// Individual payment method card/tile component.
    /// Default implementation shows payment method icon and name.
    var paymentMethodCard: (@ViewBuilder (_ modifier: PrimerModifier, _ onPaymentMethodSelected: @escaping () -> Void) -> any View)? { get set }
    
    // MARK: - State Definition
    
    /// Represents the current state of available payment methods and loading status.
    struct State: Equatable {
        /// List of available payment methods.
        public var paymentMethods: [PrimerComposablePaymentMethod] = []
        
        /// Indicates if payment methods are being loaded.
        public var isLoading: Bool = false
        
        public init(
            paymentMethods: [PrimerComposablePaymentMethod] = [],
            isLoading: Bool = false
        ) {
            self.paymentMethods = paymentMethods
            self.isLoading = isLoading
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
    
    public init(
        id: String,
        type: String,
        name: String,
        icon: UIImage? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.icon = icon
        self.metadata = metadata
    }
    
    public static func == (lhs: PrimerComposablePaymentMethod, rhs: PrimerComposablePaymentMethod) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.name == rhs.name
    }
}