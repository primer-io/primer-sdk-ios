//
//  BundleExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

private final class BundleHelper {}

@_spi(PrimerInternal) public extension Bundle {

    static var primerResources: Bundle {
        #if COCOAPODS
            let bundleURL = Bundle(for: BundleHelper.self).resourceURL!.appendingPathComponent("PrimerResources.bundle")
            return Bundle(url: bundleURL)!
        #else
            return Bundle.module
        #endif
    }
}
