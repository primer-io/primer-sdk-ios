//
//  SDKEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct SDKEventProperties: AnalyticsEventProperties {

    var name: String
    var params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case name
        case params
    }

    init(name: String, params: [String: String]?) {
        self.name = name

        var parameters: [String: Any] = params ?? [:]

        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary() {
            parameters.merge(sdkPropertiesDict) {(current, _) in current}
        }

        if !parameters.isEmpty,
           let parametersData = try? JSONSerialization.data(withJSONObject: parameters, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: parametersData) {
                self.params = anyDecodableDictionary
            }
        } else {
            self.params = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(params, forKey: .params)
    }
}
