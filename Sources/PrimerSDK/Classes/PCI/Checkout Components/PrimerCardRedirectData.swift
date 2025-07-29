//
//  PrimerCardRedirectData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class PrimerBancontactCardData: PrimerRawData {

    public var cardNumber: String {
        didSet {
            self.onDataDidChange?()
        }
    }
    public var expiryDate: String {
        didSet {
            self.onDataDidChange?()
        }
    }
    public var cardholderName: String {
        didSet {
            self.onDataDidChange?()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case cardNumber, expiryDate, cardholderName
    }

    public required init(
        cardNumber: String,
        expiryDate: String,
        cardholderName: String
    ) {
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cardholderName = cardholderName
        super.init()
    }
}
