//
//  VaultedPaymentMethodPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 18/10/22.
//

#if canImport(UIKit)

import Foundation

class VaultedPaymentMethodPaymentModule: PaymentModule {
    
    override func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
    #if canImport(Primer3DS)
                guard let paymentMethodTokenData = self.paymentMethodTokenData else {
                    let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                    return
                }
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodTokenData: paymentMethodTokenData, protocolVersion: decodedJWTToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let resumeToken):
                        DispatchQueue.main.async {
                            seal.fulfill(resumeToken)
                        }
                        
                    case .failure(let err):
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                    }
                }
    #else
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
    #endif
                
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
}

#endif
