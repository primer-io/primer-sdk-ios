//
//  PrimerServerError.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct PrimerServerErrorResponse: Codable {
    let error: PrimerServerError
}

struct PrimerServerError: Codable {
    var errorId: String
    var `description`: String
    var diagnosticsId: String
    var validationErrors: [String]?
}
