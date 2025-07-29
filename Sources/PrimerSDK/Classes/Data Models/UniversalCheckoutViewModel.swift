//
//  UniversalCheckoutViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal protocol UniversalCheckoutViewModelProtocol {
    var paymentMethods: [PrimerPaymentMethodTokenData] { get }
    var selectedPaymentMethod: PrimerPaymentMethodTokenData? { get }
    var amountStr: String? { get }
}

final class UniversalCheckoutViewModel: UniversalCheckoutViewModelProtocol, LogReporter {

    var amountStr: String? {
        if (PrimerInternal.shared.intent ?? .vault) == .vault { return nil }
        guard let amount = AppState.current.amount else { return nil }
        guard let currency = AppState.current.currency else { return nil }
        return amount.toCurrencyString(currency: currency)
    }

    var paymentMethods: [PrimerPaymentMethodTokenData] {
        return AppState.current.paymentMethods
    }

    var selectedPaymentMethod: PrimerPaymentMethodTokenData? {
        return AppState.current.selectedPaymentMethod
    }
}
