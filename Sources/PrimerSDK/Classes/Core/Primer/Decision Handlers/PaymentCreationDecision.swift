//
//  PaymentCreationDecision.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/04/22.
//

#if canImport(UIKit)

import Foundation

@objc public class PaymentCreationDecision: NSObject {
    
    public enum DecisionType {
        case abort
        case `continue`
    }
    
    enum InfoKey: String {
        case message
        case clientToken
    }
        
    var type: DecisionType
    var additionalInfo: [InfoKey: Codable]?
    
    private init(type: DecisionType, additionalInfo: [InfoKey: Codable]?) {
        self.type = type
        self.additionalInfo = additionalInfo
    }
}

public extension PaymentCreationDecision {
    
    static func abortPaymentCreation(errorMessage: String? = nil) -> PaymentCreationDecision {
        PaymentCreationDecision(type: .abort, additionalInfo: [.message: errorMessage])
    }
    
    static func continuePaymentCreation() -> PaymentCreationDecision {
        PaymentCreationDecision(type: .continue, additionalInfo: nil)
    }
}

#endif
