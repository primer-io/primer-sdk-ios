//
//  UserDefaultsExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal extension UserDefaults {

    static var primerFramework: UserDefaults {
        if Primer.shared.integrationOptions?.reactNativeVersion == nil {
            return UserDefaults(suiteName: Bundle.primerFrameworkIdentifier) ?? UserDefaults.standard
        } else {
            return UserDefaults.standard
        }
    }
}
