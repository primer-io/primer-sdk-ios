//
//  AnalyticsEventService.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation
import UIKit

/// Core analytics event service responsible for orchestrating event tracking.
/// Thread-safe actor that coordinates payload building, buffering, and network transmission.
actor AnalyticsEventService: CheckoutComponentsAnalyticsServiceProtocol, LogReporter {

    // MARK: - Dependencies

    private let payloadBuilder: AnalyticsPayloadBuilder
    private let networkClient: AnalyticsNetworkClient
    private let eventBuffer: AnalyticsEventBuffer
    private let environmentProvider: AnalyticsEnvironmentProvider

    // MARK: - State

    private var sessionConfig: AnalyticsSessionConfig?

    // MARK: - Initialization

    init(
        payloadBuilder: AnalyticsPayloadBuilder,
        networkClient: AnalyticsNetworkClient,
        eventBuffer: AnalyticsEventBuffer,
        environmentProvider: AnalyticsEnvironmentProvider
    ) {
        self.payloadBuilder = payloadBuilder
        self.networkClient = networkClient
        self.eventBuffer = eventBuffer
        self.environmentProvider = environmentProvider
    }

    /// Factory method for creating service with default configuration.
    static func create(
        environmentProvider: AnalyticsEnvironmentProvider
    ) -> AnalyticsEventService {
        let payloadBuilder = AnalyticsPayloadBuilder()
        let networkClient = AnalyticsNetworkClient()
        let eventBuffer = AnalyticsEventBuffer()

        return AnalyticsEventService(
            payloadBuilder: payloadBuilder,
            networkClient: networkClient,
            eventBuffer: eventBuffer,
            environmentProvider: environmentProvider
        )
    }

    // MARK: - AnalyticsServiceProtocol

    func initialize(config: AnalyticsSessionConfig) async {
        self.sessionConfig = config

        // Flush any events that arrived before initialization completed
        let bufferedEvents = await eventBuffer.flush()

        guard !bufferedEvents.isEmpty else { return }

        for (eventType, metadata, timestamp) in bufferedEvents {
            await sendEventWithTimestamp(eventType, metadata: metadata, timestamp: timestamp)
        }
    }

    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        // Capture timestamp at the moment the event occurs
        let eventTimestamp = Int(Date().timeIntervalSince1970)
        await sendEventWithTimestamp(eventType, metadata: metadata, timestamp: eventTimestamp)
    }

    // MARK: - Private Methods

    /// Internal method that sends event with an explicit timestamp
    /// - Parameters:
    ///   - eventType: The type of event being tracked
    ///   - metadata: Optional event metadata
    ///   - timestamp: UNIX timestamp when the event occurred
    private func sendEventWithTimestamp(
        _ eventType: AnalyticsEventType,
        metadata: AnalyticsEventMetadata?,
        timestamp: Int
    ) async {
        guard let config = sessionConfig else {
            // Buffer the event with its original timestamp
            await eventBuffer.buffer(eventType: eventType, metadata: metadata, timestamp: timestamp)
            return
        }

        guard let endpoint = environmentProvider.getEndpointURL(for: config.environment) else {
            let envName = config.environment.rawValue
            logger.warn(message: "📊 [Analytics] Dropped \(eventType.rawValue) - invalid endpoint for \(envName)")
            return
        }

        // Construct payload using the builder, passing the captured timestamp
        let payload = payloadBuilder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config,
            timestamp: timestamp
        )

        // Send via network client (fire-and-forget)
        do {
            try await networkClient.send(payload: payload, to: endpoint, token: config.clientSessionToken)
        } catch {
            // Log error but don't throw to caller (fire-and-forget pattern)
            logger.error(message: "📊 [Analytics] Failed to send \(eventType.rawValue): \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types

enum AnalyticsError: Error {
    case requestFailed
    case invalidConfiguration
}
