//
//  PrimerPhoneNumberData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

#if canImport(UIKit)

import Foundation

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

#endif
