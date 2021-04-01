//
//  BundleExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

#if canImport(UIKit)

import Foundation

internal extension Bundle {

    static var primerFramework: Bundle {
        return Bundle(for: Primer.self)
    }
    
    static var primerResources: Bundle {
        let frameworkBundle = Bundle(for: Primer.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("PrimerResources.bundle")
        return Bundle(url: bundleURL!)!
    }

    static var primerFrameworkIdentifier: String {
        return Bundle.primerFramework.bundleIdentifier!
    }

}

#endif
