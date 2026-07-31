//
//  CardType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

/// Card funding type used to filter which cards Apple Pay offers.
public enum CardType: String, Codable {
    case credit
    case debit
}
