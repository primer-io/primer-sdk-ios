//
//  ErrorHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

final class ErrorHandler: LogReporter {

    // Call this function to log any error to Analytics
    static func handle(
        error: Error,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        ErrorHandler.shared.handle(error: error, file: file, line: line, function: function)
    }

    static var shared = ErrorHandler()

    func handle(
        error: Error,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        logger.error(message: error.localizedDescription, file: file, line: line, function: function)

        // Check if error should be filtered from server reporting
        if shouldFilterError(error) {
            logger.warn(message: "Integration issue: \(error.localizedDescription)")
            return
        }

        Analytics.Service.fire(event: event(for: error))
    }

    // Preserves the `diagnosticsId` for every `PrimerErrorProtocol` error (notably `InternalError`);
    // without this they fall through to the NSError branch and the id surfaced to the merchant has
    // no matching backend log entry.
    func event(for error: Error) -> Analytics.Event {
        if let threeDsError = error as? Primer3DSErrorContainer {
            var event = Analytics.Event.message(
                message: threeDsError.errorDescription,
                messageType: .error,
                severity: .error,
                diagnosticsId: threeDsError.diagnosticsId,
                context: threeDsError.analyticsContext
            )
            if let createdAt = (threeDsError.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }
            return event
        }

        if let primerError = error as? PrimerError {
            var event = Analytics.Event.message(
                message: primerError.errorDescription,
                messageType: .error,
                severity: determineErrorSeverity(primerError),
                diagnosticsId: primerError.diagnosticsId,
                context: primerError.analyticsContext
            )
            if let createdAt = (primerError.errorUserInfo["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }
            return event
        }

        if let primerError = error as? (any PrimerErrorProtocol) {
            return Analytics.Event.message(
                message: primerError.errorDescription,
                messageType: .error,
                severity: .error,
                diagnosticsId: primerError.diagnosticsId,
                context: primerError.analyticsContext
            )
        }

        let nsError = error as NSError
        var userInfo = nsError.userInfo
        userInfo["description"] = nsError.description
        userInfo[NSLocalizedDescriptionKey] = nil

        return Analytics.Event.message(
            message: "\(nsError.domain) [\(nsError.code)]: \(nsError.localizedDescription)",
            messageType: .error,
            severity: .error,
            diagnosticsId: nil,
            context: userInfo
        )
    }

    private func shouldFilterError(_ error: Error) -> Bool {
        guard let primerError = error as? PrimerError else {
            return false
        }

        // Filter out non-actionable errors (merchant integration issues, not SDK bugs)
        switch primerError {
        case .applePayNoCardsInWallet,
             .applePayDeviceNotSupported,
             .unableToPresentPaymentMethod:
            return true
        default:
            return false
        }
    }

    private func determineErrorSeverity(_ error: PrimerError) -> Analytics.Event.Property.Severity {
        switch error {
        case .applePayNoCardsInWallet,
             .applePayDeviceNotSupported:
            .warning
        default:
            .error
        }
    }
}
