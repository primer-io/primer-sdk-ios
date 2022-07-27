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

internal struct UILocalizableUtil {
    
    static var isRightToLeftLocale =  UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
}

#endif
