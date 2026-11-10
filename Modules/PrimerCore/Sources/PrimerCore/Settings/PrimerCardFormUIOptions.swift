//
//  PrimerCardFormUIOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public struct PrimerCardFormUIOptions: Codable {
    /// When true, Drop-In’s card form pay button shows “Add new card” instead of “Pay $x.xx”
    public let payButtonAddNewCard: Bool
    public let payButtonText: String?

    /// Initializes `PrimerCardFormUIOptions`
    /// - Parameter payButtonAddNewCard: Indicates whether to show “Add new card” instead of “Pay $x.xx”
    public init(payButtonAddNewCard: Bool = false, payButtonText: String? = nil) {
        self.payButtonAddNewCard = payButtonAddNewCard
        self.payButtonText = payButtonText
    }

    private enum CodingKeys: String, CodingKey {
        case payButtonAddNewCard, payButtonText
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payButtonAddNewCard = try container.decodeIfPresent(Bool.self, forKey: .payButtonAddNewCard) ?? false
        payButtonText = try container.decodeIfPresent(String.self, forKey: .payButtonText)
    }
}
