//
//  PrimerCardRedirectData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

#if canImport(UIKit)

import Foundation

public class PrimerCardRedirectData: PrimerRawData {}

public class PrimerBancontactCardRedirectData: PrimerCardRedirectData {
    
    public var cardNumber: String {
        didSet {
            self.onDataDidChange?()
        }
    }
    public var expiryMonth: String {
        didSet {
            self.onDataDidChange?()
        }
    }
    public var expiryYear: String {
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
        case cardNumber, expiryMonth, expiryYear, cardholderName
    }
        
    public required init(
        cardNumber: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String
    ) {
        self.cardNumber = cardNumber
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cardholderName = cardholderName
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cardNumber, forKey: .cardNumber)
        try container.encode(expiryMonth, forKey: .expiryMonth)
        try container.encode(expiryYear, forKey: .expiryYear)
        try container.encode(cardholderName, forKey: .cardholderName)
    }
}

#endif
