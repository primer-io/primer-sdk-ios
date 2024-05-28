//
//  ArrayExtension.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import Foundation

internal extension Array where Element: Hashable & Comparable {
    var unique: [Element] {
        return Array(Set(self)).sorted()
    }
}

internal extension Array where Element: Equatable {
    func toBatches(of size: UInt) -> [[Element]] {
        return stride(from: 0, to: count, by: Int(size)).map {
            Array(self[$0 ..< Swift.min($0 + Int(size), count)])
        }
    }
}
