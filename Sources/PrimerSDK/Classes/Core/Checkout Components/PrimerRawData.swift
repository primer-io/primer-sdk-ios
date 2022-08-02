//
//  PrimerRawData.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/7/22.
//

#if canImport(UIKit)

import Foundation

public protocol PrimerRawData: Codable {
    var isValid: Bool { get }
}

public class PrimerCardData: PrimerRawData {
    
    var number: String
    var expiryMonth: String
    var expiryYear: String
    var cvv: String
    var cardholderName: String?
    
    public var isValid: Bool {
        return false
    }
    
    public init(
        number: String,
        expiryMonth: String,
        expiryYear: String,
        cvv: String,
        cardholderName: String?
    ) {
        self.number = number
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cvv = cvv
        self.cardholderName = cardholderName
    }
}

#endif
