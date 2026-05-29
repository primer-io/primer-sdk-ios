//
//  NetworkCallEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

struct NetworkCallEventProperties: AnalyticsEventProperties {

    var callType: Analytics.Event.Property.NetworkCallType
    var id: String
    var url: String
    var method: HTTPMethod
    var errorBody: String?
    var responseCode: Int?
    var params: [String: AnyCodable]?
    var duration: TimeInterval?

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

    init(
        callType: Analytics.Event.Property.NetworkCallType,
        id: String,
        url: String,
        method: HTTPMethod,
        errorBody: String?,
        responseCode: Int?,
        duration: TimeInterval? = nil
    ) {
        self.callType = callType
        self.id = id
        self.url = url
        self.method = method
        self.errorBody = errorBody
        self.responseCode = responseCode
        self.duration = duration

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
        self.callType = try container.decode(Analytics.Event.Property.NetworkCallType.self, forKey: .callType)
        self.id = try container.decode(String.self, forKey: .id)
        self.url = try container.decode(String.self, forKey: .url)
        self.method = try container.decode(HTTPMethod.self, forKey: .method)
        self.errorBody = try container.decodeIfPresent(String.self, forKey: .errorBody)
        self.responseCode = try container.decodeIfPresent(Int.self, forKey: .responseCode)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }

    func encode(to encoder: Encoder) throws {
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
