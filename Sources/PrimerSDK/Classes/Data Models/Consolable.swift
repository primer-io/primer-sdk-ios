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

@propertyWrapper
struct Consolable<T> {

    var wrappedValue: T {
        didSet {
            #if DEBUG
            log(logLevel: .verbose, message: "Did set \(type(of: wrappedValue))")
            #endif
        }
    }

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

#endif
