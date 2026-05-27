//
//  AppLifecycleEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct AppLifecycleEventProperties: AnalyticsEventProperties {

    enum LifecycleType: String, Codable {
        case backgrounded = "APP_DID_ENTER_BACKGROUND"
        case foregrounded = "APP_WILL_ENTER_FOREGROUND"
    }

    let lifecycleType: LifecycleType
    var params: [String: AnyCodable]?

    init(lifecycleType: LifecycleType) {
        self.lifecycleType = lifecycleType
        let sdkProperties = SDKProperties()
        let dict = try? sdkProperties.asDictionary()
        let data = try? JSONSerialization.data(withJSONObject: dict as Any, options: .fragmentsAllowed)
        data.map { params = try? JSONDecoder().decode([String: AnyCodable].self, from: $0) }
    }
    
}
