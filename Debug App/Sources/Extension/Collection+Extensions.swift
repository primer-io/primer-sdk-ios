//
//  Collection+Extensions.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

extension Collection {
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}
