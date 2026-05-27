//
//  NetworkConnectivityEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct NetworkConnectivityEventProperties: AnalyticsEventProperties {

    var networkType: Connectivity.NetworkType
    var params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case networkType
        case params
    }

    init(networkType: Connectivity.NetworkType) {
        self.networkType = networkType

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
        self.networkType = try container.decode(Connectivity.NetworkType.self, forKey: .networkType)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(networkType, forKey: .networkType)
        try container.encodeIfPresent(params, forKey: .params)
    }
}
