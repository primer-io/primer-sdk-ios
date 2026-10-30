//
//  ComponentsAnalyticsEventResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

protocol RawAnalyticsEventSending: Actor {
  func sendRawEvent(named eventName: String, fields: [String: CodableValue]) async
}

@available(iOS 15.0, *)
struct ComponentsAnalyticsEventResolver: StepResolver {
  let analyticsService: any RawAnalyticsEventSending

  func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
    if case let .object(fields) = data, case let .string(eventName)? = fields["eventName"], !eventName.isEmpty {
      await analyticsService.sendRawEvent(named: eventName, fields: fields)
    }
    return StepResolutionResult(outcome: .success)
  }
}
