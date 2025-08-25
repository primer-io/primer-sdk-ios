//
//  BundleExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal extension Bundle {

    static var primerFramework: Bundle {
        return Bundle(for: Primer.self)
    }

    static var primerResources: Bundle {
        #if COCOAPODS
        let bundleURL = Bundle.primerFramework.resourceURL?.appendingPathComponent("PrimerResources.bundle")
        return Bundle(url: bundleURL!)!
        #else
        return Bundle.module
        #endif
    }

    static var primerFrameworkIdentifier: String {
        return Bundle.primerFramework.bundleIdentifier ?? "org.cocoapods.PrimerSDK"
    }

    var minimumOSVersion: String? {
        return infoDictionary?["MinimumOSVersion"] as? String
    }
}
