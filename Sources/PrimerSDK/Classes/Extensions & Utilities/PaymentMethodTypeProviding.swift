//
//  PaymentMethodTypeProviding.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// swiftlint:disable type_name
protocol PaymentMethodTypeViaPaymentMethodTokenDataProviding {
    // swiftlint:enable type_name
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get }
    var paymentMethodType: String { get }
}

extension PaymentMethodTypeViaPaymentMethodTokenDataProviding {
    var paymentMethodType: String {
        if let pmt = paymentMethodTokenData?.paymentMethodType {
            return pmt
        } else if let pmt = paymentMethodTokenData?.paymentInstrumentData?.paymentMethodType {
            return pmt
        }
        return "UNKNOWN"
    }
}
