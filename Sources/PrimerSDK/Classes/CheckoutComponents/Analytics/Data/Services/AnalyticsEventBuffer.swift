//
//  AnalyticsEventBuffer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

actor AnalyticsEventBuffer: LogReporter {

  typealias BufferedEvent = (
    eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?, timestamp: Int
  )

  private static let maxBufferSize = 100
  private var pendingEvents: [BufferedEvent] = []

  func buffer(eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?, timestamp: Int) {
    logger.debug(
      message: "[Analytics] Queued \(eventType.rawValue) - service not initialized yet")
    pendingEvents.append((eventType, metadata, timestamp))
    if pendingEvents.count > Self.maxBufferSize {
      pendingEvents.removeFirst(pendingEvents.count - Self.maxBufferSize)
    }
  }

  func flush() -> [BufferedEvent] {
    defer { pendingEvents.removeAll() }
    return pendingEvents
  }

  var hasBufferedEvents: Bool {
    !pendingEvents.isEmpty
  }

  var count: Int {
    pendingEvents.count
  }
}
