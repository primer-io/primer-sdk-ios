//
//  Bank.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

#if canImport(UIKit)

import Foundation

extension PaymentMethod {
    
    struct Bank: Codable {
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
        
        class Session {
            struct Request: Codable {
                let paymentMethodConfigId: String
                let command: String = "FETCH_BANK_ISSUERS"
                let parameters: PaymentMethod.Bank.Session.Request.Parameters
                
                internal struct Parameters: Codable {
                    let paymentMethod: String
                }
            }
            
            struct Response: Codable {
                let result: [PaymentMethod.Bank]
            }
        }
    }
    
}

#endif

