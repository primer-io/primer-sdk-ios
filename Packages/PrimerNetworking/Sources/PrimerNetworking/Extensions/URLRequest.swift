//
//  URLRequest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public typealias HTTPHeaders = [String: String]

public extension URLRequest {
	var requestId: String? { allHTTPHeaderFields?["X-Request-ID"] }
}

extension URLRequest {
	init<E, D>(endpoint: Endpoint<E, D>) throws {
		let baseURL = endpoint.baseURL
        let url = endpoint.path.map { baseURL.appendingPathComponent($0) } ?? baseURL
		self.init(url: url)
		
        switch endpoint.method {
		case .get:
			httpMethod = "GET"
		case let .post(body):
			httpMethod = "POST"
			httpBody = try JSONEncoder().encode(body)
			setValue("application/json", forHTTPHeaderField: "Content-Type")
		case let .put(body):
			httpMethod = "PUT"
			httpBody = try JSONEncoder().encode(body)
			setValue("application/json", forHTTPHeaderField: "Content-Type")
		case .delete:
			httpMethod = "DELETE"
		}
        
		var headers = endpoint.headers
		headers?["X-Request-ID"] = UUID().uuidString
		allHTTPHeaderFields = headers
		endpoint.timeout.map { timeoutInterval = $0 }
	}
}
