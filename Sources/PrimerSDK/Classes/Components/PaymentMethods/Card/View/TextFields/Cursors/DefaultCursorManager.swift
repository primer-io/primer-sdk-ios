//
//  DefaultCursorManager.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import Foundation

public class DefaultCursorManager: CursorPositionManaging {
    public init() {}
    public func position(for raw: String, formatted: String, original: Int) -> Int {
        return formatted.count
    }
}