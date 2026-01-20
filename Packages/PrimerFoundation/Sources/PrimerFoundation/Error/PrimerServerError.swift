//
//  PrimerServerError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct PrimerServerErrorResponse: Codable {
    public let error: PrimerServerError
}

public struct PrimerServerError: Codable {
    public var errorId: String
    public var `description`: String
    public var diagnosticsId: String
    var validationErrors: [String]?
}
