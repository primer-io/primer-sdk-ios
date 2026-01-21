//
//  LoggingService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

actor LoggingService: LogReporter {
    // MARK: - Dependencies

    private let networkClient: any LogNetworkClientProtocol
    private let payloadBuilder: any LogPayloadBuilding
    private let masker: SensitiveDataMasker

    // MARK: - Initialization

    init(
        networkClient: any LogNetworkClientProtocol,
        payloadBuilder: any LogPayloadBuilding,
        masker: SensitiveDataMasker
    ) {
        self.networkClient = networkClient
        self.payloadBuilder = payloadBuilder
        self.masker = masker
    }

    // MARK: - Public Methods

    func sendInfo(
        message: String,
        event: String,
        initDurationMs: Int?
    ) async {
        do {
            let sessionData = await LoggingSessionContext.shared.getSessionData()

            let payload = try payloadBuilder.buildInfoPayload(
                message: message,
                event: event,
                initDurationMs: initDurationMs,
                sessionData: sessionData
            )

            let endpoint = LogEnvironmentProvider.getEndpointURL(for: sessionData.environment)

            try await networkClient.send(
                payload: payload,
                to: endpoint,
                token: sessionData.clientSessionToken
            )
        } catch {
            // Fire-and-forget: log error locally but don't throw
            Self.logger.error(message: "📊 [Logging] Failed to send INFO log: \(error.localizedDescription)")
        }
    }

    func sendError(
        message: String,
        error: Error
    ) async {
        do {
            let sessionData = await LoggingSessionContext.shared.getSessionData()

            // Extract error message and stack trace
            let errorMessage = error.localizedDescription
            let stack = String(describing: error)

            // Mask sensitive data
            let maskedMessage = await masker.mask(text: message)
            let maskedErrorMessage = await masker.mask(text: errorMessage)
            let maskedStack = await masker.mask(text: stack)

            let payload = try payloadBuilder.buildErrorPayload(
                message: maskedMessage,
                errorMessage: maskedErrorMessage,
                errorStack: maskedStack,
                sessionData: sessionData
            )

            let endpoint = LogEnvironmentProvider.getEndpointURL(for: sessionData.environment)

            try await networkClient.send(
                payload: payload,
                to: endpoint,
                token: sessionData.clientSessionToken
            )
        } catch {
            // Fire-and-forget: log error locally but don't throw
            Self.logger.error(message: "📊 [Logging] Failed to send ERROR log: \(error.localizedDescription)")
        }
    }
}
