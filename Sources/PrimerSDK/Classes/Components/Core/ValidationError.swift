//
//  ValidationError.swift
//
//
//  Created by Boris on 24.3.25..
//

import Foundation

/**
 * A data class representing a validation error encountered during the payment method data validation process.
 *
 * @property code A unique identifier for the error.
 * @property message A descriptive message explaining the error.
 */
struct ValidationError: Equatable, Hashable, Codable {
    let code: String
    let message: String
}
