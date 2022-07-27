//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

internal extension Bundle {

    static var primerFramework: Bundle {
        return Bundle(for: Primer.self)
    }

    static var primerResources: Bundle {
        #if COCOAPODS
        let frameworkBundle = Bundle(for: Primer.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("PrimerResources.bundle")
        return Bundle(url: bundleURL!)!
        #else
        return Bundle.module
        #endif
    }

    static var primerFrameworkIdentifier: String {
        return Bundle.primerFramework.bundleIdentifier!
    }
    
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }

}

#endif
