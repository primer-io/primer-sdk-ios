//
//  PrimerPayPalValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerPayPalValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        
        if URL(string: PrimerAPIConfigurationModule.decodedJWTToken?.coreUrl ?? "") == nil {
            let err = PrimerError.invalidValue(
                key: "decodedClientToken.pciUrl",
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
