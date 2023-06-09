//
//  XenditRetailOutlets.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/10/22.
//

#if canImport(UIKit)

import Foundation

extension Request.Body {
    class Xendit {}
}

extension Response.Body {
    class Xendit {}
}

extension Request.Body.Xendit {
    
    struct RetailOutletsList: Encodable {
        let paymentMethodConfigId: String
    }
}

internal struct RetailOutletTokenizationSessionRequestParameters: OffSessionPaymentSessionInfo {
    let locale: String = PrimerSettings.current.localeData.localeCode
    let platform: String = "IOS"
    let retailOutlet: String
}

@objc public class RetailOutletsList: PrimerInitializationData {
    
    public let result: [RetailOutletsRetail]
    
    private enum CodingKeys : String, CodingKey {
        case result
    }
    
    init(result: [RetailOutletsRetail]) {
        self.result = result
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode([RetailOutletsRetail].self, forKey: .result)
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(result, forKey: .result)
    }
}


#endif
