//
//  BundleExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerResources

extension Bundle {

    static var primerFramework: Bundle {
        Bundle(for: Primer.self)
    }

    static var primerFrameworkIdentifier: String {
        Bundle.primerFramework.bundleIdentifier ?? "org.cocoapods.PrimerSDK"
    }

    var minimumOSVersion: String? {
        infoDictionary?["MinimumOSVersion"] as? String
    }
}
