//
//  API.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import OSLog

public final class API: NetworkingClient {
	
    let logger = Logger()
		
	public init() {}
	
	public func call<E: Encodable, D: Decodable>(_ endpoint: Endpoint<E, D>) async throws -> D {
		try await execute(try URLRequest(endpoint: endpoint))
	}
	
	public func call<D: Decodable>(_ endpoint: Endpoint<Nothing, D>) async throws -> D {
		try await execute(try URLRequest(endpoint: endpoint))
	}
	
	@discardableResult
	public func call(_ endpoint: Endpoint<Nothing, Nothing>) async throws -> Nothing {
		try await execute(try URLRequest(endpoint: endpoint))
	}
	
	private func execute<D: Decodable>(_ request: URLRequest) async throws -> D {
		try await execute(request).0
	}
	
	func logResponse(_ response: HTTPURLResponse) {
		guard #available(iOS 14, *) else { return print(response) }
		logger.debug("[API] -> \(response.statusCode)")
	}
	
	func loggedError(_ error: Error) -> Error {
		logger.debug(String(describing: error))
		return error
	}
}

final class Logger: Sendable {
	func debug(_ message: String) {
		guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "Networking")
		logger.error("\(message)")
	}
	
	func error(_ message: String) {
		guard #available(iOS 14, *) else { return print(message) }
        let logger = os.Logger(subsystem: "PrimerBDC", category: "Networking")
		logger.error("\(message)")
	}
}
