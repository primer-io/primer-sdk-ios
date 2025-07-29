//
//  DeeplinkUtils.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

protocol DeeplinkAbilityProviding {
    func canOpenURL(_ url: URL) -> Bool
}

extension UIApplication: DeeplinkAbilityProviding {}
