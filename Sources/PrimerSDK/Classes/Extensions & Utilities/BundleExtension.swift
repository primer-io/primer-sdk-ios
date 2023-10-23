//
//  BundleExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//



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


