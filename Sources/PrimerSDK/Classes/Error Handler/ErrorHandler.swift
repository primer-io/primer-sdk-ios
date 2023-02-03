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

            if let createdAt = error.info?["createdAt"]?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }
            

        } else {
            let nsError = error as NSError
            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: nsError.localizedDescription,
                    messageType: .error,
                    severity: .error))
        }

        Analytics.Service.record(event: event)

        return false
    }

}

#endif
