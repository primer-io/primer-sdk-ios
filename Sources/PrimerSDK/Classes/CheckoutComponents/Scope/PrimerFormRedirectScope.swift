//
//  PrimerFormRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Type Aliases for UI Customization

/// Type alias for form redirect screen customization component.
@available(iOS 15.0, *)
public typealias FormRedirectScreenComponent = (any PrimerFormRedirectScope) -> any View

/// Type alias for form redirect button customization component.
@available(iOS 15.0, *)
public typealias FormRedirectButtonComponent = (any PrimerFormRedirectScope) -> any View

/// Type alias for form redirect form section customization component.
@available(iOS 15.0, *)
public typealias FormRedirectFormSectionComponent = (any PrimerFormRedirectScope) -> any View

// MARK: - Scope Protocol

/// Scope protocol for form-based redirect payment methods (e.g., BLIK, MBWay).
///
/// Provides state observation, field management, and UI customization for payment methods
/// that require user input (OTP code or phone number) before completing payment
/// in an external app.
///
/// ## State Flow
/// ```
/// ready → submitting → awaitingExternalCompletion → success | failure
/// ```
///
/// ## Usage
/// ```swift
/// if let formScope = checkoutScope.getPaymentMethodScope(
///   PrimerFormRedirectScope.self
/// ) {
///   // Update a field value
///   formScope.updateField(.otpCode, value: "123456")
///
///   // Observe state
///   for await state in formScope.state {
///     if state.isSubmitEnabled {
///       // User can submit
///     }
///   }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerFormRedirectScope: PrimerPaymentMethodScope where State == PrimerFormRedirectState {

    /// Async stream emitting the current form redirect state whenever it changes.
    var state: AsyncStream<PrimerFormRedirectState> { get }

    /// The payment method type identifier (e.g., "ADYEN_BLIK", "ADYEN_MBWAY").
    var paymentMethodType: String { get }

    // MARK: - Field Management

    /// Updates the value of a form field.
    /// - Parameters:
    ///   - fieldType: The type of field to update (`.otpCode` or `.phoneNumber`).
    ///   - value: The new value for the field.
    func updateField(_ fieldType: PrimerFormFieldState.FieldType, value: String)

    // MARK: - Screen-Level Customization

    /// When set, replaces both form input and pending screens.
    var screen: FormRedirectScreenComponent? { get set }

    /// Custom form section component to replace the default form fields area.
    var formSection: FormRedirectFormSectionComponent? { get set }

    /// Custom button component to replace the submit button.
    var submitButton: FormRedirectButtonComponent? { get set }

    /// Custom text for the submit button (default: payment method specific, e.g., "Pay with BLIK").
    var submitButtonText: String? { get set }
}
