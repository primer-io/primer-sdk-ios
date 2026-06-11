//
//  AppLifecycleEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal) public struct AppLifecycleEventProperties: AnalyticsEventProperties {

    public enum LifecycleType: String, Codable {
        case backgrounded = "APP_DID_ENTER_BACKGROUND"
        case foregrounded = "APP_WILL_ENTER_FOREGROUND"
    }

    public let lifecycleType: LifecycleType
    public var params: [String: AnyCodable]?

    public init(lifecycleType: LifecycleType, params: [String: AnyCodable]?) {
        self.lifecycleType = lifecycleType
        self.params = params
    }
}
