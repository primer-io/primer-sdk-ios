//
//  OrderItem.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

import Foundation
import PassKit

public struct OrderItem: Codable {
    public let name: String
    public let unitAmount: Int?
    public let quantity: Int
    public var isPending: Bool = false
    
    public var applePayItem: PKPaymentSummaryItem {
        let item = PKPaymentSummaryItem(label: name, amount: NSDecimalNumber(value: Double(unitAmount ?? 0)/100))
        item.type = isPending ? .pending : .final
        return item
    }

    public init(
        name: String,
        unitAmount: Int?,
        quantity: Int,
        isPending: Bool = false
    ) throws {
        if isPending && unitAmount != nil {
            throw PrimerError.amountShouldBeNullForPendingOrderItems
        }
        
        if !isPending && unitAmount == nil {
            throw PrimerError.amountCannotBeNullForNonPendingOrderItems
        }
        
        self.name = name
        self.unitAmount = unitAmount
        self.quantity = quantity
        self.isPending = isPending
    }
    
}
