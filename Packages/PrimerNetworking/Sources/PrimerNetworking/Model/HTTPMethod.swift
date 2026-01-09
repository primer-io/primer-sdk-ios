//
//  HTTPMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum HTTPMethod {
	case get
	case post(Encodable)
	case put(Encodable)
	case delete
}
