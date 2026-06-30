//
//  ExecutionResult.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct ExecutionResult {
    let stepID: String
    let statusCode: Int
    let response: Data
    let headers: [String: String]
}
