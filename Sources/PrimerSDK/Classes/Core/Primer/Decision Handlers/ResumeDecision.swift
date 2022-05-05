//
//  ResumeDecision.swift
//  PrimerSDK
//
//  Created by Evangelos on 5/5/22.
//

#if canImport(UIKit)

import Foundation

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

#endif
