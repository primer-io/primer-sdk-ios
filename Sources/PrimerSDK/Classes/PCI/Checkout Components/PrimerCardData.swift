//
//  PrimerCardData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//



import Foundation

public class PrimerCardData: PrimerRawData {
    
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
    
    public var cardNetworkIdentifier: String? {
        didSet {
            self.onDataDidChange?()
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case cardNumber, expiryDate, cvv, cardholderName, cardNetworkIdentifier
    }
        
    public required init(
        cardNumber: String,
        expiryDate: String,
        cvv: String,
        cardholderName: String?
    ) {
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.cardholderName = cardholderName
        self.cardNetworkIdentifier = nil
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cardNumber, forKey: .cardNumber)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardholderName, forKey: .cardholderName)
        if let cni = cardNetworkIdentifier {
            try container.encode(cni, forKey: .cardNetworkIdentifier)
        }
    }
}


