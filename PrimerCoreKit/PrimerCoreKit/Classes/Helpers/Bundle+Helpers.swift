//
//  Bundle+Helpers.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 25/5/21.
//

import Foundation

internal extension Bundle {

    static var primerCoreKitFramework: Bundle {
        return Bundle(for: PrimerCoreKit.self)
    }

    static var primerCoreKitResources: Bundle {
        #if COCOAPODS
        let bundleURL = primerCoreKitFramework.resourceURL?.appendingPathComponent("PrimerCoreKitResources.bundle")
        return Bundle(url: bundleURL!)!
        #else
        // Swift Package Manager
        return Bundle.module
        #endif
    }

    static var primerFrameworkIdentifier: String {
        return Bundle.primerCoreKitFramework.bundleIdentifier!
    }

}
