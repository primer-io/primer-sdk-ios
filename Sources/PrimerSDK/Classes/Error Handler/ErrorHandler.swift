//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

import Foundation

internal protocol ErrorHandlerProtocol {
    func handle(error: Error?)
}

final class ConsoleLoggingErrorHandler: ErrorHandlerProtocol {
    
    func handle(error: Error?) {
        
        guard let error = error else {
            return
        }

        log(logLevel: .error,
            title: "ERROR!",
            message: error.localizedDescription)
    }
}

final class AnalyticsSenderErrorHandler: ErrorHandlerProtocol {
        
    func handle(error: Error?) {
        
        guard let error = error else {
            return
        }
        
        let eventProperties = MessageEventProperties(
            message: error.localizedDescription,
            messageType: .error,
            severity: .error)
        
        let event = Analytics.Event(
            eventType: .message,
            properties: eventProperties)
        
        Analytics.Service.record(event: event)
    }
}

internal class ErrorHandler {
    
    private static let shared = ErrorHandler()
        
    private lazy var defaultErrorHandlers: [ErrorHandlerProtocol] = {
        return [ConsoleLoggingErrorHandler(), AnalyticsSenderErrorHandler()]
    }()
}

extension ErrorHandler {
    
    static func handle(error: Error?, addingHandlers additionalHandlers: [ErrorHandlerProtocol] = []) {
        
        let defaultOptions = ErrorHandler.shared.defaultErrorHandlers
        let allErrorHandlers = defaultOptions + additionalHandlers
                
        allErrorHandlers.forEach { errorHandlerOption in
            errorHandlerOption.handle(error: error)
        }
    }
}
