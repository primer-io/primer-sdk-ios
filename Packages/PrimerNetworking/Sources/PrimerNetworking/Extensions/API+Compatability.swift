//
//  API+Compatability.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension API {
	func call<E, D>(
		_ endpoint: Endpoint<E, D>,
		beforeAction: BeforeNetworkingAction? = nil,
	) async throws -> (D, HTTPURLResponse)  {
		try await execute(try URLRequest(endpoint: endpoint), beforeAction: beforeAction)
	}
	
	func call<D>(
		_ endpoint: Endpoint<Nothing, D>,
		beforeAction: BeforeNetworkingAction? = nil,
	) async throws -> (D, HTTPURLResponse) {
		try await execute(try URLRequest(endpoint: endpoint), beforeAction: beforeAction)
	}

	func execute<D: Decodable>(
		_ request: URLRequest,
		beforeAction: BeforeNetworkingAction? = nil,
	) async throws -> (D, HTTPURLResponse) {
        logger.debug(">>> \(request.url!)")
        
		beforeAction?(request)
		let session = URLSession.shared
		let (data, response) = try await session.data(request: request)
        logger.debug("<<< \(request.url!) [\(response.statusCode)]")
        
		guard (200...299).contains(response.statusCode) else {
			logger.error("Received non-2xx status code: \(response.statusCode)")
			throw URLError(.badServerResponse)
		}
        
		do {
			return try (JSONDecoder().decode(D.self, from: data), response)
		} catch {
            if data.isEmpty { throw APIError.emptyResponse }
			throw loggedError(error)
		}
	}
}

public enum APIError: Error {
    case emptyResponse
}
