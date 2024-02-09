//
//  PaymentMethodTypeProviding.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 06/12/23.
//

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
