//
//  PrimerCardPaymentOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

/// Defines how the card network selector is displayed for co-badged cards
public enum CardNetworkSelectorStyle: String, Codable {
    /// Inline badge buttons (legacy style)
    case inline
    /// Dropdown menu with chevron (default)
    case dropdown
}

public final class PrimerCardPaymentOptions: Codable {

    let is3DSOnVaultingEnabled: Bool

    /// The style of card network selector for co-badged cards (default: .dropdown)
    public let networkSelectorStyle: CardNetworkSelectorStyle

    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    public init(is3DSOnVaultingEnabled: Bool?) {
        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled ?? true
        networkSelectorStyle = .dropdown
    }

    public init(networkSelectorStyle: CardNetworkSelectorStyle = .dropdown) {
        is3DSOnVaultingEnabled = true
        self.networkSelectorStyle = networkSelectorStyle
    }
}
