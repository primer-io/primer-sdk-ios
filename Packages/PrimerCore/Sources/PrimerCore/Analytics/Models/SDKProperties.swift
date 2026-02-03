//
//  SDKProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public struct SDKProperties: Codable {

    public let clientToken: String?
    public let integrationType: String?
    public let paymentMethodType: String?
    public let sdkIntegrationType: PrimerSDKIntegrationType?
    public let sdkIntent: PrimerSessionIntent?
    public let sdkPaymentHandling: PrimerPaymentHandling?
    public let sdkSessionId: String?
    public let sdkSettings: [String: AnyCodable]?
    public let sdkType: String?
    public let sdkVersion: String?
    public let context: [String: AnyCodable]?
    
    public init(
        clientToken: String? = nil,
        integrationType: String? = nil,
        paymentMethodType: String? = nil,
        sdkIntegrationType: PrimerSDKIntegrationType? = nil,
        sdkIntent: PrimerSessionIntent? = nil,
        sdkPaymentHandling: PrimerPaymentHandling? = nil,
        sdkSessionId: String? = nil,
        sdkSettings: [String: AnyCodable]? = nil,
        sdkType: String? = nil,
        sdkVersion: String? = nil,
        context: [String: AnyCodable]? = nil
    ) {
        self.clientToken = clientToken
        self.integrationType = integrationType
        self.paymentMethodType = paymentMethodType
        self.sdkIntegrationType = sdkIntegrationType
        self.sdkIntent = sdkIntent
        self.sdkPaymentHandling = sdkPaymentHandling
        self.sdkSessionId = sdkSessionId
        self.sdkSettings = sdkSettings
        self.sdkType = sdkType
        self.sdkVersion = sdkVersion
        self.context = context
    }
    
    private enum CodingKeys: String, CodingKey {
        case clientToken
        case integrationType
        case paymentMethodType
        case sdkIntegrationType
        case sdkIntent
        case sdkPaymentHandling
        case sdkSessionId
        case sdkSettings
        case sdkType
        case sdkVersion
        case context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientToken = try container.decodeIfPresent(String.self, forKey: .clientToken)
        self.integrationType = try container.decodeIfPresent(String.self, forKey: .integrationType)
        self.paymentMethodType = try container.decodeIfPresent(String.self, forKey: .paymentMethodType)
        self.sdkIntegrationType = try container.decodeIfPresent(PrimerSDKIntegrationType.self, forKey: .sdkIntegrationType)
        self.sdkIntent = try container.decodeIfPresent(PrimerSessionIntent.self, forKey: .sdkIntent)
        self.sdkPaymentHandling = try container.decodeIfPresent(PrimerPaymentHandling.self, forKey: .sdkPaymentHandling)
        self.sdkSessionId = try container.decodeIfPresent(String.self, forKey: .sdkSessionId)
        self.sdkSettings = try container.decodeIfPresent([String: AnyCodable].self, forKey: .sdkSettings)
        self.sdkType = try container.decodeIfPresent(String.self, forKey: .sdkType)
        self.sdkVersion = try container.decodeIfPresent(String.self, forKey: .sdkVersion)
        self.context = try container.decodeIfPresent([String: AnyCodable].self, forKey: .context)

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(clientToken, forKey: .clientToken)
        try container.encodeIfPresent(integrationType, forKey: .integrationType)
        try container.encodeIfPresent(paymentMethodType, forKey: .paymentMethodType)
        try container.encodeIfPresent(sdkIntent, forKey: .sdkIntent)
        try container.encodeIfPresent(sdkPaymentHandling, forKey: .sdkPaymentHandling)
        try container.encodeIfPresent(sdkSettings, forKey: .sdkSettings)
        try container.encodeIfPresent(sdkSessionId, forKey: .sdkSessionId)
        try container.encodeIfPresent(sdkSettings, forKey: .sdkSettings)
        try container.encodeIfPresent(sdkType, forKey: .sdkType)
        try container.encodeIfPresent(sdkVersion, forKey: .sdkVersion)
        try container.encodeIfPresent(context, forKey: .context)
    }
}
