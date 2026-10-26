//
//  BackendDrivenCheckoutLogger.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

enum BackendDrivenCheckoutLogger {
    static func log(
        _ message: String,
        type: Analytics.Event.Property.MessageType,
        severity: Analytics.Event.Property.Severity,
        diagnosticsId: String? = nil,
        context: [String: Any]? = nil
    ) {
        Analytics.Service.fire(event: Analytics.Event.message(
            message: message,
            messageType: type,
            severity: severity,
            diagnosticsId: diagnosticsId,
            context: context
        ))

        runPlatformLogStep(
            message,
            type: type,
            severity: severity,
            diagnosticsId: diagnosticsId,
            context: context
        )
    }

    private static func runPlatformLogStep(
        _ message: String,
        type: Analytics.Event.Property.MessageType,
        severity: Analytics.Event.Property.Severity,
        diagnosticsId: String?,
        context: [String: Any]?
    ) {
        var stepContext = context ?? [:]
        stepContext["diagnosticsId"] = diagnosticsId
        let payload: [String: Any] = [
            "properties": [
                "messageType": type.rawValue,
                "message": message,
                "severity": severity.platformLogSeverity,
                "context": stepContext
            ]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let step = try? JSONDecoder().decode(CodableValue.self, from: data) else { return }
        Task {
            guard await DIContainer.current != nil else { return }
            try? await PrimerStepResolverRegistry.shared.resolve(StepCapability.platformLog.rawValue, data: step)
        }
    }
}

private extension Analytics.Event.Property.Severity {
    var platformLogSeverity: String {
        switch self {
        case .debug, .info: "info"
        case .warning: "warn"
        case .error: "error"
        }
    }
}
