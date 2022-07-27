//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

extension UIScreen {
    
    static var isDarkModeEnabled: Bool {
        if #available(iOS 12.0, *) {
            return Self.main.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
}

#endif
