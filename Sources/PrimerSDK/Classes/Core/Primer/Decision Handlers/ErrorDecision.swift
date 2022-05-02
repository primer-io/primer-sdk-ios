//
//  ErrorDecision.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 02/05/22.
//

import Foundation

@objc public class ErrorDecision: NSObject {
    
    public enum DecisionType {
        case showErrorMessage
    }
    
    enum InfoKey: String {
        case message
    }
        
    var type: DecisionType
    var additionalInfo: [InfoKey: Codable]?
    
    private init(type: DecisionType, additionalInfo: [InfoKey: Codable]?) {
        self.type = type
        self.additionalInfo = additionalInfo
    }
}

public extension ErrorDecision {
    
    static func showErrorMessage(_ message: String?) -> ErrorDecision {
        ErrorDecision(type: .showErrorMessage, additionalInfo: [.message: message])
    }
}
