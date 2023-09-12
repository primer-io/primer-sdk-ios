//
//  AdyenDotPay.swift
//  PrimerSDK
//
//  Created by Admin on 8/11/21.
//



import Foundation

typealias AdyenBank = Response.Body.Adyen.Bank

extension Request.Body {
    class Adyen {}
}

extension Response.Body {
    class Adyen {}
}

extension Request.Body.Adyen {
    
    struct BanksList: Encodable {
        
        let paymentMethodConfigId: String
        let command: String = "FETCH_BANK_ISSUERS"
        let parameters: BankTokenizationSessionRequestParameters
    }
}

internal struct BankTokenizationSessionRequestParameters: Encodable {
    let paymentMethod: String
}

extension Response.Body.Adyen {
    
    struct Bank: Decodable {
        
        let id: String
        let name: String
        let iconUrlStr: String?
        lazy var iconUrl: URL? = {
            guard let iconUrlStr = iconUrlStr else { return nil }
            return URL(string: iconUrlStr)
        }()
        let disabled: Bool
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case iconUrlStr = "iconUrl"
            case disabled
        }
    }
}

internal struct BanksListSessionResponse: Decodable {
    let result: [Response.Body.Adyen.Bank]
}


