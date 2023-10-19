//
//  NolPaySecretDataRequest.swift
//  PrimerSDK
//
//  Created by Boris on 20.9.23..
//

import Foundation

// Request
extension Request.Body {
    class NolPay {}
}

extension Request.Body.NolPay {
    
    struct NolPaySecretDataRequest: Codable {
        
        let nolSdkId: String
        let nolAppId: String
        let phoneVendor: String
        let phoneModel: String
    }
}

// Response
extension Response.Body {
    class NolPay {}
}

extension Response.Body.NolPay {
    struct NolPaySecretDataResponse: Codable {
        
        let sdkSecret: String
    }
}
