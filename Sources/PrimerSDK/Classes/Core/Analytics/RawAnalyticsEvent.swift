//
//  RawAnalyticsEvent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

struct RawAnalyticsEvent: AnalyticsEvent, Codable {
    let analyticsUrl: String?
    let localId: String
    let createdAt: Int
    let payload: CodableValue

    init(payload: CodableValue) {
        let params = try? payload.casted(to: AnalyticsStepParams.self)
        self.analyticsUrl = params?.analyticsUrl
        self.localId = String.randomString(length: 32)
        self.createdAt = Date().millisecondsSince1970
        self.payload = payload
    }
}

extension RawAnalyticsEvent: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.localId == rhs.localId }
}

private struct AnalyticsStepParams: Decodable {
    fileprivate let analyticsUrl: String
}
