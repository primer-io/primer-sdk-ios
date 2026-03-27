//
//  AnalyticsService+BDC.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerStepResolver

extension Analytics.Service: StepResolver {
    func resolve(_ step: CodableValue) async throws -> CodableValue? {
        let params = try step.casted(to: AnalyticsStepParams.self)
        let properties = try JSONEncoder().encode(params.properties)
        let event: Analytics.Event? = .bdcEvent(event: params.eventType, data: properties)
        event.map(fire(event:))
        return nil
    }
}

private struct AnalyticsStepParams: Decodable {
    fileprivate let eventType: String
    fileprivate let properties: CodableValue
}
