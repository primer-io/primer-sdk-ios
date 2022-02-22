//
//  RangeExtension.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 22/2/22.
//

import Foundation

extension Range where Bound == String.Index {
    func toNSRange(in text: String) -> NSRange {
        return NSRange(self, in: text)
    }
}
