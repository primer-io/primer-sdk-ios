//
//  PrimerApplePayValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerApplePayValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        
        if PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "order.countryCode",
                value: nil,
                allowedValue: "Any country code",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        if PrimerSettings.current.paymentMethodOptions.applePayOptions == nil {
            let err = PrimerError.invalidMerchantIdentifier(
                merchantIdentifier: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        try super.throwErrors()
    }
}

#endif
