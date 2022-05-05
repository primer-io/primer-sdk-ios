//
//  ErrorDecision.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 02/05/22.
//

#if canImport(UIKit)

import Foundation

// MARK: - SUCCESS DECISION

@objc public class SuccessDecision: NSObject {
    
    public enum DecisionType {
        case showSuccessMessage(_ message: String?)
    }
  
    var type: DecisionType
    
    private init(type: DecisionType) {
        self.type = type
    }
}

public extension SuccessDecision {
    
    static func showSuccessMessage(_ message: String?) -> SuccessDecision {
        SuccessDecision(type: .showSuccessMessage(message))
    }
}

// MARK: - ERROR DECISION

@objc public class ErrorDecision: NSObject {
    
    public enum DecisionType {
        case showErrorMessage(_ message: String?)
    }
  
    var type: DecisionType
    
    private init(type: DecisionType) {
        self.type = type
    }
}

public extension ErrorDecision {
    
    static func showErrorMessage(_ message: String?) -> ErrorDecision {
        ErrorDecision(type: .showErrorMessage(message))
    }
}

// MARK: - RESUME DECISION

@objc public class ResumeDecision: NSObject {
    
    public enum DecisionType {
        case showSuccessMessage(_ message: String?)
        case showErrorMessage(_ message: String?)
        case handleNewClientToken(_ newClientToken: String)
    }
        
    var type: DecisionType
    
    private init(type: DecisionType) {
        self.type = type
    }
}

public extension ResumeDecision {
    
    static func showSuccessMessage(_ message: String?) -> ResumeDecision {
        ResumeDecision(type: .showSuccessMessage(message))
    }
    
    static func showErrorMessage(_ message: String?) -> ResumeDecision {
        ResumeDecision(type: .showErrorMessage(message))
    }
    
    static func handleNewClientToken(_ newClientToken: String) -> ResumeDecision {
        ResumeDecision(type: .handleNewClientToken(newClientToken))
    }
}

// MARK: - PAYMENT DECISION

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
