//
//  URLExtension.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension URLSession {
	func data(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
		let (data, response) = try await data(for: request)
		return (data, response())
	}
}
