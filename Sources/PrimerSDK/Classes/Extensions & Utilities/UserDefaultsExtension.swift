//
//  UserDefaultsExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

extension UserDefaults {

    static var primerFramework: UserDefaults {
        if Primer.shared.integrationOptions?.reactNativeVersion == nil {
            UserDefaults(suiteName: Bundle.primerFrameworkIdentifier) ?? UserDefaults.standard
        } else {
            UserDefaults.standard
        }
    }
}
