//
//  URL.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension URL: @retroactive ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self = URL(string: value)!
	}
}
