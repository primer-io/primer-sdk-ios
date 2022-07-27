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

internal protocol Parser {
    func parse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

#endif
