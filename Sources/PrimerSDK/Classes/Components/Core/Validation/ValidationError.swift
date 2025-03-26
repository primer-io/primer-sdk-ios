//
//  representing.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/**
 * A data class representing a validation error encountered during the payment method data validation process.
 *
 * @property code A unique identifier for the error.
 * @property message A descriptive message explaining the error.
 */
public struct ValidationError: Equatable, Hashable, Codable {
    let code: String
    let message: String
}
