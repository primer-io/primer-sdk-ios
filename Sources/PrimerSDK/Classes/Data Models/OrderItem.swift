//
//  OrderItem.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

import Foundation
import PassKit

internal struct OrderItem: Codable {

    public let name: String
    public let unitAmount: Int?
    public let quantity: Int
    public let discountAmount: Int?
    public let taxAmount: Int?
    public var isPending: Bool = false

    public var applePayItem: PKPaymentSummaryItem {

        var applePayItemAmount: NSDecimalNumber!

        let tmpUnitAmount = unitAmount ?? 0
        let tmpQuantity = quantity
        let tmpAmount = tmpUnitAmount * tmpQuantity
        let tmpDiscountAmount = discountAmount ?? 0
        let tmpTaxAmount = taxAmount ?? 0
        let tmpTotalOrderItemAmount = tmpAmount - tmpDiscountAmount + tmpTaxAmount

        if AppState.current.currency?.isZeroDecimal == true {
            applePayItemAmount = NSDecimalNumber(value: tmpTotalOrderItemAmount)
        } else {
            applePayItemAmount = NSDecimalNumber(value: tmpTotalOrderItemAmount).dividing(by: 100)
        }

        let item = PKPaymentSummaryItem(label: name, amount: applePayItemAmount)
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
            let err = PrimerError.generic(message: "amount should be null for pending items",
                                          userInfo: .errorUserInfoDictionary(),
                                          diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        if !isPending && unitAmount == nil {
            let err = PrimerError.generic(message: "amount cannot be null for non-pending items",
                                          userInfo: .errorUserInfoDictionary(),
                                          diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        self.name = name
        self.unitAmount = unitAmount
        self.quantity = quantity
        self.isPending = isPending
        self.discountAmount = discountAmount
        self.taxAmount = taxAmount
    }

}
