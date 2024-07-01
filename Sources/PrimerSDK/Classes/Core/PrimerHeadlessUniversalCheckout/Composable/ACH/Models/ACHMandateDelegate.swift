//
//  ACHMandateDelegate.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 14.05.2024.
//

import Foundation

/**
 * A protocol for handling the acceptance or decline of an ACH mandate.
 *
 * Specifies methods for handling actions when a user accepts or declines an ACH mandate.
 *
 * Methods:
 *  - `mandateAccepted()`: Called when the user accepts the mandate, enabling completion of transaction.
 *  - `mandateDeclined()`: Called when the user declines the mandate.
 */
public protocol ACHMandateDelegate {
    func mandateAccepted()
    func mandateDeclined()
}
