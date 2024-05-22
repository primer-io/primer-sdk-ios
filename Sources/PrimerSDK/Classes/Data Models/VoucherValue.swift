//
//  PrimerAccountInfoPaymentViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation

struct VoucherValue {
    let id: String
    let description: String
    let value: String?
}

extension VoucherValue: Equatable {

    static func == (lhs: VoucherValue, rhs: VoucherValue) -> Bool {
        return lhs.id == rhs.id
    }
}

extension VoucherValue {

    fileprivate static var defaultVoucherValues: [VoucherValue] {
        [
            VoucherValue(id: "entity",
                         description: Strings.VoucherInfoPaymentView.entityLabelText,
                         value: PrimerAPIConfigurationModule.decodedJWTToken?.entity),
            VoucherValue(id: "reference",
                         description: Strings.VoucherInfoPaymentView.referenceLabelText,
                         value: PrimerAPIConfigurationModule.decodedJWTToken?.reference)
        ]
    }

    static var currentVoucherValues: [VoucherValue] {

        var currentVoucherValues = defaultVoucherValues
        if let currency = AppState.current.currency, let amount = AppState.current.amount {
            currentVoucherValues.append(VoucherValue(id: "amount",
                                                     description: Strings.VoucherInfoPaymentView.amountLabelText,
                                                     value: "\(amount.toCurrencyString(currency: currency))"))
        }

        return currentVoucherValues
    }
}

extension VoucherValue {

    static var sharableVoucherValuesText: String? {

        /// Expecred output string
        ///
        /// Entity: 123123123
        /// Reference: 123 123 123
        /// Expires at: 12 Dec 2022 12:00 PM (Date in the user format)
        ///

        var sharableVoucherValues = defaultVoucherValues

        if let expirationDate = PrimerAPIConfigurationModule.decodedJWTToken?.expiresAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            sharableVoucherValues.append(VoucherValue(id: "expirationDate",
                                                      description: Strings.VoucherInfoPaymentView.expiresAt,
                                                      value: formatter.string(from: expirationDate)))
        }

        let description = sharableVoucherValues.compactMap { voucherValue in
            if let unwrappedVoucherValue = voucherValue.value {
                return "\(voucherValue.description): \(unwrappedVoucherValue)"
            }
            return nil
        }.joined(separator: "\n")

        return description.isEmpty ? nil : description
    }
}
