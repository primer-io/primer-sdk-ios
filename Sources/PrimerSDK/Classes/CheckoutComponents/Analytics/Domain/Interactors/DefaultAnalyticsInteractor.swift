//
//  DefaultAnalyticsInteractor.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation

/// Default implementation of CheckoutComponents analytics interactor.
/// Provides fire-and-forget event tracking using detached tasks for non-blocking behavior.
actor DefaultAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

    // MARK: - Dependencies

    private let eventService: CheckoutComponentsAnalyticsServiceProtocol

    // MARK: - Initialization

    init(eventService: CheckoutComponentsAnalyticsServiceProtocol) {
        self.eventService = eventService
    }

    // MARK: - CheckoutComponentsAnalyticsInteractorProtocol

    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
        // Launch a child task to keep fire-and-forget behavior without leaving structured concurrency
        // This prevents blocking the caller even if the service is busy
        _ = Task { [eventService] in
            await eventService.sendEvent(eventType, metadata: metadata)
        }
    }
}
