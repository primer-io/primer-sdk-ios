//
//  ACHMandateDelegate.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/**
 * A protocol for handling the acceptance or decline of an ACH mandate.
 *
 * Specifies methods for handling actions when a user accepts or declines an ACH mandate.
 *
 * Methods:
 *  - `acceptMandate()`: Called when the user accepts the mandate, enabling completion of transaction.
 *  - `declineMandate()`: Called when the user declines the mandate.
 */
public protocol ACHMandateDelegate: AnyObject {
    func acceptMandate()
    func declineMandate()
}
