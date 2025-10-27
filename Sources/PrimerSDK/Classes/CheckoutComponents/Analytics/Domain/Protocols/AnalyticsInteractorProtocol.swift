//
//  AnalyticsInteractorProtocol.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation

/// Protocol defining the CheckoutComponents analytics interactor interface.
/// Domain layer abstraction for tracking analytics events in a fire-and-forget manner.
protocol CheckoutComponentsAnalyticsInteractorProtocol: Actor {
    /// Track an analytics event asynchronously without blocking the caller.
    /// Events are sent in a detached task to ensure non-blocking behavior.
    /// - Parameters:
    ///   - eventType: The type of event to track
    ///   - metadata: Optional event-specific metadata
    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async
}
