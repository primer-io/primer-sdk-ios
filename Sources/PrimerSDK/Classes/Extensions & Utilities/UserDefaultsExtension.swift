//
//  UserDefaultsExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

import Foundation

internal extension UserDefaults {

    static var primerFramework: UserDefaults {
        if Primer.shared.integrationOptions?.reactNativeVersion == nil {
            return UserDefaults(suiteName: Bundle.primerFrameworkIdentifier) ?? UserDefaults.standard
        } else {
            return UserDefaults.standard
        }
    }
}
