//
//  KlarnaCollectableData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/**
 * Enumerates the types of data that can be collected during a Klarna payment session.
 * It conforms to `PrimerCollectableData` for integration with the Primer SDK data collection process and is `Encodable` to facilitate serialization.
 *
 * Cases:
 *  - `paymentCategory(_ category: KlarnaPaymentCategory, clientToken: String?)`: Represents the selection of a payment category along with an optional client token.
 *  - `finalizePayment`: Indicates that the payment session is in the final stage and finalization is required.
 */
public enum KlarnaCollectableData: PrimerCollectableData, Encodable {
    case paymentCategory(_ category: KlarnaPaymentCategory, clientToken: String?)
    case finalizePayment
}
