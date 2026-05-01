//
//  Throwable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum Throwable<T: Decodable>: Decodable {
    case success(T)
    case failure(Error)

    public init(from decoder: Decoder) throws {
        do {
            let decoded = try T(from: decoder)
            self = .success(decoded)
        } catch let error {
            self = .failure(error)
        }
    }

    public var value: T? {
        switch self {
        case .failure:
            return nil
        case let .success(value):
            return value
        }
    }
}
