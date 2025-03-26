//
//  File.swift
//  
//
//  Created by Boris on 26.3.25..
//

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }

    func all(_ predicate: (Element) -> Bool) -> Bool {
        return self.allSatisfy(predicate)
    }
}
