//
//  CardNetworkSelectorStyle.swift
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
