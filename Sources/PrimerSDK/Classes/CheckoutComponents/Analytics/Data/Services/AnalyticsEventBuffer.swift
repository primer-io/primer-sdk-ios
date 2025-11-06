//
//  AnalyticsEventBuffer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Responsible for buffering analytics events before the service is fully initialized.
/// Once initialization completes, buffered events are flushed in order.
actor AnalyticsEventBuffer: LogReporter {

    // MARK: - Types

    typealias BufferedEvent = (eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?, timestamp: Int)

    // MARK: - State

    private var pendingEvents: [BufferedEvent] = []

    // MARK: - Public Methods

    /// Add an event to the buffer
    /// - Parameters:
    ///   - eventType: The type of event to buffer
    ///   - metadata: Optional event metadata
    ///   - timestamp: UNIX timestamp when the event occurred
    func buffer(eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?, timestamp: Int) {
        logger.debug(message: "📊 [Analytics] Queued \(eventType.rawValue) - service not initialized yet")
        pendingEvents.append((eventType, metadata, timestamp))
    }

    /// Retrieve all buffered events and clear the buffer
    /// - Returns: Array of buffered events in the order they were added
    func flush() -> [BufferedEvent] {
        let bufferedEvents = pendingEvents
        pendingEvents.removeAll()
        return bufferedEvents
    }

    /// Check if there are any buffered events
    var hasBufferedEvents: Bool {
        !pendingEvents.isEmpty
    }

    /// Get the number of buffered events
    var count: Int {
        pendingEvents.count
    }
}
