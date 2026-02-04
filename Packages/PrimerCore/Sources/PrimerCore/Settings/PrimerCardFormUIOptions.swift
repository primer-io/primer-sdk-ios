//
//  PrimerCardFormUIOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public struct PrimerCardFormUIOptions: Codable {
    /// When true, Drop-In’s card form pay button shows “Add new card” instead of “Pay $x.xx”
    public let payButtonAddNewCard: Bool

    /// Initializes `PrimerCardFormUIOptions`
    /// - Parameter payButtonAddNewCard: Indicates whether to show “Add new card” instead of “Pay $x.xx”
    public init(payButtonAddNewCard: Bool = false) {
        self.payButtonAddNewCard = payButtonAddNewCard
    }
}
