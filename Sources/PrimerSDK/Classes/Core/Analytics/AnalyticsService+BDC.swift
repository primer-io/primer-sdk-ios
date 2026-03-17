//
//  AnalyticsService+BDC.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerStepResolver

extension Analytics.Service: StepResolver {
    func resolve(_ step: Data) async throws -> Data? {
        let analyticsStepParams = try JSONDecoder().decode(AnalyticsStepParams.self, from: step)
        let properties = try JSONEncoder().encode(analyticsStepParams.properties)
        print("[ANALYTICS HANDLER] Firing event: \(try! analyticsStepParams.properties.jsonString)")
        print("\n")
        fire(event: .bdcEvent(event: analyticsStepParams.eventType, data: properties))
        return nil
    }
}

private struct AnalyticsStepParams: Decodable {
    let eventType: String
    let properties: CodableValue
}
