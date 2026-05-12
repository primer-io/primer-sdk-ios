//
//  DeeplinkUtils.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@_spi(PrimerInternal)
public protocol DeeplinkAbilityProviding {
    func canOpenURL(_ url: URL) -> Bool
}

@_spi(PrimerInternal)
extension UIApplication: DeeplinkAbilityProviding {}
