//
//  Range+Extensions.swift
//  PrimerSDK_Example
//
//  Created by Dario Carlomagno on 27/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation


extension Range where Bound == String.Index {
    func toNSRange(in text: String) -> NSRange {
        return NSRange(self, in: text)
    }
}
