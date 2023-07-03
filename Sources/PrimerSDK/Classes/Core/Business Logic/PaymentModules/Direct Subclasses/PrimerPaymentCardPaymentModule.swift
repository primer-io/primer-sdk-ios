//
//  PrimerPaymentCardPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerPaymentCardPaymentModule: PrimerPaymentModule {
    
    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                
            } else if decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue {
                
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
}

#endif
