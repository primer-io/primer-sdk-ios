//
//  ArrayExtension.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

internal extension Array where Element: Equatable {
    
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
    
    func toBatches(of size: UInt) -> [[Element]] {
            return stride(from: 0, to: count, by: Int(size)).map {
                Array(self[$0 ..< Swift.min($0 + Int(size), count)])
            }
        }
}

extension Array where Element:Weak<AnyObject> {
    mutating func reap () {
        self = self.filter { nil != $0.value }
    }
}

#endif
