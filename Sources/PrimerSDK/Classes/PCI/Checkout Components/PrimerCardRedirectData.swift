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

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cardNumber, forKey: .cardNumber)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(cardholderName, forKey: .cardholderName)
    }
}
