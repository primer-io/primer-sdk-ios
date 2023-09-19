//
//  PrimerServerErrorResponse.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

import Foundation

struct PrimerServerErrorResponse: Codable {
    var errorId: String
    var `description`: String
    var diagnosticsId: String
    var validationErrors: [String]?
}
