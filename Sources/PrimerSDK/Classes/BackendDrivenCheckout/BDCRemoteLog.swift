//
//  BDCRemoteLog.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

struct BDCRemoteLog {
    enum Event {
        static let flowStarted = "bdc-flow-started"
        static let flowEnded = "bdc-flow-ended"
        static let requirementsNotMet = "bdc-requirements-not-met"
        static let engineLoadFailed = "bdc-engine-load-failed"
    }

    enum Outcome {
        static let success = "success"
        static let cancelled = "cancelled"
        static let error = "error"
    }

    private let service: any ComponentsLoggingServiceProtocol
    private let clientToken: () -> String?

    init(
        service: any ComponentsLoggingServiceProtocol = LoggingService.shared,
        clientToken: @escaping () -> String? = { PrimerAPIConfigurationModule.clientToken }
    ) {
        self.service = service
        self.clientToken = clientToken
    }

    func flowStarted(_ config: PrimerPaymentMethod, trustedKeyFingerprints: [String]) async {
        await prepareSession()
        await service.logInfo(
            message: "BDC flow started",
            event: Event.flowStarted,
            userInfo: fields(for: config, ["trusted_key_fingerprints": trustedKeyFingerprints])
        )
    }

    func flowEnded(_ config: PrimerPaymentMethod, outcome: String, error: PrimerErrorProtocol?) async {
        await prepareSession()
        var fields = fields(for: config, ["outcome": outcome])
        if let error {
            fields["error_id"] = error.errorId
            fields["diagnostics_id"] = error.diagnosticsId
            if let description = error.errorDescription {
                fields["error_message"] = description
            }
        }
        let message = "BDC flow ended: \(outcome)"
        if outcome == Outcome.error {
            await service.logWarning(message: message, event: Event.flowEnded, userInfo: fields)
        } else {
            await service.logInfo(message: message, event: Event.flowEnded, userInfo: fields)
        }
    }

    func requirementsNotMet(_ method: PrimerPaymentMethod, unmet: [UnmetClientRequirement]) async {
        await prepareSession()
        await service.logWarning(
            message: "BDC client requirements not met",
            event: Event.requirementsNotMet,
            userInfo: fields(for: method, ["unmet": unmet.map(\.fields)])
        )
    }

    func engineLoadFailed(_ error: Error) async {
        await prepareSession()
        await service.logError(
            message: "BDC engine failed to load",
            event: Event.engineLoadFailed,
            errorMessage: "\(error)",
            stack: nil,
            userInfo: baseFields()
        )
    }

    private func prepareSession() async {
        guard let clientToken = clientToken() else { return }
        await LoggingSessionContext.shared.initialize(clientToken: clientToken)
    }

    private func fields(for config: PrimerPaymentMethod, _ extra: [String: Any]) -> [String: Any] {
        var fields = baseFields()
        fields["payment_method_type"] = config.type
        fields["entry"] = config.entry.rawValue
        fields.merge(extra) { _, new in new }
        return fields
    }

    private func baseFields() -> [String: Any] {
        guard let integrationType = PrimerInternal.shared.sdkIntegrationType else { return [:] }
        return ["integration_type": integrationType.rawValue]
    }
}

private extension UnmetClientRequirement {
    var fields: [String: String] {
        var fields = ["kind": kind, "name": name, "reason": reason]
        fields["type"] = type
        fields["required"] = required
        fields["available"] = available
        return fields
    }
}
