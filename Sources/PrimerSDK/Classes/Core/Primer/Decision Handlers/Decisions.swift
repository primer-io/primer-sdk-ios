//
//  ErrorDecision.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 02/05/22.
//

#if canImport(UIKit)

import Foundation

// MARK: - ERROR DECISION

@objc public class PrimerErrorDecision: NSObject {
    
    public enum DecisionType {
        case fail(message: String?)
    }
  
    var type: DecisionType
    
    private init(type: DecisionType) {
        self.type = type
    }
}

public extension PrimerErrorDecision {
    
    static func fail(withMessage message: String?) -> PrimerErrorDecision {
        PrimerErrorDecision(type: .fail(message: message))
    }
}

// MARK: - RESUME DECISION

@objc public class PrimerResumeDecision: NSObject {
    
    public enum DecisionType {
        case succeed
        case fail(message: String?)
        case continueWithNewClientToken(_ newClientToken: String)
    }
        
    var type: DecisionType
    
    private init(type: DecisionType) {
        self.type = type
    }
}

public extension PrimerResumeDecision {
    
    static func succeed() -> PrimerResumeDecision {
        PrimerResumeDecision(type: .succeed)
    }
    
    static func fail(withMessage message: String?) -> PrimerResumeDecision {
        PrimerResumeDecision(type: .fail(message: message))
    }
    
    static func continueWithNewClientToken(_ newClientToken: String) -> PrimerResumeDecision {
        PrimerResumeDecision(type: .continueWithNewClientToken(newClientToken))
    }
}

// MARK: - PAYMENT DECISION

@objc public class PrimerPaymentCreationDecision: NSObject {
    
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

public extension PrimerPaymentCreationDecision {
    
    static func abortPaymentCreation(errorMessage: String? = nil) -> PrimerPaymentCreationDecision {
        PrimerPaymentCreationDecision(type: .abort, additionalInfo: [.message: errorMessage])
    }
    
    static func continuePaymentCreation() -> PrimerPaymentCreationDecision {
        PrimerPaymentCreationDecision(type: .continue, additionalInfo: nil)
    }
}

#endif
