//
//  ClientSession+SDK.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerNetworking

extension ClientSession.Order {

    var currency: Currency? {
        guard let currencyCode else { return nil }
        let currencyLoader = CurrencyLoader(
            storage: DefaultCurrencyStorage(),
            networkService: CurrencyNetworkService()
        )
        return currencyLoader.getCurrency(currencyCode)
    }
}

extension ClientSession.Order.LineItem {

    func toOrderItem() throws -> ApplePayOrderItem {
        let applePayOptions = PrimerSettings.current.paymentMethodOptions.applePayOptions
        let name = (description ?? applePayOptions?.merchantName)
        return try ApplePayOrderItem(
            name: name ?? "Item",
            unitAmount: amount,
            quantity: quantity,
            discountAmount: discountAmount,
            taxAmount: taxAmount,
            isPending: false
        )
    }
}
