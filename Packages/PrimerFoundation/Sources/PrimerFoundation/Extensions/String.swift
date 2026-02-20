//
//  String.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension String {
	func jsonObject<T>() throws -> T {
        do {
            let object = try JSONSerialization.jsonObject(with: Data(utf8), options: [])
            if let typedObject = object as? T {
                return typedObject
            } else {
                throw CastError.typeMismatch(value: object, type: T.self)
            }
        }
	}
    
    func unsafeData() -> Data { data(using: .utf8)! }
}
