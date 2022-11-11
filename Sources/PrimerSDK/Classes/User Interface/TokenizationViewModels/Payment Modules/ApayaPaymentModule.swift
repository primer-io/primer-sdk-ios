//
//  ApayaPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class ApayaPaymentModule: PaymentModule {
    
    override func awaitDecodedJWTTokenHandlingIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        precondition(false, "ApayaPaymentModule does not need to handle required actions.")
        return Promise { seal in
            let err = PrimerError.generic(message: "ApayaPaymentModule failed to handle decoded client token", userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
        }
    }
}

#endif
