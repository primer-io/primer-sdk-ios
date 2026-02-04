//
//  NetworkCallEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct NetworkCallEventProperties: AnalyticsEventProperties {

    public let callType: Analytics.Event.Property.NetworkCallType
    public let id: String
    public let url: String
    public let method: String
    public let errorBody: String?
    public let responseCode: Int?
    public let params: [String: AnyCodable]?
    public let duration: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case callType
        case id
        case url
        case method
        case errorBody
        case responseCode
        case params
        case duration
    }
    
    public init(
        callType: Analytics.Event.Property.NetworkCallType,
        id: String,
        url: String,
        method: String,
        errorBody: String? = nil,
        responseCode: Int? = nil,
        params: [String: AnyCodable]? = nil,
        duration: TimeInterval? = nil
    ) {
        self.callType = callType
        self.id = id
        self.url = url
        self.method = method
        self.errorBody = errorBody
        self.responseCode = responseCode
        self.params = params
        self.duration = duration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.callType = try container.decode(Analytics.Event.Property.NetworkCallType.self, forKey: .callType)
        self.id = try container.decode(String.self, forKey: .id)
        self.url = try container.decode(String.self, forKey: .url)
        self.method = try container.decode(String.self, forKey: .method)
        self.errorBody = try container.decodeIfPresent(String.self, forKey: .errorBody)
        self.responseCode = try container.decodeIfPresent(Int.self, forKey: .responseCode)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callType, forKey: .callType)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(errorBody, forKey: .errorBody)
        try container.encodeIfPresent(responseCode, forKey: .responseCode)
        try container.encodeIfPresent(params, forKey: .params)
        try container.encodeIfPresent(duration, forKey: .duration)
    }
}
