//
//  Sequence+Helpers.swift
//  Primer3DS
//
//  Created by Evangelos Pittas on 4/5/23.
//

#if canImport(UIKit)

import Foundation

internal extension Sequence where Element: Hashable {
    
    var unique: [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

#endif
