//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

import Foundation

internal class ErrorHandler: LogReporter {

    // Call this function to log any error to Analytics
    static func handle(error: Error) {
        ErrorHandler.shared.handle(error: error)
    }

    static var shared = ErrorHandler()

    @discardableResult
    func handle(error: Error) {
        self.logger.error(message: error.localizedDescription)

        var event: Analytics.Event!

        if let threeDsError = error as? Primer3DSErrorContainer {

            event = Analytics.Event.message(
                message: threeDsError.errorDescription,
                messageType: .error,
                severity: .error,
                diagnosticsId: threeDsError.diagnosticsId,
                context: threeDsError.analyticsContext
            )

            if let createdAt = (threeDsError.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }

        } else if let primerError = error as? PrimerErrorProtocol {
            event = Analytics.Event.message(
                message: primerError.errorDescription,
                messageType: .error,
                severity: .error,
                diagnosticsId: primerError.diagnosticsId,
                context: primerError.analyticsContext
            )

            if let createdAt = (primerError.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }

        } else {
            let nsError = error as NSError
            var userInfo = nsError.userInfo
            userInfo["description"] = nsError.description

            if userInfo[NSLocalizedDescriptionKey] != nil {
                userInfo[NSLocalizedDescriptionKey] = nil
            }

            event = Analytics.Event.message(
                message: "\(nsError.domain) [\(nsError.code)]: \(nsError.localizedDescription)",
                messageType: .error,
                severity: .error,
                diagnosticsId: nil,
                context: userInfo
            )
        }

        Analytics.Service.record(event: event)
    }
}
