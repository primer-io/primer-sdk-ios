//
//  OrderItem.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

#if canImport(UIKit)

import Foundation
import PassKit

@available(*, deprecated, message: "Set the order items in the client session with POST /client-session. See documentation here: https://primer.io/docs/api#tag/Client-Session")
internal struct OrderItem: Codable {
    
    public let name: String
    public let unitAmount: Int?
    public let quantity: Int
    public var isPending: Bool = false
    
    public var applePayItem: PKPaymentSummaryItem {
        
        var applePayItemAmount: NSDecimalNumber!
        
        if AppState.current.currency?.isZeroDecimal == true {
            applePayItemAmount = NSDecimalNumber(value: (unitAmount ?? 0)*quantity)
        } else {
            applePayItemAmount = NSDecimalNumber(value: (unitAmount ?? 0)*quantity).dividing(by: 100)
        }
        
        let item = PKPaymentSummaryItem(label: name, amount: applePayItemAmount)
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
            let err = PrimerError.generic(message: "amount should be null for pending items", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if !isPending && unitAmount == nil {
            let err = PrimerError.generic(message: "amount cannot be null for non-pending items", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        self.name = name
        self.unitAmount = unitAmount
        self.quantity = quantity
        self.isPending = isPending
    }
    
}

#endif
