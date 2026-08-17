//
//  BDCHTTPRequestEndpoint.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

struct BDCHTTPRequestEndpoint: Endpoint {
    
    let method: HTTPMethod
    let body: Data?
    let timeout: TimeInterval?

    private let url: String
    private let schemaHeaders: [String: String]?
    
    var baseURL: String? { url }
    var path: String { "" }
    var queryParameters: [String: String]? { nil }
    
    var headers: [String: String]? {
        var merged = PrimerRuntimeHeaders.default
        schemaHeaders?.forEach { merged[$0.key] = $0.value }
        return merged
    }

    init(
        url: String,
        method: HTTPMethod,
        schemaHeaders: [String: String]?,
        body: Data?,
        timeout: TimeInterval?
    ) {
        self.url = url
        self.method = method
        self.schemaHeaders = schemaHeaders
        self.body = body
        self.timeout = timeout
    }
}
