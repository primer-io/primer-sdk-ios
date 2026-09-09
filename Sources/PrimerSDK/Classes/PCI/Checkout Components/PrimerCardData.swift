//
//  PrimerCardData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class PrimerCardData: PrimerRawData {

    public var cardNumber: String {
        didSet {
            onDataDidChange?()
        }
    }
    public var expiryDate: String {
        didSet {
            onDataDidChange?()
        }
    }
    public var cvv: String {
        didSet {
            onDataDidChange?()
        }
    }
    public var cardholderName: String? {
        didSet {
            onDataDidChange?()
        }
    }

    // Note: cardNetwork is derived/detected data, not user input.
    // It intentionally does not have a didSet that triggers onDataDidChange() to avoid duplicate validations.
    // The validation flow already receives this value through the rawData parameter.
    public var cardNetwork: CardNetwork?

    private enum CodingKeys: String, CodingKey {
        case cardNumber,
             expiryDate,
             cvv,
             cardholderName,
             cardNetworkIdentifier
    }

    public required init(
        cardNumber: String,
        expiryDate: String,
        cvv: String,
        cardholderName: String?,
        cardNetwork: CardNetwork? = nil
    ) {
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.cardholderName = cardholderName
        self.cardNetwork = cardNetwork
        super.init()
    }

    func wipe() {
        cardNumber = ""
        expiryDate = ""
        cvv = ""
        cardholderName = nil
        cardNetwork = nil
    }
}
