//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import Foundation

extension NSError {
    static var emptyDescriptionError: NSError {
        NSError(domain: "", code: 0001)
    }
}
