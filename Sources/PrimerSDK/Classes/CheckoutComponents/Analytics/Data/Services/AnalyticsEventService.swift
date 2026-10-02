//
//  AnalyticsEventService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Network
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
  private let sleep: @Sendable (UInt64) async -> Void
  private let beginBackgroundTask: @MainActor @Sendable () -> UIBackgroundTaskIdentifier
  private let endBackgroundTask: @MainActor @Sendable (UIBackgroundTaskIdentifier) -> Void
  private let connectivity: AnalyticsConnectivity
  private let selectedMethods: SelectedMethodsMemory

  // MARK: - State

  private var sessionConfig: AnalyticsSessionConfig?
  private var integrationSurface: String?
  private var funnel = AnalyticsFunnelState()
  private var isStarting = false
  private var arrivedWhileStarting: [AnalyticsEventBuffer.BufferedEvent] = []
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
    retryDelays: [UInt64] = [1_000_000_000, 2_000_000_000],
    sleep: @escaping @Sendable (UInt64) async -> Void = { try? await Task.sleep(nanoseconds: $0) },
    beginBackgroundTask: @escaping @MainActor @Sendable () -> UIBackgroundTaskIdentifier = {
      UIApplication.shared.beginBackgroundTask(withName: "PrimerAnalyticsFlush")
    },
    endBackgroundTask: @escaping @MainActor @Sendable (UIBackgroundTaskIdentifier) -> Void = {
      UIApplication.shared.endBackgroundTask($0)
    },
    connectivity: AnalyticsConnectivity = PathMonitorConnectivity.shared,
    selectedMethods: SelectedMethodsMemory = .shared
  ) {
    self.payloadBuilder = payloadBuilder
    self.networkClient = networkClient
    self.eventBuffer = eventBuffer
    self.environmentProvider = environmentProvider
    self.integrationSurfaceProvider = integrationSurfaceProvider
    self.retryDelays = retryDelays
    self.sleep = sleep
    self.beginBackgroundTask = beginBackgroundTask
    self.endBackgroundTask = endBackgroundTask
    self.connectivity = connectivity
    self.selectedMethods = selectedMethods
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
    // Events that arrive during the awaits wait too, so none uses the old session or overtakes an earlier one.
    isStarting = true
    let surface = await integrationSurfaceProvider()
    let early = await eventBuffer.flush()
    sessionConfig = config
    integrationSurface = surface
    funnel = AnalyticsFunnelState(selectedMethods: selectedMethods.methods(for: config.clientSessionId))
    isStarting = false
    observeBackground()

    for (eventType, metadata, timestamp) in early + arrivedWhileStarting {
      process(eventType, metadata: metadata, timestamp: timestamp)
    }
    arrivedWhileStarting = []
  }

  /// Queues the event and returns, so a slow endpoint never delays the payment.
  func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
    let timestamp = Int(Date().timeIntervalSince1970)
    if isStarting { return arrivedWhileStarting.append((eventType, metadata, timestamp)) }
    guard sessionConfig != nil else {
      return await eventBuffer.buffer(eventType: eventType, metadata: metadata, timestamp: timestamp)
    }
    process(eventType, metadata: metadata, timestamp: timestamp)
  }

  func recordThreeDSOutcome(_ outcome: AnalyticsFunnelState.ThreeDSOutcome) async {
    funnel.recordThreeDSOutcome(outcome)
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
    if eventType == .paymentMethodSelection {
      selectedMethods.remember(funnel.selectedMethods, for: sessionConfig.clientSessionId)
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
    var sendIndex = 0
    while sendIndex < Delivery.maxSends {
      do {
        return try await networkClient.send(payload: event.payload, to: event.endpoint, token: event.token)
      } catch {
        // As on Web, a send while the device is offline costs no attempt: the event waits for the network.
        if error is URLError, connectivity.isOffline {
          await connectivity.waitUntilOnline()
          continue
        }
        guard Self.isRetryable(error), sendIndex < Delivery.maxSends - 1 else {
          return logger.error(
            message: "[Analytics] Failed to send \(event.payload.eventName): \(error.localizedDescription)"
          )
        }
        if !skipsRetryDelay, sendIndex < retryDelays.count {
          await sleep(retryDelays[sendIndex])
        }
        sendIndex += 1
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
    let taskId = await beginBackgroundTask()
    let deadline = DispatchTime.now().uptimeNanoseconds + Delivery.backgroundFlushLimit
    while isDraining, DispatchTime.now().uptimeNanoseconds < deadline {
      try? await Task.sleep(nanoseconds: 50_000_000)
    }
    await endBackgroundTask(taskId)
  }
}

// MARK: - Errors

enum AnalyticsError: Error {
  case requestFailed
  case httpStatus(Int)
}

// MARK: - Connectivity

protocol AnalyticsConnectivity: Sendable {
  var isOffline: Bool { get }
  func waitUntilOnline() async
}

final class PathMonitorConnectivity: AnalyticsConnectivity, @unchecked Sendable {
  static let shared = PathMonitorConnectivity()

  private let monitor = NWPathMonitor()
  private let lock = NSLock()
  // Online until the first path update says otherwise, so a slow monitor never holds an event.
  private var isOnline = true
  private var waiters: [CheckedContinuation<Void, Never>] = []

  private init() {
    monitor.pathUpdateHandler = { [weak self] in self?.update(isOnline: $0.status == .satisfied) }
    monitor.start(queue: DispatchQueue(label: "io.primer.analytics.connectivity"))
  }

  var isOffline: Bool {
    lock.lock()
    defer { lock.unlock() }
    return !isOnline
  }

  func waitUntilOnline() async {
    await withCheckedContinuation { continuation in
      lock.lock()
      guard !isOnline else {
        lock.unlock()
        return continuation.resume()
      }
      waiters.append(continuation)
      lock.unlock()
    }
  }

  private func update(isOnline: Bool) {
    lock.lock()
    self.isOnline = isOnline
    let resumed = isOnline ? waiters : []
    if isOnline { waiters = [] }
    lock.unlock()
    resumed.forEach { $0.resume() }
  }
}

// MARK: - Selected Methods

/// SELECTION goes out once per method per client session. An inline remount builds a new service, so the
/// methods already selected live here, for the latest client session only.
final class SelectedMethodsMemory: @unchecked Sendable {
  static let shared = SelectedMethodsMemory()

  private let lock = NSLock()
  private var clientSessionId: String?
  private var methods: Set<String> = []

  func methods(for clientSessionId: String) -> Set<String> {
    lock.lock()
    defer { lock.unlock() }
    return clientSessionId == self.clientSessionId ? methods : []
  }

  func remember(_ methods: Set<String>, for clientSessionId: String) {
    lock.lock()
    defer { lock.unlock() }
    self.clientSessionId = clientSessionId
    self.methods = methods
  }
}
