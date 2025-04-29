//
//  CursorPositionManaging.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


public protocol CursorPositionManaging {
    /// Computes new cursor position after formatting
    func position(for raw: String, formatted: String, original: Int) -> Int
}