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
            var context: [String: Any] = [:]

            let continueInfo = threeDsError.continueInfo
            context["initProtocolVersion"] = continueInfo.initProtocolVersion
            context["threeDsSdkVersion"] = continueInfo.threeDsSdkVersion
            context["threeDsSdkProvider"] = continueInfo.threeDsSdkProvider
            context["threeDsWrapperSdkVersion"] = continueInfo.threeDsWrapperSdkVersion

            switch threeDsError {
            case .primer3DSSdkError(_, _, _, let errorInfo):
                context["reasonCode"] = errorInfo.errorId
                context["reasonText"] = errorInfo.errorDescription
                context["threeDsErrorCode"] = errorInfo.threeDsErrorCode
                context["threeDsErrorComponent"] = errorInfo.threeDsErrorComponent
                context["threeDsErrorDescription"] = errorInfo.errorDescription
                context["threeDsErrorDetail"] = errorInfo.threeDsErrorDetail
                context["threeDsSdkTranscationId"] = errorInfo.threeDsSdkTranscationId
                context["protocolVersion"] = errorInfo.threeDsSErrorVersion
            default:
                break
            }

            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: threeDsError.errorDescription,
                    messageType: .error,
                    severity: .error,
                    diagnosticsId: threeDsError.diagnosticsId,
                    context: context.isEmpty ? nil : context))

            if let createdAt = (threeDsError.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }

        } else if let primerError = error as? PrimerErrorProtocol {
            guard shouldReport(error: primerError) else {
                return
            }
            event = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: primerError.errorDescription,
                    messageType: .error,
                    severity: .error,
                    diagnosticsId: primerError.diagnosticsId))

            if let createdAt = (primerError.info?["createdAt"] as? String)?.toDate() {
                event.createdAt = createdAt.millisecondsSince1970
            }

        } else {
            let nsError = error as NSError
            var userInfo = nsError.userInfo
            userInfo["description"] = nsError.description

            if let _ = userInfo[NSLocalizedDescriptionKey] {
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
    }
    
    private func shouldReport(error: PrimerErrorProtocol) -> Bool {
        guard let error = error as? PrimerError, case .underlyingErrors(let errors, _, _) = error else {
            return true
        }
        return !errors.allSatisfy { $0 is PrimerValidationError }
    }
}
