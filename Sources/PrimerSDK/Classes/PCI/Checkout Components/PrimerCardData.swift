//
//  PrimerCardData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

import Foundation

public final class PrimerCardData: PrimerRawData {

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
    public var cvv: String {
        didSet {
            self.onDataDidChange?()
        }
    }
    public var cardholderName: String? {
        didSet {
            self.onDataDidChange?()
        }
    }

    public var cardNetwork: CardNetwork? {
        didSet {
            if cardNetwork != oldValue {
                self.onDataDidChange?()
            }
        }
    }

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
}
