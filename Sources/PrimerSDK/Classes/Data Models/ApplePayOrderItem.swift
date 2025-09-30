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
		let tmpUnitAmount = unitAmount ?? 0
		let tmpQuantity = quantity
		let tmpAmount = tmpUnitAmount * tmpQuantity
		let tmpDiscountAmount = discountAmount ?? 0
		let tmpTaxAmount = taxAmount ?? 0
		let tmpTotalOrderItemAmount = tmpAmount - tmpDiscountAmount + tmpTaxAmount

		let decimalDigits = AppState.current.currency?.decimalDigits ?? 2
		let factor = pow(10.0, Double(decimalDigits))
		let amountDecimal = (Decimal(tmpTotalOrderItemAmount) / Decimal(factor)) as NSDecimalNumber

		return PKPaymentSummaryItem(label: name, amount: amountDecimal, type: isPending ? .pending : .final)
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
