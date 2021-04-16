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
    public let unitAmount: Int
    public let quantity: Int
    
    public var applePayItem: PKPaymentSummaryItem {
        return PKPaymentSummaryItem(label: name, amount: NSDecimalNumber(value: Double(unitAmount)/100))
    }

    public init(
        name: String,
        unitAmount: Int,
        quantity: Int
    ) {
        self.name = name
        self.unitAmount = unitAmount
        self.quantity = quantity
    }
}
