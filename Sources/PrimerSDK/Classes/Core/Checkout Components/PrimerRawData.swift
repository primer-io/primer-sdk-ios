//
//  PrimerRawData.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/7/22.
//

#if canImport(UIKit)

import Foundation

internal protocol PrimerRawDataProtocol: Encodable {
    var onDataDidChange: (() -> Void)? { get set }
}

public class PrimerRawData: NSObject, PrimerRawDataProtocol {
    
    var onDataDidChange: (() -> Void)?
    
    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}

public class PrimerPhoneNumberData: PrimerRawData {
    
    public var phoneNumber: String {
        didSet {
            self.onDataDidChange?()
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case phoneNumber
    }
    
    public required init(
        phoneNumber: String
    ) {
        self.phoneNumber = phoneNumber
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phoneNumber, forKey: .phoneNumber)
    }
}

public class PrimerCardData: PrimerRawData {
    
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
    
    private enum CodingKeys: String, CodingKey {
        case cardNumber, expiryMonth, expiryYear, cvv, cardholderName
    }
        
    public required init(
        cardNumber: String,
        expiryMonth: String,
        expiryYear: String,
        cvv: String,
        cardholderName: String?
    ) {
        self.cardNumber = cardNumber
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cvv = cvv
        self.cardholderName = cardholderName
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cardNumber, forKey: .cardNumber)
        try container.encode(expiryMonth, forKey: .expiryMonth)
        try container.encode(expiryYear, forKey: .expiryYear)
        try container.encode(cvv, forKey: .cvv)
        try container.encode(cardholderName, forKey: .cardholderName)
    }
}

#endif
