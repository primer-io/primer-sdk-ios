//
//  String.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import struct Foundation.UUID

public extension String {
    static let uuid = UUID().uuidString
}
