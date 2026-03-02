//
//  BundleExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Bundle {

    static var primerResources: Bundle {
        #if COCOAPODS
        let frameworkBundle = Bundle(for: BundleMarker.self)
        guard
            let bundleURL = frameworkBundle.url(forResource: "PrimerResources", withExtension: "bundle"),
            let resourceBundle = Bundle(url: bundleURL) else {
            fatalError("PrimerResources.bundle not found")
        }
        return resourceBundle
        #else
        return .module
        #endif
    }
}

private class BundleMarker {}
