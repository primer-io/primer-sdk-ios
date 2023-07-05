//
//  PrimerKlarnaValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerKlarnaValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        
        // Order validation
        
        if PrimerInternal.shared.intent == .checkout {
            if (PrimerAPIConfiguration.current?.clientSession?.order?.lineItems?.filter({ $0.amount != nil }) ?? []).isEmpty {
                let err = PrimerError.invalidClientSessionValue(
                    name: "order.lineItems",
                    value: nil,
                    allowedValue: nil,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                self.errors.append(err)
                
            }
        }
        
        try super.throwErrors()
    }
}

#endif
