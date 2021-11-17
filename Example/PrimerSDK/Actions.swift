//
//  Actions.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 17/11/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation


struct CaptureData: Encodable {
    let capture: Bool
    let required: Bool
}

struct SetInputAction: Encodable {
    let type: String
    let params: Array<Param>
    
    struct Param: Encodable {
        var cardInformation: CardInformation? = nil
        var billingAddress: BillingAddress? = nil
    }
    
    struct CardInformation: Encodable {
        var cardholderName: CaptureData
    }
    
    struct BillingAddress: Encodable {
        var postalCode: CaptureData
    }
}
