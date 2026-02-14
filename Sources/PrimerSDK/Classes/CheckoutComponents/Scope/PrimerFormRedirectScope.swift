//
//  PrimerFormRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Type Aliases for UI Customization

@available(iOS 15.0, *)
public typealias FormRedirectScreenComponent = (any PrimerFormRedirectScope) -> any View

@available(iOS 15.0, *)
public typealias FormRedirectButtonComponent = (any PrimerFormRedirectScope) -> any View

@available(iOS 15.0, *)
public typealias FormRedirectFormSectionComponent = (any PrimerFormRedirectScope) -> any View

// MARK: - Scope Protocol

/// Scope for form-based redirect payment methods (BLIK, MBWay).
/// Provides state observation, field management, and UI customization for form-based APMs
/// that require user input before completing payment in an external app.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerFormRedirectScope: PrimerPaymentMethodScope where State == FormRedirectState {

    // MARK: - State

    var state: AsyncStream<FormRedirectState> { get }
    var paymentMethodType: String { get }
    var presentationContext: PresentationContext { get }
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Payment Method Lifecycle

    /// Called when the scope becomes active; initializes field configuration.
    func start()

    /// Initiates the payment flow (tokenization + polling).
    /// - Precondition: All fields must be valid (`isSubmitEnabled == true`)
    func submit()

    func cancel()

    // MARK: - Field Management

    func updateField(_ fieldType: FormFieldState.FieldType, value: String)

    // MARK: - Navigation Methods

    func onBack()
    func onCancel()

    // MARK: - Screen-Level Customization

    /// When set, replaces both form input and pending screens.
    var screen: FormRedirectScreenComponent? { get set }

    var formSection: FormRedirectFormSectionComponent? { get set }
    var submitButton: FormRedirectButtonComponent? { get set }

    /// Default: payment method specific (e.g., "Pay with BLIK")
    var submitButtonText: String? { get set }
}

// MARK: - Default Implementations

@available(iOS 15.0, *)
extension PrimerFormRedirectScope {

    public func onBack() {
        cancel()
    }

    public func onCancel() {
        cancel()
    }
}
