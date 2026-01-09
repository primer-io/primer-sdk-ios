//
//  NetworkingClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public typealias BeforeNetworkingAction = ((URLRequest) -> Void)
public typealias CompatabilityResponse<T> = (T, HTTPURLResponse)

public protocol NetworkingClient: Sendable {
	func call<E: Encodable, D: Decodable>(_ endpoint: Endpoint<E, D>) async throws -> D
	func call<D: Decodable>(_ endpoint: Endpoint<Nothing, D>) async throws -> D
	@discardableResult func call(_ endpoint: Endpoint<Nothing, Nothing>) async throws -> Nothing
	
	// Basic compatibility with PrimerSDK
	func call<E: Encodable, D: Decodable>(
		_ endpoint: Endpoint<E, D>,
		beforeAction: BeforeNetworkingAction?
	) async throws -> CompatabilityResponse<D>
	
}
