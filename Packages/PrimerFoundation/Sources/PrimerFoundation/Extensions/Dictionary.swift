//
//  Dictionary.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Dictionary {
    func data(options: JSONSerialization.WritingOptions = []) throws -> Data {
		try JSONSerialization.data(withJSONObject: self, options: options)
	}
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        String(data: try data(), encoding: encoding)
    }
}
