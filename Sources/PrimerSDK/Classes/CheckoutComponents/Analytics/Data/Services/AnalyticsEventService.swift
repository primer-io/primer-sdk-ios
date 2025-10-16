//
//  AnalyticsEventService.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation
import UIKit

/// Core analytics event service responsible for constructing and sending events.
/// Thread-safe actor that maintains session state and handles HTTP communication.
actor AnalyticsEventService: CheckoutComponentsAnalyticsServiceProtocol, LogReporter {

    // MARK: - Dependencies

    private let environmentProvider: AnalyticsEnvironmentProvider
    private let deviceInfoProvider: DeviceInfoProvider

    // MARK: - State

    private var sessionConfig: AnalyticsSessionConfig?
    private var pendingEvents: [(AnalyticsEventType, AnalyticsEventMetadata?)] = []

    // MARK: - Initialization

    init(
        environmentProvider: AnalyticsEnvironmentProvider,
        deviceInfoProvider: DeviceInfoProvider
    ) {
        self.environmentProvider = environmentProvider
        self.deviceInfoProvider = deviceInfoProvider
    }

    // MARK: - AnalyticsServiceProtocol

    func initialize(config: AnalyticsSessionConfig) async {
        self.sessionConfig = config

        // Flush any events that arrived before initialization completed
        guard !pendingEvents.isEmpty else { return }
        let bufferedEvents = pendingEvents
        pendingEvents.removeAll()

        for (eventType, metadata) in bufferedEvents {
            await sendEvent(eventType, metadata: metadata)
        }
    }

    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        guard let config = sessionConfig else {
            logger.debug(message: "📊 [Analytics] Queued \(eventType.rawValue) - service not initialized yet")
            pendingEvents.append((eventType, metadata))
            return
        }

        guard let endpoint = environmentProvider.getEndpointURL(for: config.environment) else {
            logger.warn(message: "📊 [Analytics] Dropped \(eventType.rawValue) - invalid endpoint for \(config.environment.rawValue)")
            return
        }

        // Construct payload
        let payload = constructPayload(
            eventType: eventType,
            metadata: metadata,
            config: config
        )

        // Send request (fire-and-forget)
        do {
            try await sendRequest(payload: payload, endpoint: endpoint, token: config.clientSessionToken)
        } catch {
            // Log error but don't throw to caller (fire-and-forget pattern)
            logger.error(message: "📊 [Analytics] Failed to send \(eventType.rawValue): \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func constructPayload(
        eventType: AnalyticsEventType,
        metadata: AnalyticsEventMetadata?,
        config: AnalyticsSessionConfig
    ) -> AnalyticsPayload {
        // Generate unique event ID
        let eventId = UUIDGenerator.generate()

        // Get current timestamp
        let timestamp = Int(Date().timeIntervalSince1970)

        // Detect SDK type (native iOS vs React Native)
        let sdkType = detectSDKType()

        // Get device info (auto-fill if not provided in metadata)
        let userAgent = deviceInfoProvider.getUserAgent()
        let device = deviceInfoProvider.getDevice()
        let deviceType = deviceInfoProvider.getDeviceType()
        let userLocale = metadata?.locale ?? deviceInfoProvider.getUserLocale()

        return AnalyticsPayload(
            id: eventId,
            timestamp: timestamp,
            sdkType: sdkType,
            eventName: eventType.rawValue,
            checkoutSessionId: config.checkoutSessionId,
            clientSessionId: config.clientSessionId,
            primerAccountId: config.primerAccountId,
            sdkVersion: config.sdkVersion,
            userAgent: userAgent,
            eventType: nil,
            userLocale: userLocale,
            paymentMethod: metadata?.paymentMethod,
            paymentId: metadata?.paymentId,
            redirectDestinationUrl: metadata?.redirectDestinationUrl,
            threedsProvider: metadata?.threedsProvider,
            threedsResponse: metadata?.threedsResponse,
            browser: nil,
            device: device,
            deviceType: deviceType
        )
    }

    private func sendRequest(payload: AnalyticsPayload, endpoint: URL, token: String?) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add Authorization header if token is available
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.debug(message: "📊 [Analytics] Authorization header set (token masked)")
        }

        // Encode payload
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        request.httpBody = try encoder.encode(payload)

        logger.info(message: "📊 [Analytics] Dispatching \(payload.eventName) -> \(endpoint.absoluteString)")
        logger.debug(message: "📊 [Analytics] Event context - id: \(payload.id), timestamp: \(payload.timestamp), sdkType: \(payload.sdkType)")

        if request.value(forHTTPHeaderField: "Authorization") == nil {
            logger.warn(message: "⚠️ [Analytics] No authorization token provided")
        }

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error(message: "❌ [Analytics] Invalid response type")
            throw AnalyticsError.requestFailed
        }

        logger.debug(message: "📊 [Analytics] Response status code: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                logger.error(message: "❌ [Analytics] Request failed with status \(httpResponse.statusCode) - \(responseString)")
            } else {
                logger.error(message: "❌ [Analytics] Request failed with status \(httpResponse.statusCode)")
            }
            throw AnalyticsError.requestFailed
        }

        logger.info(message: "✅ [Analytics] \(payload.eventName) acknowledged")
    }

    private func detectSDKType() -> String {
        // Check if React Native bridge is available
        return NSClassFromString("RCTBridge") != nil ? "RN_IOS" : "IOS_NATIVE"
    }
}

// MARK: - Error Types

enum AnalyticsError: Error {
    case requestFailed
    case invalidConfiguration
}
