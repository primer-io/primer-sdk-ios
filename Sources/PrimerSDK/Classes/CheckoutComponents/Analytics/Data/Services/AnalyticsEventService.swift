//
//  AnalyticsEventService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

actor AnalyticsEventService: CheckoutComponentsAnalyticsServiceProtocol, LogReporter {

  private enum Delivery {
    static let maxQueuedEvents = 50
    static let maxSends = 3
    static let backgroundFlushLimit: UInt64 = 5_000_000_000
  }

  private struct QueuedEvent {
    let payload: AnalyticsPayload
    let endpoint: URL
    let token: String?
  }

  // MARK: - Dependencies

  private let payloadBuilder: AnalyticsPayloadBuilder
  private let networkClient: any AnalyticsEventSending
  private let eventBuffer: AnalyticsEventBuffer
  private let environmentProvider: AnalyticsEnvironmentProvider
  private let integrationSurfaceProvider: @Sendable () async -> String?
  /// Wait before the 2nd and the 3rd send.
  private let retryDelays: [UInt64]

  // MARK: - State

  private var sessionConfig: AnalyticsSessionConfig?
  private var integrationSurface: String?
  private var funnel = AnalyticsFunnelState()
  private var queue: [QueuedEvent] = []
  private var isDraining = false
  private var skipsRetryDelay = false
  private var backgroundObservation: Task<Void, Never>?

  // MARK: - Initialization

  init(
    payloadBuilder: AnalyticsPayloadBuilder,
    networkClient: any AnalyticsEventSending,
    eventBuffer: AnalyticsEventBuffer,
    environmentProvider: AnalyticsEnvironmentProvider,
    integrationSurfaceProvider: @escaping @Sendable () async -> String? = {
      await LoggingSessionContext.shared.getSessionData().integrationType?.rawValue
    },
    retryDelays: [UInt64] = [1_000_000_000, 2_000_000_000]
  ) {
    self.payloadBuilder = payloadBuilder
    self.networkClient = networkClient
    self.eventBuffer = eventBuffer
    self.environmentProvider = environmentProvider
    self.integrationSurfaceProvider = integrationSurfaceProvider
    self.retryDelays = retryDelays
  }

  deinit {
    backgroundObservation?.cancel()
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

  /// Starts a new checkout session: the funnel rules reset, then events that arrived early are sent.
  func initialize(config: AnalyticsSessionConfig) async {
    sessionConfig = config
    integrationSurface = await integrationSurfaceProvider()
    funnel = AnalyticsFunnelState()
    observeBackground()

    for (eventType, metadata, timestamp) in await eventBuffer.flush() {
      process(eventType, metadata: metadata, timestamp: timestamp)
    }
  }

  /// Queues the event and returns, so a slow endpoint never delays the payment.
  func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
    let timestamp = Int(Date().timeIntervalSince1970)
    guard sessionConfig != nil else {
      return await eventBuffer.buffer(eventType: eventType, metadata: metadata, timestamp: timestamp)
    }
    process(eventType, metadata: metadata, timestamp: timestamp)
  }

  // MARK: - Private Methods

  private func process(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?, timestamp: Int) {
    guard let sessionConfig else { return }
    guard let endpoint = environmentProvider.getEndpointURL(for: sessionConfig.environment) else {
      return logger.warn(
        message: "[Analytics] Dropped \(eventType.rawValue) - invalid endpoint for \(sessionConfig.environment.rawValue)"
      )
    }

    for output in funnel.process(eventType, metadata: metadata) {
      let payload = payloadBuilder.buildPayload(
        eventType: output.eventType,
        metadata: output.metadata,
        config: sessionConfig,
        timestamp: timestamp,
        envelope: output.envelope,
        integrationSurface: integrationSurface
      )
      enqueue(QueuedEvent(payload: payload, endpoint: endpoint, token: sessionConfig.clientSessionToken))
    }
  }

  private func enqueue(_ event: QueuedEvent) {
    queue.append(event)
    if queue.count > Delivery.maxQueuedEvents {
      logger.warn(message: "[Analytics] Queue full, dropped \(queue.removeFirst().payload.eventName)")
    }
    guard !isDraining else { return }
    isDraining = true
    Task { await drain() }
  }

  /// Sends one event at a time, so the collector receives them in order.
  private func drain() async {
    while !queue.isEmpty {
      await deliver(queue.removeFirst())
    }
    isDraining = false
    skipsRetryDelay = false
  }

  private func deliver(_ event: QueuedEvent) async {
    for sendIndex in 0 ..< Delivery.maxSends {
      do {
        return try await networkClient.send(payload: event.payload, to: event.endpoint, token: event.token)
      } catch {
        guard Self.isRetryable(error), sendIndex < Delivery.maxSends - 1 else {
          return logger.error(
            message: "[Analytics] Failed to send \(event.payload.eventName): \(error.localizedDescription)"
          )
        }
        if !skipsRetryDelay, sendIndex < retryDelays.count {
          try? await Task.sleep(nanoseconds: retryDelays[sendIndex])
        }
      }
    }
  }

  private static func isRetryable(_ error: Error) -> Bool {
    switch error {
    case let AnalyticsError.httpStatus(status): status >= 500 || status == 408 || status == 429
    case is URLError: true
    default: false
    }
  }

  // MARK: - Background Flush

  private func observeBackground() {
    guard backgroundObservation == nil else { return }
    backgroundObservation = Task { [weak self] in
      for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
        await self?.flushForBackground()
      }
    }
  }

  private func flushForBackground() async {
    guard isDraining else { return }
    skipsRetryDelay = true
    let taskId = await MainActor.run { UIApplication.shared.beginBackgroundTask(withName: "PrimerAnalyticsFlush") }
    let deadline = DispatchTime.now().uptimeNanoseconds + Delivery.backgroundFlushLimit
    while isDraining, DispatchTime.now().uptimeNanoseconds < deadline {
      try? await Task.sleep(nanoseconds: 50_000_000)
    }
    await MainActor.run { UIApplication.shared.endBackgroundTask(taskId) }
  }
}

// MARK: - Errors

enum AnalyticsError: Error {
  case requestFailed
  case httpStatus(Int)
}
