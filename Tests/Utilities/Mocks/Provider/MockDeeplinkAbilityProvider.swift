//
//  MockDeeplinkAbilityProvider.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

struct MockDeeplinkAbilityProvider: DeeplinkAbilityProviding {
    var isDeeplinkAvailable = true

    func canOpenURL(_ url: URL) -> Bool {
        isDeeplinkAvailable
    }
}
