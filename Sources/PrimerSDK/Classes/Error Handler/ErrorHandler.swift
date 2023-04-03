//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

import Foundation

internal class ErrorHandler {
    
    static func handle(error: Error) {
        _ = ErrorHandler.shared.handle(error: error)
    }

    static var shared = ErrorHandler()

    @discardableResult
    func handle(error: Error) -> Bool {
        log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)

        var event: Analytics.Event!
        
        if let primerError = error as? PrimerError {
            switch primerError {
            case .failedToCreateSession(let error, _, let diagnosticsId),
                    .failedOnWebViewFlow(let error, _, let diagnosticsId),
                    .failedToPerform3DS(let error, _, let diagnosticsId):
                if let nsError = error as? NSError {
                    var eventInfo: [String: Any] = nsError.userInfo
                    
                    if let errorUserInfo = primerError.info {
                        eventInfo = eventInfo.merging(errorUserInfo) { (current, _) in current }
                    }
                    
                    if let localizedDescription = eventInfo[NSLocalizedDescriptionKey] as? String {
                        eventInfo["description"] = localizedDescription
                        eventInfo[NSLocalizedDescriptionKey] = nil
                    }
                                        
                    event = Analytics.Event(
                        eventType: .message,
                        properties: MessageEventProperties(
                            message: "\(nsError.domain) [\(nsError.code)]: \(nsError.localizedDescription)",
                            messageType: .error,
                            severity: .error,
                            diagnosticsId: diagnosticsId,
                            context: eventInfo))
                    
                    if let createdAt = (primerError.info?["createdAt"] as? String)?.toDate() {
                        event.createdAt = createdAt.millisecondsSince1970
                    }
                    
                } else {
                    var eventInfo: [String: Any]?
                    
                    if let errorUserInfo = primerError.info {
                        eventInfo = errorUserInfo
                    }
                    
                    if let localizedDescription = eventInfo?[NSLocalizedDescriptionKey] as? String {
                        eventInfo?["description"] = localizedDescription
                        eventInfo?[NSLocalizedDescriptionKey] = nil
                    }
                                        
                    event = Analytics.Event(
                        eventType: .message,
                        properties: MessageEventProperties(
                            message: primerError.localizedDescription,
                            messageType: .error,
                            severity: .error,
                            diagnosticsId: diagnosticsId,
                            context: eventInfo))
                    
                    if let createdAt = (primerError.info?["createdAt"] as? String)?.toDate() {
                        event.createdAt = createdAt.millisecondsSince1970
                    }
                }
                
            default:
                var eventInfo: [String: Any]?
                
                if let errorUserInfo = primerError.info {
                    eventInfo = errorUserInfo
                }
                
                if let localizedDescription = eventInfo?[NSLocalizedDescriptionKey] as? String {
                    eventInfo?["description"] = localizedDescription
                    eventInfo?[NSLocalizedDescriptionKey] = nil
                }
                                    
                event = Analytics.Event(
                    eventType: .message,
                    properties: MessageEventProperties(
                        message: primerError.localizedDescription,
                        messageType: .error,
                        severity: .error,
                        diagnosticsId: primerError.diagnosticsId,
                        context: eventInfo))
                
                if let createdAt = (primerError.info?["createdAt"] as? String)?.toDate() {
                    event.createdAt = createdAt.millisecondsSince1970
                }
            }
            
        } else if let primerError = error as? PrimerErrorProtocol {
            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: primerError.localizedDescription,
                    messageType: .error,
                    severity: .error,
                    diagnosticsId: primerError.diagnosticsId))

            if let createdAt = (primerError.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }

        } else {
            let nsError = error as NSError
            var userInfo = nsError.userInfo
            
            if let nsLocalizedDescription = userInfo[NSLocalizedDescriptionKey] {
                userInfo["description"] = nsLocalizedDescription
                userInfo[NSLocalizedDescriptionKey] = nil
            }
            
            var diagnosticsId: String?
            if let tmpDiagnosticsId = userInfo["diagnosticsId"] as? String {
                diagnosticsId = tmpDiagnosticsId
            }
            
            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "\(nsError.domain) [\(nsError.code)]: \(nsError.localizedDescription)",
                    messageType: .error,
                    severity: .error,
                    diagnosticsId: diagnosticsId,
                    context: userInfo))
        }
        
        Analytics.Service.record(event: event)

        return false
    }

}

#endif
