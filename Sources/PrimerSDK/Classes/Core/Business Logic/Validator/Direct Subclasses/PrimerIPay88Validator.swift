//
//  PrimerIPay88Validator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerIPay88Validator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        
        // Configuration response validation
        
        if (self.paymentMethodOrchestrator.paymentMethodConfig.options as? MerchantOptions)?.merchantId == nil {
            let err = PrimerError.invalidValue(
                key: "configuration.merchantId",
                value: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        // Order validation
        
        if (PrimerAPIConfiguration.current?.clientSession?.order?.lineItems ?? []).count == 0 {
            let err = PrimerError.invalidClientSessionValue(
                name: "order.lineItems",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
            
        } else {
            let productsDescription = PrimerAPIConfiguration.current?.clientSession?.order?.lineItems?.compactMap({ $0.name ?? $0.description }).joined(separator: ", ")
            
            if productsDescription == nil {
                let err = PrimerError.invalidClientSessionValue(
                    name: "order.lineItems.description",
                    value: nil,
                    allowedValue: nil,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.errors.append(err)
            }
        }
        
        // Customer validation
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.firstName == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.firstName",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.lastName == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.lastName",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
        if PrimerAPIConfiguration.current?.clientSession?.customer?.emailAddress == nil {
            let err = PrimerError.invalidClientSessionValue(
                name: "customer.emailAddress",
                value: nil,
                allowedValue: nil,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            self.errors.append(err)
        }
        
#if !canImport(PrimerIPay88MYSDK)
        let err = PrimerError.missingSDK(
            paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
            sdkName: "PrimerIPay88MYSDK",
            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: err)
        self.errors.append(err)
#endif
        
        try super.throwErrors()
    }
}

#endif
