//
//  LogMessageObject.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct LogMessageObject: Codable, Sendable {
    // MARK: - Common Fields

    public let message: String
    public let status: String
    public let primer: PrimerIdentifiers?
    public let deviceInfo: DeviceInfoMetadata?

    // MARK: - ERROR-specific Fields

    public let errorMessage: String?
    public let errorStack: String?

    // MARK: - INFO-specific Fields

    public let event: String?
    public let initDurationMs: Int?

    // MARK: - Metadata Fields

    public let appMetadata: AppMetadata?
    public let sessionMetadata: SessionMetadata?

    // MARK: - Initialization

    public init(
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
    public struct PrimerIdentifiers: Codable, Sendable {
        public let checkoutSessionId: String?
        public let clientSessionId: String?
        public let primerAccountId: String?
        public let customerId: String?

        public init(
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
