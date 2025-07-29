//
//  PrimerVaultedCardAdditionalData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class PrimerVaultedCardAdditionalData: PrimerVaultedPaymentMethodAdditionalData {

    let cvv: String

    public init(cvv: String) {
        self.cvv = cvv
    }
}
