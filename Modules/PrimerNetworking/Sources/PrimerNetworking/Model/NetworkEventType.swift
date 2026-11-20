//
//  NetworkEventType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal) public enum NetworkEventType {
    case requestStart(identifier: String, endpoint: Endpoint, request: URLRequest)
    case requestEnd(identifier: String, endpoint: Endpoint, response: ResponseMetadata, duration: TimeInterval)
    case networkConnectivity(endpoint: Endpoint)

    public var endpoint: Endpoint {
        switch self {
        case let .requestStart(_, endpoint, _),
             let .requestEnd(_, endpoint, _, _),
             let .networkConnectivity(endpoint):
            endpoint
        }
    }
}
