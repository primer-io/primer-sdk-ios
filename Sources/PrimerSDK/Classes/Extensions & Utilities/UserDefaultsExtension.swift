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

internal extension UserDefaults {

    static var primerFramework: UserDefaults {
        return UserDefaults(suiteName: Bundle.primerFrameworkIdentifier) ?? UserDefaults.standard
    }

    func clearPrimerFramework() {
        UserDefaults.primerFramework.removePersistentDomain(forName: Bundle.primerFrameworkIdentifier)
        UserDefaults.primerFramework.synchronize()
    }

}

#endif
