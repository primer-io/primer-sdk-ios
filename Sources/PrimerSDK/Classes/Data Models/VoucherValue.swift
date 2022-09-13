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

extension VoucherValue: Comparable {
    
    static func < (lhs: VoucherValue, rhs: VoucherValue) -> Bool {
        return lhs.id == rhs.id
    }
}

extension VoucherValue {
    
    static var currentVoucherValues: [VoucherValue] {
        
        var currentVaucherValues = [
            VoucherValue(id: "entity", description: Strings.VoucherInfoPaymentView.entityLabelText, value: ClientTokenService.decodedClientToken?.entity),
            VoucherValue(id: "reference", description: Strings.VoucherInfoPaymentView.referenceLabelText, value: ClientTokenService.decodedClientToken?.reference)
        ]
        
        if let currency = AppState.current.currency, let amount = AppState.current.amount {
            currentVaucherValues.append(VoucherValue(id: "amount", description: Strings.VoucherInfoPaymentView.amountLabelText, value: "\(amount.toCurrencyString(currency: currency))"))
        }
        
        return currentVaucherValues
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
        
        var voucherSharableValues = ""
        
        var sharableVoucherValues = [
            VoucherValue(id: "entity", description: Strings.VoucherInfoPaymentView.entityLabelText, value: ClientTokenService.decodedClientToken?.entity),
            VoucherValue(id: "reference", description: Strings.VoucherInfoPaymentView.referenceLabelText, value: ClientTokenService.decodedClientToken?.reference)
        ]
        
        if let expirationDate = ClientTokenService.decodedClientToken?.expiresAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            sharableVoucherValues.append(VoucherValue(id: "expirationDate", description: Strings.VoucherInfoPaymentView.expiresAt, value: formatter.string(from: expirationDate)))
        }

        for voucherValue in sharableVoucherValues {
            
            if let unwrappedVoucherValue = voucherValue.value {
                voucherSharableValues += "\(voucherValue.description): \(unwrappedVoucherValue)"
            }
            
            
            if let lastValue = VoucherValue.currentVoucherValues.last, voucherValue != lastValue  {
                voucherSharableValues += "\n"
            }
        }
        
        return voucherSharableValues.isEmpty ? nil : voucherSharableValues
    }
}
