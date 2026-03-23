//
//  AnalyticsEventService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

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

  static func create(
    environmentProvider: AnalyticsEnvironmentProvider
  ) -> AnalyticsEventService {
    AnalyticsEventService(
      payloadBuilder: AnalyticsPayloadBuilder(),
      networkClient: AnalyticsNetworkClient(),
      eventBuffer: AnalyticsEventBuffer(),
      environmentProvider: environmentProvider
    )
  }

  // MARK: - AnalyticsServiceProtocol

  func initialize(config: AnalyticsSessionConfig) async {
    sessionConfig = config

    // Flush any events that arrived before initialization completed
    let bufferedEvents = await eventBuffer.flush()

    guard !bufferedEvents.isEmpty else { return }

    for (eventType, metadata, timestamp) in bufferedEvents {
      await sendEventWithTimestamp(eventType, metadata: metadata, timestamp: timestamp)
    }
  }

  func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
    await sendEventWithTimestamp(eventType, metadata: metadata, timestamp: Int(Date().timeIntervalSince1970))
  }

  // MARK: - Private Methods

  private func sendEventWithTimestamp(
    _ eventType: AnalyticsEventType,
    metadata: AnalyticsEventMetadata?,
    timestamp: Int
  ) async {
    guard let sessionConfig else {
      await eventBuffer.buffer(eventType: eventType, metadata: metadata, timestamp: timestamp)
      return
    }

    guard let endpoint = environmentProvider.getEndpointURL(for: sessionConfig.environment) else {
      logger.warn(
        message:
          "📊 [Analytics] Dropped \(eventType.rawValue) - invalid endpoint for \(sessionConfig.environment.rawValue)"
      )
      return
    }

    let payload = payloadBuilder.buildPayload(
      eventType: eventType,
      metadata: metadata,
      config: sessionConfig,
      timestamp: timestamp
    )

    do {
      try await networkClient.send(
        payload: payload, to: endpoint, token: sessionConfig.clientSessionToken)
    } catch {
      logger.error(
        message: "📊 [Analytics] Failed to send \(eventType.rawValue): \(error.localizedDescription)"
      )
    }
  }
}

// MARK: - Error Types

enum AnalyticsError: Error {
  case requestFailed
}
