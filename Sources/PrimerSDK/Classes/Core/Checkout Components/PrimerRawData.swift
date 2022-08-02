//
//  PrimerRawData.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/7/22.
//

#if canImport(UIKit)

import Foundation

internal protocol PrimerRawDataProtocol {
    var onDataDidChange: (() -> Void)? { get set }
}

public class PrimerRawData: NSObject, PrimerRawDataProtocol {
    var onDataDidChange: (() -> Void)?
}

public class PrimerCardData: PrimerRawData {
    
    public var number: String {
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
        
    public required init(
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
        super.init()
    }
}

#endif
