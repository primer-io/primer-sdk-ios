//
//  PrimerCardNetworkTraits.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Read-only traits of a card network — digit grouping, length constraints, and CVV configuration.
///
/// Access via ``CardNetwork/traits`` or
/// ``PrimerHeadlessUniversalCheckout/AssetsManager/getCardNetworkTraits(for:)``. Returns `nil` for
/// networks without known validation rules (e.g. `.bancontact`, `.cartesBancaires`, `.eftpos`, `.unknown`).
public struct PrimerCardNetworkTraits {
    public let cardNetwork: CardNetwork
    public let displayName: String
    public let panLengths: [Int]
    public let gapPattern: [Int]
    public let cvvLength: Int
    public let cvvLabel: String
}
