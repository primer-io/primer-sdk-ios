//
//  PrimerValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

#if canImport(UIKit)

import Foundation

class PrimerValidator {
    
    let paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator
    var errors: [PrimerError] = []
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func validateSynchronously() throws {
        // Client token and configuration validation
        
        if PrimerAPIConfigurationModule.decodedJWTToken == nil || PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            let err = PrimerError.invalidClientToken(
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
        
        if URL(string: PrimerAPIConfigurationModule.decodedJWTToken?.pciUrl ?? "") == nil {
            let err = PrimerError.invalidValue(
                key: "decodedClientToken.pciUrl",
                value: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        if self.paymentMethodOrchestrator.paymentMethodConfig.id == nil {
            let err = PrimerError.invalidValue(
                key: "configuration.id",
                value: self.paymentMethodOrchestrator.paymentMethodConfig.id,
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
    }
    
    final func validate() -> Promise<Void> {
        return Promise { seal in
            do {
                try self.validateSynchronously()
                seal.fulfill()
            } catch {
                seal.reject(error)
            }
        }
    }
    
    final func throwErrors() throws {
        if !self.errors.isEmpty {
            if self.errors.count == 1 {
                throw self.errors.first!
            } else {
                let err = PrimerError.underlyingErrors(
                    errors: self.errors,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                throw err
            }
        }
    }
}

#endif
