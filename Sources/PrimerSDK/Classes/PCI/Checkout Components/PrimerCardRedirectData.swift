//
//  PrimerCardRedirectData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

import Foundation

public class PrimerBancontactCardData: PrimerRawData {

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
