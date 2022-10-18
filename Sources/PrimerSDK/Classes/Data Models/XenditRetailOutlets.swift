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

internal struct RetailOutletsListSessionResponse: Decodable {
    let result: [RetailOutletsRetail]
}

@objc public class RetailOutletsList: PrimerInitializationData {
    
    public let result: [RetailOutletsRetail]
    
    public init(result: [RetailOutletsRetail]) {
        self.result = result
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}


#endif
