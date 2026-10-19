//
//  FunnelAnalyticsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Runs every tracked event through the real `AnalyticsFunnelState`, so a test sees exactly the events
/// that would be sent, after the contract's drop and attempt rules. Attempt ids are `attempt-1`, `attempt-2`...
@available(iOS 15.0, *)
actor FunnelAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

    struct Sent: Equatable, CustomStringConvertible {
        let event: AnalyticsEventType
        let paymentMethod: String?
        let attemptId: String?
        let reason: String?

        init(_ event: AnalyticsEventType, _ paymentMethod: String? = nil, attempt: Int? = nil, reason: String? = nil) {
            self.event = event
            self.paymentMethod = paymentMethod
            attemptId = attempt.map { "attempt-\($0)" }
            self.reason = reason
        }

        init(_ output: AnalyticsFunnelState.Output) {
            event = output.eventType
            paymentMethod = output.metadata?.paymentMethod ?? output.envelope.paymentMethod
            attemptId = output.envelope.attemptId
            reason = output.metadata?.paymentEvent?.reason
        }

        var description: String {
            [event.rawValue, paymentMethod, attemptId, reason].compactMap(\.self).joined(separator: " ")
        }
    }

    private var funnel: AnalyticsFunnelState
    private(set) var outputs: [AnalyticsFunnelState.Output] = []

    init() {
        let ids = SequentialAttemptIds()
        funnel = AnalyticsFunnelState(makeAttemptId: { ids.next() })
    }

    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        outputs += funnel.process(eventType, metadata: metadata)
    }

    func recordThreeDSOutcome(_ outcome: AnalyticsFunnelState.ThreeDSOutcome) async {
        funnel.recordThreeDSOutcome(outcome)
    }

    var sent: [Sent] { outputs.map(Sent.init) }

    var sentEvents: [AnalyticsEventType] { outputs.map(\.eventType) }

    /// Waits until `event` was sent `count` times. Events arrive on their own tasks, so a test waits for the last one it expects.
    func waitFor(_ event: AnalyticsEventType, count: Int = 1, timeout: TimeInterval = 3) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while outputs.filter({ $0.eventType == event }).count < count {
            if Date() > deadline { throw Timeout(waitingFor: event, sent: sent) }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    struct Timeout: Error, CustomStringConvertible {
        let waitingFor: AnalyticsEventType
        let sent: [Sent]

        var description: String { "Timed out waiting for \(waitingFor.rawValue). Sent: \(sent)" }
    }

    /// For a negative check: lets in-flight events land before the test reads `sent`.
    func settle() async throws {
        var count = -1
        while count != outputs.count {
            count = outputs.count
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}

private final class SequentialAttemptIds: @unchecked Sendable {
    private var count = 0
    private let lock = NSLock()

    func next() -> String {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return "attempt-\(count)"
    }
}
