//
//  LogMessageObject.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct LogMessageObject: Codable, Sendable {
    // MARK: - Common Fields

    let message: String
    let status: String
    let primer: PrimerIdentifiers?
    let deviceInfo: DeviceInfoMetadata?

    // MARK: - ERROR-specific Fields

    let errorMessage: String?
    let errorStack: String?

    // MARK: - INFO-specific Fields

    let event: String?
    let initDurationMs: Int?

    // MARK: - Metadata Fields

    let appMetadata: AppMetadata?
    let sessionMetadata: SessionMetadata?

    // MARK: - Initialization

    init(
        message: String,
        status: String,
        primer: PrimerIdentifiers? = nil,
        deviceInfo: DeviceInfoMetadata? = nil,
        errorMessage: String? = nil,
        errorStack: String? = nil,
        event: String? = nil,
        initDurationMs: Int? = nil,
        appMetadata: AppMetadata? = nil,
        sessionMetadata: SessionMetadata? = nil
    ) {
        self.message = message
        self.status = status
        self.primer = primer
        self.deviceInfo = deviceInfo
        self.errorMessage = errorMessage
        self.errorStack = errorStack
        self.event = event
        self.initDurationMs = initDurationMs
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
