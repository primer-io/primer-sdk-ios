//
//  CardNumberFormatter.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import Foundation

public struct CardNumberFormatter: FieldFormatter {
    private let groupSizes: [Int]
    public init(groupSizes: [Int] = [4,4,4,4]) {
        self.groupSizes = groupSizes
    }
    public func format(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        var result = ""
        var index = digits.startIndex
        for size in groupSizes where index < digits.endIndex {
            let end = digits.index(index, offsetBy: size, limitedBy: digits.endIndex) ?? digits.endIndex
            result += digits[index..<end]
            if end < digits.endIndex { result += " " }
            index = end
        }
        return result
    }
}