//
//  PrimerSDKIntegrationType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum PrimerSDKIntegrationType: String, Codable {
    case dropIn     = "DROP_IN"
    case headless   = "HEADLESS"
    case checkoutComponents = "CHECKOUT_COMPONENTS"
}
