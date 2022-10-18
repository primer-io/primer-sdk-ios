//
//  PrimerTestPaymentMethodPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

//
//  QRCodePaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class PrimerTestPaymentMethodPaymentModule: PaymentModule {
    
    override func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        precondition(false, "PrimerTestPaymentMethodPaymentModule does not need to handle required actions.")
        return Promise { seal in
            let err = PrimerError.generic(message: "PrimerTestPaymentMethodPaymentModule failed to handle decoded client token", userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
        }
    }
}

#endif
