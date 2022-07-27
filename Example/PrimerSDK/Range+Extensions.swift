//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import Foundation


extension Range where Bound == String.Index {
    func toNSRange(in text: String) -> NSRange {
        return NSRange(self, in: text)
    }
}
