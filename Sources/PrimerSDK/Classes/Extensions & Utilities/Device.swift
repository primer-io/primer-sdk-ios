//
//  Device.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
import UIKit

extension Device {
    static var uniqueDeviceIdentifier: String {
        // Prefer identifierForVendor
        if let udid = UIDevice.current.identifierForVendor?.uuidString {
            return udid
        }
        let userDefaults = UserDefaults.primerFramework
        let udidKey = "Primer.uniqueDeviceIdentifier"
        // If we have a previous UDID, use it
        if let udid = userDefaults.string(forKey: udidKey) {
            return udid
        }
        // If we have no previous UDID, create one
        let udid = UUID().uuidString
        userDefaults.setValue(udid, forKey: udidKey)
        return udid
    }
}
