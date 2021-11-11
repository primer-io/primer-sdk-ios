//
//  ArrayExtension.swift
//  Pods-PrimerSDK_Example
//
//  Created by Evangelos on 11/11/21.
//

import Foundation

internal extension Array {
    func unique<T:Hashable>(map: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>()
        var arrayOrdered = [Element]()
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
