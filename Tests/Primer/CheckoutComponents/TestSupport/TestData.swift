//
//  TestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum TestData {
    // All test data is organized in domain-specific extension files:
    // - TestData+Cards.swift: Card numbers, expiry dates, CVV, cardholder names, networks
    // - TestData+Address.swift: Billing addresses, postal codes, country codes, cities, states
    // - TestData+Contact.swift: First names, last names, email addresses, phone numbers
    // - TestData+Payments.swift: Amounts, currencies, payment results, 3DS flows
    // - TestData+Network.swift: Tokens, API responses, network responses, errors
}
