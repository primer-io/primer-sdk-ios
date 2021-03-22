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
    
    static var primerFrameworkIdentifier: String {
        return Bundle.primerFramework.bundleIdentifier!
    }
    
}
