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
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func validateSynchronously() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if decodedJWTToken.isValid != true {
            let err = PrimerError.invalidClientToken(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard self.paymentMethodOrchestrator.paymentMethodConfig.id != nil else {
            let err = PrimerError.invalidValue(
                key: "configuration.id",
                value: self.paymentMethodOrchestrator.paymentMethodConfig.id,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if PrimerInternal.shared.intent == .checkout {
            if AppState.current.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if AppState.current.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
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
}

#endif
