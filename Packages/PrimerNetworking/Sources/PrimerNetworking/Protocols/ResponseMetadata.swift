//
//  ResponseMetadata.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public protocol ResponseMetadata {
    var responseUrl: String? { get }
    var statusCode: Int { get }
    var headers: [String: String]? { get }
}

public extension ResponseMetadata {
    var description: String {
        "\(responseUrl ?? "Unknown URL") => \(statusCode)"
    }
}
