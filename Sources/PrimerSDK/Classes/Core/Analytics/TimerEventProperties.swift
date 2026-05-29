//
//  TimerEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

struct TimerEventProperties: AnalyticsEventProperties {

    var momentType: Analytics.Event.Property.TimerType
    var id: String?
    var params: [String: AnyCodable]?
    var duration: TimeInterval?
    var context: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case momentType
        case id
        case params
        case duration
        case context
    }

    init(
        momentType: Analytics.Event.Property.TimerType,
        id: String?,
        duration: TimeInterval? = nil,
        context: [String: Any]? = nil
    ) {
        self.momentType = momentType
        self.id = id
        self.duration = duration
        self.context = context

        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                self.params = anyDecodableDictionary
            }
        } else {
            self.params = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.momentType = try container.decode(Analytics.Event.Property.TimerType.self, forKey: .momentType)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.context = try container.decodeIfPresent([String: Any].self, forKey: .context)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(momentType, forKey: .momentType)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(params, forKey: .params)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(context, forKey: .context)
    }
}
