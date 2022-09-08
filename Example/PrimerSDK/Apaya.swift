//
//  Apaya.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 20/9/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import PrimerSDK

class ApayaViewModel {
    
    var carrier: ApayaCarrier
    var hashedIdentifier: String?
    
    init?(paymentMethod: PrimerPaymentMethodTokenData) {
        guard paymentMethod.paymentInstrumentType == .apayaToken else { return nil }
        guard let mcc = paymentMethod.paymentInstrumentData?.mcc,
              let mnc = paymentMethod.paymentInstrumentData?.mnc,
              let carrier = ApayaCarrier(mcc: mcc, mnc: mnc)
        else { return nil }
        
        self.carrier = carrier
        self.hashedIdentifier = paymentMethod.paymentInstrumentData?.hashedIdentifier
    }
    
}

enum ApayaCarrier: String, Codable {
    case EE_UK, O2_UK, Vodafone_UK, Three_UK, Strex_Norway
    
    var name: String {
        switch self {
        case .EE_UK:
            return "EE UK"
        case .O2_UK:
            return "O2 UK"
        case .Vodafone_UK:
            return "Vodafone UK"
        case .Three_UK:
            return "Three UK"
        case .Strex_Norway:
            return "Strex Norway"
        }
    }
    
    var mcc: Int {
        switch self {
        case .EE_UK:
            return 234
        case .O2_UK:
            return 234
        case .Vodafone_UK:
            return 234
        case .Three_UK:
            return 234
        case .Strex_Norway:
            return 242
        }
    }
    
    var mnc: Int {
        switch self {
        case .EE_UK:
            return 99
        case .O2_UK:
            return 11
        case .Vodafone_UK:
            return 15
        case .Three_UK:
            return 20
        case .Strex_Norway:
            return 99
        }
    }
    
    init?(mcc: Int, mnc: Int) {
        switch (mcc, mnc) {
        case (234, 99):
            self = .EE_UK
        case (234, 11):
            self = .O2_UK
        case (234, 15):
            self = .Vodafone_UK
        case (234, 20):
            self = .Three_UK
        case (242, 99):
            self = .Strex_Norway
        default:
            return nil
        }
    }
    
}
