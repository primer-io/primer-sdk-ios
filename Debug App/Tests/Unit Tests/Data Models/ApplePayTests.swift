//
//  ApplePayTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 8/5/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//


import PassKit
import XCTest
@testable import PrimerSDK

class ApplePayTests: XCTestCase {
    
    func test_apple_pay_order_items_with_line_items() throws {
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant-identifier",
                    merchantName: "Merchant Name")))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let applePayTokenizationViewModel = ApplePayTokenizationViewModel(
            config: PrimerPaymentMethod(
                id: "apple-pay-id",
                implementationType: .nativeSdk,
                type: "APPLE_PAY",
                name: "Apple Pay",
                processorConfigId: "processor-config-id",
                surcharge: nil,
                options: nil,
                displayMetadata: nil))
        
        do {
            var clientSession = ClientSession.APIResponse(
                clientSessionId: nil,
                paymentMethod: nil,
                order: ClientSession.Order(
                    id: "order-id",
                    merchantAmount: nil,
                    totalOrderAmount: 1000,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: .GBP,
                    fees: nil,
                    lineItems: [
                        ClientSession.Order.LineItem(
                            itemId: "item-id-1",
                            quantity: 1,
                            amount: 1000,
                            discountAmount: nil,
                            name: "name 1",
                            description: "description 1",
                            taxAmount: nil,
                            taxCode: nil),
                    ],
                    shippingAmount: nil),
                customer: nil,
                testId: nil)
            
            var orderItems = try applePayTokenizationViewModel.createOrderItemsFromClientSession(clientSession)
            XCTAssert(orderItems.count == (clientSession.order?.lineItems?.count ?? 0) + 1, "Apple Pay order items should be \((clientSession.order?.lineItems?.count ?? 0) + 1)")
            
            XCTAssert(orderItems[0].quantity == clientSession.order?.lineItems?[0].quantity, "Order item's quantity should be \(String(describing: clientSession.order?.lineItems?[0].quantity)), but it's \(orderItems[0].quantity)")
            XCTAssert(orderItems[0].unitAmount == clientSession.order?.lineItems?[0].amount, "Order item's unitAmount should be \(String(describing: clientSession.order?.lineItems?[0].amount)), but it's \(String(describing: orderItems[0].unitAmount))")
            XCTAssert(orderItems[0].name == clientSession.order?.lineItems?[0].description, "Order item's name should be \(String(describing: clientSession.order?.lineItems?[0].description)), but it's \(orderItems[0].name)")
            
            XCTAssert(orderItems.last!.quantity == 1)
            XCTAssert(orderItems.last!.unitAmount == clientSession.order?.totalOrderAmount)
            XCTAssert(orderItems.last!.name == settings.paymentMethodOptions.applePayOptions?.merchantName)
            
            clientSession = ClientSession.APIResponse(
                clientSessionId: nil,
                paymentMethod: nil,
                order: ClientSession.Order(
                    id: "order-id",
                    merchantAmount: nil,
                    totalOrderAmount: 5000,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: .GBP,
                    fees: nil,
                    lineItems: [
                        ClientSession.Order.LineItem(
                            itemId: "item-id-1",
                            quantity: 1,
                            amount: 1000,
                            discountAmount: nil,
                            name: "name 1",
                            description: "description 1",
                            taxAmount: nil,
                            taxCode: nil),
                        ClientSession.Order.LineItem(
                            itemId: "item-id-2",
                            quantity: 2,
                            amount: 2000,
                            discountAmount: nil,
                            name: "name 2",
                            description: "description 2",
                            taxAmount: nil,
                            taxCode: nil)
                    ],
                    shippingAmount: nil),
                customer: nil,
                testId: nil)
            
            orderItems = try applePayTokenizationViewModel.createOrderItemsFromClientSession(clientSession)
            XCTAssert(orderItems.count == (clientSession.order?.lineItems?.count ?? 0) + 1, "Apple Pay order items should be \((clientSession.order?.lineItems?.count ?? 0) + 1)")
            
            XCTAssert(orderItems[0].quantity == clientSession.order?.lineItems?[0].quantity, "Order item's quantity should be \(String(describing: clientSession.order?.lineItems?[0].quantity)), but it's \(orderItems[0].quantity)")
            XCTAssert(orderItems[0].unitAmount == clientSession.order?.lineItems?[0].amount, "Order item's unitAmount should be \(String(describing: clientSession.order?.lineItems?[0].amount)), but it's \(String(describing: orderItems[0].unitAmount))")
            XCTAssert(orderItems[0].name == clientSession.order?.lineItems?[0].description, "Order item's name should be \(String(describing: clientSession.order?.lineItems?[0].description)), but it's \(orderItems[0].name)")
            
            XCTAssert(orderItems[1].quantity == clientSession.order?.lineItems?[1].quantity, "Order item's quantity should be \(String(describing: clientSession.order?.lineItems?[1].quantity)), but it's \(orderItems[1].quantity)")
            XCTAssert(orderItems[1].unitAmount == clientSession.order?.lineItems?[1].amount, "Order item's unitAmount should be \(String(describing: clientSession.order?.lineItems?[1].amount)), but it's \(String(describing: orderItems[1].unitAmount))")
            XCTAssert(orderItems[1].name == clientSession.order?.lineItems?[1].description, "Order item's name should be \(String(describing: clientSession.order?.lineItems?[1].description)), but it's \(orderItems[1].name)")
            
            XCTAssert(orderItems.last!.quantity == 1)
            XCTAssert(orderItems.last!.unitAmount == clientSession.order?.totalOrderAmount)
            XCTAssert(orderItems.last!.name == settings.paymentMethodOptions.applePayOptions?.merchantName)
            
        } catch {
            XCTAssert(false, "Failed with error \(error.localizedDescription)")
        }
    }
    
    func test_apple_pay_order_items_with_hardcoded_merchant_amount() throws {
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant-identifier",
                    merchantName: "Merchant Name")))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let applePayTokenizationViewModel = ApplePayTokenizationViewModel(
            config: PrimerPaymentMethod(
                id: "apple-pay-id",
                implementationType: .nativeSdk,
                type: "APPLE_PAY",
                name: "Apple Pay",
                processorConfigId: "processor-config-id",
                surcharge: nil,
                options: nil,
                displayMetadata: nil))
        
        do {
            var clientSession = ClientSession.APIResponse(
                clientSessionId: nil,
                paymentMethod: nil,
                order: ClientSession.Order(
                    id: "order-id",
                    merchantAmount: 1000,
                    totalOrderAmount: 2000,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: .GBP,
                    fees: nil,
                    lineItems: nil,
                    shippingAmount: nil),
                customer: nil,
                testId: nil)
            
            var orderItems = try applePayTokenizationViewModel.createOrderItemsFromClientSession(clientSession)
            XCTAssert(orderItems.count == (clientSession.order?.lineItems?.count ?? 0) + 1, "Apple Pay order items should be \((clientSession.order?.lineItems?.count ?? 0) + 1)")
            
            XCTAssert(orderItems[0].quantity == 1, "Order item's quantity should be 1, the summary item")
            XCTAssert(orderItems[0].unitAmount == clientSession.order?.merchantAmount, "Order item's unitAmount should be \(String(describing: clientSession.order?.merchantAmount)), but it's \(String(describing: orderItems[0].unitAmount))")
            XCTAssert(orderItems[0].name == settings.paymentMethodOptions.applePayOptions?.merchantName, "Order item's name should be \(String(describing: settings.paymentMethodOptions.applePayOptions?.merchantName)), but it's \(orderItems[0].name)")
            
            XCTAssert(orderItems.last!.quantity == 1)
            XCTAssert(orderItems.last!.unitAmount == clientSession.order?.merchantAmount)
            XCTAssert(orderItems.last!.name == settings.paymentMethodOptions.applePayOptions?.merchantName)
            
            clientSession = ClientSession.APIResponse(
                clientSessionId: nil,
                paymentMethod: nil,
                order: ClientSession.Order(
                    id: "order-id",
                    merchantAmount: 1000,
                    totalOrderAmount: 2000,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: .GBP,
                    fees: [
                        ClientSession.Order.Fee(
                            type: .surcharge,
                            amount: 19),
                    ],
                    lineItems: nil,
                    shippingAmount: nil),
                customer: nil,
                testId: nil)
            
            orderItems = try applePayTokenizationViewModel.createOrderItemsFromClientSession(clientSession)
            XCTAssert(orderItems.count == 1, "Apple Pay order items should be 1, the summary order item")
            
            XCTAssert(orderItems[0].quantity == 1, "Order item's quantity should be 1, as there're no line items")
            XCTAssert(orderItems[0].unitAmount == clientSession.order?.merchantAmount, "Order item's unitAmount should be \(String(describing: clientSession.order?.merchantAmount)), but it's \(String(describing: orderItems[0].unitAmount))")
            XCTAssert(orderItems[0].name == settings.paymentMethodOptions.applePayOptions?.merchantName, "Order item's name should be \(String(describing: settings.paymentMethodOptions.applePayOptions?.merchantName)), but it's \(orderItems[0].name)")
            
            XCTAssert(orderItems.last!.quantity == 1)
            XCTAssert(orderItems.last!.unitAmount == clientSession.order?.merchantAmount ?? 0)
            XCTAssert(orderItems.last!.name == settings.paymentMethodOptions.applePayOptions?.merchantName)
            
            
        } catch {
            XCTAssert(false, "Failed with error \(error.localizedDescription)")
        }
    }
    
    func test_apple_pay_items_mapping() throws {
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant-identifier",
                    merchantName: "Merchant Name")))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let applePayTokenizationViewModel = ApplePayTokenizationViewModel(
            config: PrimerPaymentMethod(
                id: "apple-pay-id",
                implementationType: .nativeSdk,
                type: "APPLE_PAY",
                name: "Apple Pay",
                processorConfigId: "processor-config-id",
                surcharge: nil,
                options: nil,
                displayMetadata: nil))
        
        do {
            let clientSession = ClientSession.APIResponse(
                clientSessionId: nil,
                paymentMethod: nil,
                order: ClientSession.Order(
                    id: "order-id",
                    merchantAmount: nil,
                    totalOrderAmount: 30202,
                    totalTaxAmount: nil,
                    countryCode: .gb,
                    currencyCode: .GBP,
                    fees: nil,
                    lineItems: [
                        ClientSession.Order.LineItem(
                            itemId: "item-id-1",
                            quantity: 1,
                            amount: 1000,
                            discountAmount: 101,
                            name: "name 1",
                            description: "description 1",
                            taxAmount: nil,
                            taxCode: nil),
                        ClientSession.Order.LineItem(
                            itemId: "item-id-2",
                            quantity: 2,
                            amount: 2000,
                            discountAmount: nil,
                            name: "name 2",
                            description: "description 2",
                            taxAmount: 202,
                            taxCode: nil),
                        ClientSession.Order.LineItem(
                            itemId: "item-id-3",
                            quantity: 3,
                            amount: 3000,
                            discountAmount: 101,
                            name: "name 3",
                            description: "description 3",
                            taxAmount: 202,
                            taxCode: nil),
                        ClientSession.Order.LineItem(
                            itemId: "item-id-4",
                            quantity: 4,
                            amount: 4000,
                            discountAmount: nil,
                            name: "name 4",
                            description: "description 4",
                            taxAmount: nil,
                            taxCode: nil),
                    ],
                    shippingAmount: nil),
                customer: nil,
                testId: nil)
            
            let mockAppState = MockAppState(
                clientToken: MockAppState.mockClientToken,
                apiConfiguration: PrimerAPIConfiguration(
                    coreUrl: "https://core.url",
                    pciUrl: "https://pci.url",
                    clientSession: clientSession,
                    paymentMethods: nil,
                    primerAccountId: nil,
                    keys: nil,
                    checkoutModules: nil))
            
            DependencyContainer.register(mockAppState as AppStateProtocol)
            
            let orderItems = try applePayTokenizationViewModel.createOrderItemsFromClientSession(clientSession)
            let applePayItems: [PKPaymentSummaryItem] = orderItems.compactMap({ $0.applePayItem })
            XCTAssert(applePayItems.count == (clientSession.order?.lineItems?.count ?? 0) + 1, "Apple Pay items should be \((clientSession.order?.lineItems?.count ?? 0) + 1)")
            
            XCTAssert(applePayItems[0].amount.doubleValue == NSDecimalNumber(floatLiteral:   8.99).doubleValue)
            XCTAssert(applePayItems[0].label == clientSession.order?.lineItems?[0].description)
            
            XCTAssert(applePayItems[1].amount.doubleValue == NSDecimalNumber(floatLiteral:  42.02).doubleValue)
            XCTAssert(applePayItems[1].label == clientSession.order?.lineItems?[1].description)
            
            XCTAssert(applePayItems[2].amount.doubleValue == NSDecimalNumber(floatLiteral:  91.01).doubleValue)
            XCTAssert(applePayItems[2].label == clientSession.order?.lineItems?[2].description)
            
            XCTAssert(applePayItems[3].amount.doubleValue == NSDecimalNumber(floatLiteral: 160.00).doubleValue)
            XCTAssert(applePayItems[3].label == clientSession.order?.lineItems?[3].description)
            
            XCTAssert(applePayItems.last!.amount.doubleValue == NSDecimalNumber(floatLiteral: 302.02).doubleValue)
            XCTAssert(applePayItems.last!.label == settings.paymentMethodOptions.applePayOptions?.merchantName)
            
        } catch {
            XCTAssert(false, "Failed with error \(error.localizedDescription)")
        }
    }
}
