//
//  VaultedPaymentMethodDisplayData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

/// Normalized display data for vaulted payment methods across different payment types.
/// This struct provides a unified interface for rendering vaulted payment method cards
/// regardless of the underlying payment instrument type (card, PayPal, ACH, etc.).
@available(iOS 15.0, *)
struct VaultedPaymentMethodDisplayData {
    /// Cardholder or account holder name. When nil, the name row should be hidden entirely.
    let name: String?

    /// Brand icon image (e.g., Visa logo, PayPal icon).
    let brandIcon: UIImage?

    /// Brand name for display (e.g., "Visa", "PayPal", "Chase (ACH)").
    let brandName: String

    /// Primary display value (e.g., "•••• 1234" for cards, "jo••••@gmail.com" for PayPal).
    /// When nil, the primary value should be hidden.
    let primaryValue: String?

    /// Secondary display value (e.g., "Expires 12/26" for cards).
    /// When nil, the secondary value should be hidden.
    let secondaryValue: String?

    /// VoiceOver accessibility label describing the complete payment method.
    let accessibilityLabel: String
}
