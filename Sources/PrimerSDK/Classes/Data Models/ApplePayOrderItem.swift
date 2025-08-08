//
//  ApplePayOrderItem.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit

internal struct ApplePayOrderItem: Codable, Equatable {

    public let name: String
    public let unitAmount: Int?
    public let quantity: Int
    public let discountAmount: Int?
    public let taxAmount: Int?
    public var isPending: Bool = false

    public var applePayItem: PKPaymentSummaryItem {

        var paymentSummaryItem: NSDecimalNumber!

        let tmpUnitAmount = unitAmount ?? 0
        let tmpQuantity = quantity
        let tmpAmount = tmpUnitAmount * tmpQuantity
        let tmpDiscountAmount = discountAmount ?? 0
        let tmpTaxAmount = taxAmount ?? 0
        let tmpTotalOrderItemAmount = tmpAmount - tmpDiscountAmount + tmpTaxAmount

        if AppState.current.currency?.isZeroDecimal == true {
            paymentSummaryItem = NSDecimalNumber(value: tmpTotalOrderItemAmount)
        } else {
            paymentSummaryItem = NSDecimalNumber(value: tmpTotalOrderItemAmount).dividing(by: 100)
        }

        let item = PKPaymentSummaryItem(label: name, amount: paymentSummaryItem)
        item.type = isPending ? .pending : .final
        return item
    }

    public init(
        name: String,
        unitAmount: Int?,
        quantity: Int,
        discountAmount: Int?,
        taxAmount: Int?,
        isPending: Bool = false
    ) throws {
        if isPending && unitAmount != nil {
            throw handled(
                primerError: .invalidValue(
                    key: "amount",
                    value: unitAmount,
                    reason: "amount should be null for pending items"
                )
            )
        }

        if !isPending && unitAmount == nil {
            throw handled(
                primerError: .invalidValue(
                    key: "amount",
                    value: unitAmount,
                    reason: "amount cannot be null for non-pending items"
                )
            )
        }

        self.name = name
        self.unitAmount = unitAmount
        self.quantity = quantity
        self.isPending = isPending
        self.discountAmount = discountAmount
        self.taxAmount = taxAmount
    }

}
