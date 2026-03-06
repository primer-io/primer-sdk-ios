//
//  VaultedPaymentMethods.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

extension Response.Body {

    struct VaultedPaymentMethods: Codable {
        let data: [PrimerPaymentMethodTokenData]
    }
}
