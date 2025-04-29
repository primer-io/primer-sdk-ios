//
//  CVVFormatter.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import Foundation

public struct CVVFormatter: FieldFormatter {
    public init() {}
    public func format(_ input: String) -> String {
        return input.filter { $0.isNumber }
    }
}