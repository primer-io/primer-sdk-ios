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

internal class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}

#endif
