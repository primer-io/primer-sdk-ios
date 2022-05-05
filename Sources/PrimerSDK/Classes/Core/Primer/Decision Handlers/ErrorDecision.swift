//
//  ErrorDecision.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 02/05/22.
//

#if canImport(UIKit)

import Foundation

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

#endif
