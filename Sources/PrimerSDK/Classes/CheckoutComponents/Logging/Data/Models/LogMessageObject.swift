//
//  LogMessageObject.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct LogMessageObject: Codable, Sendable {
    let message: String
    let status: String
    let event: String?
    let primer: PrimerIdentifiers?
    let errorMessage: String?
    let diagnosticsId: String?
    let stack: String?
    let initDurationMs: Int?
    let deviceInfo: DeviceInfoMetadata?
    let appMetadata: AppMetadata?
    let sessionMetadata: SessionMetadata?

    init(
        message: String,
        status: String,
        event: String? = nil,
        primer: PrimerIdentifiers? = nil,
        errorMessage: String? = nil,
        diagnosticsId: String? = nil,
        stack: String? = nil,
        initDurationMs: Int? = nil,
        deviceInfo: DeviceInfoMetadata? = nil,
        appMetadata: AppMetadata? = nil,
        sessionMetadata: SessionMetadata? = nil
    ) {
        self.message = message
        self.status = status
        self.event = event
        self.primer = primer
        self.errorMessage = errorMessage
        self.diagnosticsId = diagnosticsId
        self.stack = stack
        self.initDurationMs = initDurationMs
        self.deviceInfo = deviceInfo
        self.appMetadata = appMetadata
        self.sessionMetadata = sessionMetadata
    }
}

extension LogMessageObject {
    struct PrimerIdentifiers: Codable, Sendable {
        let checkoutSessionId: String?
        let clientSessionId: String?
        let primerAccountId: String?
        let customerId: String?

        init(
            checkoutSessionId: String? = nil,
            clientSessionId: String? = nil,
            primerAccountId: String? = nil,
            customerId: String? = nil
        ) {
            self.checkoutSessionId = checkoutSessionId
            self.clientSessionId = clientSessionId
            self.primerAccountId = primerAccountId
            self.customerId = customerId
        }
    }
}
