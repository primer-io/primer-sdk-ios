//
//  PrimerApayaValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerApayaValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
            
        if PrimerAPIConfigurationModule.apiConfiguration?.getProductId(for: PrimerPaymentMethodType.apaya.rawValue) == nil {
            let err = PrimerError.invalidValue(
                key: "productId",
                value: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        try super.throwErrors()
    }
}

#endif
