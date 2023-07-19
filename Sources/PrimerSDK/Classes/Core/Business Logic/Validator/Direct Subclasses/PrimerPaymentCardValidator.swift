//
//  PrimerPaymentCardValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

#if canImport(UIKit)

import Foundation

class PrimerPaymentCardValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        self.errors = []
        
        // Client token and configuration validation
        
        if PrimerAPIConfigurationModule.decodedJWTToken == nil || PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
            
        } else if URL(string: PrimerAPIConfigurationModule.decodedJWTToken?.pciUrl ?? "") == nil {
            let err = PrimerError.invalidValue(
                key: "decodedClientToken.pciUrl",
                value: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        if PrimerAPIConfigurationModule.apiConfiguration == nil {
            let err = PrimerError.missingPrimerConfiguration(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        /// Amount and currency should not get validated on vault flow
        if PrimerInternal.shared.intent == .checkout {
            if (AppState.current.amount ?? 0) == 0 {
                let err = PrimerError.invalidClientSessionValue(
                    name: "amount or line items' amounts",
                    value: AppState.current.amount == nil ? nil : "\(AppState.current.amount)",
                    allowedValue: "Any number greater than 0",
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.errors.append(err)
            }
            
            if AppState.current.currency == nil {
                let err = PrimerError.invalidClientSessionValue(
                    name: "currency",
                    value: nil,
                    allowedValue: "Any currency",
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.errors.append(err)
            }
        }
        
        try self.throwErrors()
    }
}

#endif
