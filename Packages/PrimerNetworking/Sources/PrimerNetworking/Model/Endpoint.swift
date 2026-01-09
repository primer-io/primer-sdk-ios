//
//  Endpoint.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct Endpoint<E: Encodable, D: Decodable> {
	let baseURL: URL
	let path: String?
	let headers: HTTPHeaders?
	let timeout: TimeInterval?
	let method: HTTPMethod
    
    init(
        baseURL: URL,
        path: String? = nil,
        headers: HTTPHeaders? = nil,
        timeout: TimeInterval? = nil,
        method: HTTPMethod
    ) {
        self.baseURL = baseURL
        self.path = path
        self.headers = headers
        self.timeout = timeout
        self.method = method
    }

	public static func get(
		baseURL: URL,
		path: String? = nil,
		headers: HTTPHeaders? = nil,
		timeout: TimeInterval? = nil
	) -> Endpoint {
		Endpoint<E, D>(
			baseURL: baseURL,
			path: path,
			headers: headers,
			timeout: timeout,
			method: .get
		)
	}
	
	public static func post<T: Encodable>(
		baseURL: URL,
		path: String,
		body: T,
		headers: HTTPHeaders? = nil,
		timeout: TimeInterval? = nil
	) -> Endpoint {
		Endpoint<E, D>(
			baseURL: baseURL,
			path: path,
			headers: headers,
			timeout: timeout,
			method: .post(body)
		)
	}
	
	public static func put<T: Encodable>(
		baseURL: URL,
		path: String,
		body: T,
		headers: HTTPHeaders? = nil,
		timeout: TimeInterval? = nil
	) -> Endpoint {
		Endpoint<E, D>(
			baseURL: baseURL,
			path: path,
			headers: headers,
			timeout: timeout,
			method: .put(body)
		)
	}
	
	public static func delete(
		baseURL: URL,
		path: String,
		headers: HTTPHeaders? = nil,
		timeout: TimeInterval? = nil
	) -> Endpoint {
		Endpoint<E, D>(
			baseURL: baseURL,
			path: path,
			headers: headers,
			timeout: timeout,
			method: .delete
		)
	}
}

public extension Endpoint where E == Nothing {
	static func get(
		baseURL: URL,
		path: String? = nil,
		headers: HTTPHeaders? = nil,
		timeout: TimeInterval? = nil
	) -> Endpoint {
		Endpoint<Nothing, D>(
			baseURL: baseURL,
			path: path,
			headers: headers,
			timeout: timeout,
			method: .get
		)
	}
}
