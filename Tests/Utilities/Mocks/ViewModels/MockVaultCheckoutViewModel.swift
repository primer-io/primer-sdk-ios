//
//  MockVaultCheckoutViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

class MockVaultCheckoutViewModel: UniversalCheckoutViewModelProtocol {

    var paymentMethods: [PrimerPaymentMethodTokenData] = []
    var selectedPaymentMethod: PrimerPaymentMethodTokenData?
    var amountStr: String? {
        return nil
    }
}
