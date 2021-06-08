//
//  UserDefaultsExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

#if canImport(UIKit)

import Foundation

internal extension UserDefaults {

    static var primerFramework: UserDefaults {
        return UserDefaults(suiteName: Bundle.primerFrameworkIdentifier)!
    }

    func clearPrimerFramework() {
        UserDefaults.primerFramework.removePersistentDomain(forName: Bundle.primerFrameworkIdentifier)
        UserDefaults.primerFramework.synchronize()
    }

}

#endif
