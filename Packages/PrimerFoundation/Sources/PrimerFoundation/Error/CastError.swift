//
//  CastError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum CastError<T>: @unchecked Sendable, LocalizedError, CustomStringConvertible {
    case typeMismatch(value: Any, type: T.Type)
    
    public var description: String { errorDescription ?? "Unknown error" }
    
    public var errorDescription: String? {
        switch self {
        case let .typeMismatch(value, type): "Expected \(type) but found \(Swift.type(of: value)) instead."
        }
    }
}
