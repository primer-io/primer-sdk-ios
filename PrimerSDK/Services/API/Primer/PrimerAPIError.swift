//
//  PrimerAPIError.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

//struct PrimerAPIError {
//    var errorId: String
//    var `description`: String
//    var diagnosticsId: String
//    var validationErrors: [String]?
//}

enum PrimerAPIError: String, LocalizedError {
    case userEmailAlreadyExists = "UserEmailAlreadyExists"
    case ClientTokenNull = "Client token is missing."
    case CustomerIDNull = "Customer ID is missing."
    case PayPalSessionFailed = "PayPal checkout session failed. Your account has not been charged."
    case VaultFetchFailed = "Failed to fetch saved payment methods."
    case VaultDeleteFailed = "Failed to delete saved payment method."
    case VaultCreateFailed = "Failed to save payment method."
    case DirectDebitSessionFailed = "Failed to create a direct debit mandate.\n\n Please try again."
    case ConfigFetchFailed = "Failed to setup session."
    case TokenizationPreRequestFailed = "Failed to complete action. Your payment method was not processed."
    case TokenizationRequestFailed = "Connection error, your payment method was not saved. Please try again."
}
