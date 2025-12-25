//
//  ApplePayFormState.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit

// MARK: - Apple Pay Form State

/// State model for Apple Pay payment method in CheckoutComponents.
/// Manages the UI state and configuration for Apple Pay button and payment flow.
@available(iOS 15.0, *)
public struct ApplePayFormState: Equatable {

    // MARK: - Loading States

    /// Indicates if the Apple Pay flow is currently processing
    public var isLoading: Bool

    // MARK: - Availability

    /// Indicates if Apple Pay is available on this device
    public var isAvailable: Bool

    /// Error message if Apple Pay is not available
    public var availabilityError: String?

    // MARK: - Button Customization

    /// The style of the Apple Pay button (.black, .white, .whiteOutline, .automatic)
    public var buttonStyle: PKPaymentButtonStyle

    /// The type of the Apple Pay button (.plain, .buy, .setUp, .checkout, etc.)
    public var buttonType: PKPaymentButtonType

    /// The corner radius of the Apple Pay button
    public var cornerRadius: CGFloat

    // MARK: - Initialization

    public init(
        isLoading: Bool = false,
        isAvailable: Bool = false,
        availabilityError: String? = nil,
        buttonStyle: PKPaymentButtonStyle = .black,
        buttonType: PKPaymentButtonType = .plain,
        cornerRadius: CGFloat = 8.0
    ) {
        self.isLoading = isLoading
        self.isAvailable = isAvailable
        self.availabilityError = availabilityError
        self.buttonStyle = buttonStyle
        self.buttonType = buttonType
        self.cornerRadius = cornerRadius
    }

    // MARK: - Static Factory Methods

    /// Default state for Apple Pay
    public static var `default`: ApplePayFormState {
        ApplePayFormState()
    }

    /// State when Apple Pay is available and ready
    public static func available(
        buttonStyle: PKPaymentButtonStyle = .black,
        buttonType: PKPaymentButtonType = .plain,
        cornerRadius: CGFloat = 8.0
    ) -> ApplePayFormState {
        ApplePayFormState(
            isLoading: false,
            isAvailable: true,
            availabilityError: nil,
            buttonStyle: buttonStyle,
            buttonType: buttonType,
            cornerRadius: cornerRadius
        )
    }

    /// State when Apple Pay is not available
    public static func unavailable(error: String) -> ApplePayFormState {
        ApplePayFormState(
            isLoading: false,
            isAvailable: false,
            availabilityError: error
        )
    }

    /// State when Apple Pay is loading/processing
    public static var loading: ApplePayFormState {
        ApplePayFormState(
            isLoading: true,
            isAvailable: true,
            availabilityError: nil
        )
    }
}
