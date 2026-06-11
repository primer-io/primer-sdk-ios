//
//  DefaultAnalyticsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

actor DefaultAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

  private let eventService: CheckoutComponentsAnalyticsServiceProtocol

  init(eventService: CheckoutComponentsAnalyticsServiceProtocol) {
    self.eventService = eventService
  }

  func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {
    await eventService.sendEvent(eventType, metadata: metadata)
  }
}
