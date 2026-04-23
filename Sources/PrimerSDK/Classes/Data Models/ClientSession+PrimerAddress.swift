//
//  ClientSession+PrimerAddress.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension ClientSession.Address {
    init(from primerAddress: PrimerAddress) {
        self.init(
            firstName: primerAddress.firstName,
            lastName: primerAddress.lastName,
            addressLine1: primerAddress.addressLine1,
            addressLine2: primerAddress.addressLine2,
            city: primerAddress.city,
            postalCode: primerAddress.postalCode,
            state: primerAddress.state,
            countryCode: primerAddress.countryCode.flatMap { CountryCode(rawValue: $0) }
        )
    }
}
