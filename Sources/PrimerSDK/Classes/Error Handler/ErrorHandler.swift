//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

import Foundation

final class ErrorHandler: LogReporter {

    // Call this function to log any error to Analytics
    static func handle(error: Error) {
        ErrorHandler.shared.handle(error: error)
    }

    static var shared = ErrorHandler()

    func handle(error: Error) {
        self.logger.error(message: error.localizedDescription)

        // Check if error should be filtered from server reporting
        if shouldFilterError(error) {
            self.logger.info(message: "Filtered error from server reporting: \(error.localizedDescription)")
            return
        }

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
        } else if let primerError = error as? PrimerError {
            event = Analytics.Event.message(
                message: primerError.errorDescription,
                messageType: .error,
                severity: determineErrorSeverity(primerError),
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

    private func shouldFilterError(_ error: Error) -> Bool {
        guard let primerError = error as? PrimerError else {
            return false
        }

        // Filter out non-actionable Apple Pay errors
        switch primerError {
        case .applePayNoCardsInWallet,
             .applePayDeviceNotSupported:
            return true
        default:
            return false
        }
    }

    private func determineErrorSeverity(_ error: PrimerError) -> Analytics.Event.Property.Severity {
        switch error {
        case .applePayNoCardsInWallet,
             .applePayDeviceNotSupported:
            return .warning
        case .applePayConfigurationError,
             .applePayPresentationFailed,
             .unableToPresentApplePay:
            return .error
        default:
            return .error
        }
    }
}
