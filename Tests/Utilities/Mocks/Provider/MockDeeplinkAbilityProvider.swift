//
//  MockDeeplinkAbilityProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
@testable import PrimerSDK

struct MockDeeplinkAbilityProvider: DeeplinkAbilityProviding {
    var isDeeplinkAvailable = true

    func canOpenURL(_ url: URL) -> Bool {
        isDeeplinkAvailable
    }
}
