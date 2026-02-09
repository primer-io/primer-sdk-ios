//
//  HTTPURLResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  HTTPURLResponse.swift
//  PrimerNetworking
//
//  Created by Henry Cooper on 09/02/2026.
//
import Foundation

extension HTTPURLResponse: @retroactive ResponseMetadata {

    public var responseUrl: String? {
        url?.absoluteString
    }

    public var headers: [String: String]? {
        allHeaderFields.reduce(into: [:]) { result, item in
            if let key = item.key as? String, let value = item.value as? String {
                result[key] = value
            }
        }
    }
}
