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

        if let error = error as? PrimerErrorProtocol {
            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: error.localizedDescription,
                    messageType: .error,
                    severity: .error,
                    diagnosticsId: error.diagnosticsId))

            if let createdAt = (error.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }
            

        } else {
            let nsError = error as NSError
            var userInfo = nsError.userInfo
            
            if let nsLocalizedDescription = userInfo[NSLocalizedDescriptionKey] {
                userInfo["description"] = nsLocalizedDescription
                userInfo[NSLocalizedDescriptionKey] = nil
            }
            
            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "\(nsError.domain) [\(nsError.code)]: \(nsError.localizedDescription)",
                    messageType: .error,
                    severity: .error,
                    diagnosticsId: nil,
                    context: userInfo))
        }
        
        Analytics.Service.record(event: event)

        return false
    }

}

#endif
