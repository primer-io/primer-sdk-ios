//
//  TimerEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct TimerEventProperties: AnalyticsEventProperties {

    public let momentType: Analytics.Event.Property.TimerType
    public let id: String?
    public let params: [String: AnyCodable]?
    public let duration: TimeInterval?
    public let context: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case momentType
        case id
        case params
        case duration
        case context
    }
    
    public init(
        momentType: Analytics.Event.Property.TimerType,
        id: String? = nil,
        params: [String: AnyCodable]? = nil,
        duration: TimeInterval? = nil,
        context: [String: Any]? = nil
    ) {
        self.momentType = momentType
        self.id = id
        self.params = params
        self.duration = duration
        self.context = context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.momentType = try container.decode(Analytics.Event.Property.TimerType.self, forKey: .momentType)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.context = try container.decodeIfPresent([String: Any].self, forKey: .context)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(momentType, forKey: .momentType)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(params, forKey: .params)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(context, forKey: .context)
    }
}
