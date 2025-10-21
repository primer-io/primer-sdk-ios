//
//  AnalyticsServiceProtocol.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation

/// Protocol defining the CheckoutComponents analytics event service interface.
/// Data layer abstraction for sending analytics events.
protocol CheckoutComponentsAnalyticsServiceProtocol: Actor {
    /// Initialize the analytics service with session configuration
    /// - Parameter config: Session configuration containing environment, tokens, and IDs
    func initialize(config: AnalyticsSessionConfig) async

    /// Send an analytics event
    /// - Parameters:
    ///   - eventType: The type of event to send
    ///   - metadata: Optional metadata specific to the event type
    func sendEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async
}
