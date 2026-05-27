//
//  SDKProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct SDKProperties: Codable {

    let clientToken: String?
    let integrationType: String?
    let paymentMethodType: String?
    let sdkIntegrationType: PrimerSDKIntegrationType?
    let sdkIntent: PrimerSessionIntent?
    let sdkPaymentHandling: PrimerPaymentHandling?
    let sdkSessionId: String?
    let sdkSettings: [String: AnyCodable]?
    let sdkType: String?
    let sdkVersion: String?
    let context: [String: AnyCodable]?

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

    init() {
        self.clientToken = AppState.current.clientToken
        self.sdkIntegrationType = PrimerInternal.shared.sdkIntegrationType
        #if COCOAPODS
            self.integrationType = "COCOAPODS"
        #else
            self.integrationType = "SPM"
        #endif
        self.paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType
        self.sdkIntent = PrimerInternal.shared.intent
        self.sdkPaymentHandling = PrimerSettings.current.paymentHandling
        self.sdkSessionId = PrimerInternal.shared.checkoutSessionId

        self.sdkType = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"
        self.sdkVersion = VersionUtils.releaseVersionNumber
        self.context = nil

        if let settingsData = try? JSONEncoder().encode(PrimerSettings.current) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: settingsData) {
                self.sdkSettings = anyDecodableDictionary
                return
            }
        }

        self.sdkSettings = nil
    }

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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
