//
//  String+Extensions.swift
//  PrimerSDK_Example
//
//  Created by Dario Carlomagno on 27/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

extension String {

    public func allRanges(
        of aString: String,
        options: String.CompareOptions = [],
        range: Range<String.Index>? = nil,
        locale: Locale? = nil
    ) -> [Range<String.Index>] {

        // the slice within which to search
        let slice = (range == nil) ? self[...] : self[range!]

        var previousEnd = startIndex
        var ranges = [Range<String.Index>]()

        while let r = slice.range(
            of: aString, options: options,
            range: previousEnd ..< endIndex,
            locale: locale
        ) {
            if previousEnd != endIndex { // don't increment past the end
                previousEnd = index(after: r.lowerBound)
            }
            ranges.append(r)
        }

        return ranges
    }

    public func allRanges(
        of aString: String,
        options: String.CompareOptions = [],
        range: Range<String.Index>? = nil,
        locale: Locale? = nil
    ) -> [Range<Int>] {
        return allRanges(of: aString, options: options, range: range, locale: locale)
            .map(indexRangeToIntRange)
    }

    private func indexRangeToIntRange(_ range: Range<String.Index>) -> Range<Int> {
        return indexToInt(range.lowerBound) ..< indexToInt(range.upperBound)
    }

    private func indexToInt(_ index: String.Index) -> Int {
        return distance(from: startIndex, to: index)
    }
}

internal extension String {

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
