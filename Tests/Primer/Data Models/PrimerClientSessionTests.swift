//
//  PrimerClientSessionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation

/// Covers the wire-to-merchant mapping in `PrimerClientSession.init(from:)`, the read model
/// CheckoutComponents delivers on `.ready` and Drop-In / Headless deliver via
/// `primerClientSessionDidUpdate(_:)`.
final class PrimerClientSessionTests: XCTestCase {

    private func makeConfiguration(
        orderedAllowedCardNetworks: [String]? = nil,
        fees: [ClientSession.Order.Fee]? = nil,
        totalOrderAmount: Int? = 1000,
        currencyCode: String? = "GBP",
        lineItems: [ClientSession.Order.LineItem]? = nil,
        totalTaxAmount: Int? = nil,
        customer: ClientSession.Customer? = nil
    ) -> PrimerAPIConfiguration {
        let session = ClientSession.APIResponse(
            clientSessionId: "client_session_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: orderedAllowedCardNetworks,
                descriptor: nil
            ),
            order: ClientSession.Order(
                id: "order_id",
                merchantAmount: nil,
                totalOrderAmount: totalOrderAmount,
                totalTaxAmount: totalTaxAmount,
                countryCode: .gb,
                currencyCode: currencyCode.flatMap { CurrencyLoader().getCurrency($0) },
                fees: fees,
                lineItems: lineItems
            ),
            customer: customer,
            testId: nil
        )
        return PrimerAPIConfiguration(
            coreUrl: "core_url",
            pciUrl: "pci_url",
            binDataUrl: "bin_data_url",
            assetsUrl: "assets_url",
            clientSession: session,
            paymentMethods: nil,
            primerAccountId: "account_id",
            keys: nil,
            checkoutModules: nil
        )
    }

    // MARK: - Allowed card networks

    func test_init_from_mapsAllowedCardNetworksInConfiguredOrder() {
        // Given
        let configuration = makeConfiguration(orderedAllowedCardNetworks: ["MASTERCARD", "VISA"])

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then — order is the merchant's, not the enum's declaration order
        XCTAssertEqual(sut.paymentMethod?.orderedAllowedCardNetworks, [.masterCard, .visa])
    }

    // A network the SDK has no case for must survive as `.unknown` rather than vanish from the list,
    // matching Android's `CardNetwork.Type.OTHER` fallback.
    func test_init_from_mapsUnrecognisedCardNetworkToUnknown() {
        // Given
        let configuration = makeConfiguration(orderedAllowedCardNetworks: ["VISA", "SOME_FUTURE_NETWORK"])

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then
        XCTAssertEqual(sut.paymentMethod?.orderedAllowedCardNetworks, [.visa, .unknown])
    }

    func test_init_from_mapsMissingCardNetworksToEmptyList() {
        // Given
        let configuration = makeConfiguration(orderedAllowedCardNetworks: nil)

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then — the payment method itself is present, its network list is merely empty
        XCTAssertNotNil(sut.paymentMethod)
        XCTAssertEqual(sut.paymentMethod?.orderedAllowedCardNetworks, [])
    }

    // MARK: - Fees

    func test_init_from_mapsFees() {
        // Given
        let configuration = makeConfiguration(fees: [ClientSession.Order.Fee(type: .surcharge, amount: 99)])

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then
        XCTAssertEqual(sut.fees?.count, 1)
        XCTAssertEqual(sut.fees?.first?.type, "SURCHARGE")
        XCTAssertEqual(sut.fees?.first?.amount, 99)
    }

    func test_init_from_mapsMissingFeesToNil() {
        XCTAssertNil(PrimerClientSession(from: makeConfiguration(fees: nil)).fees)
    }

    // MARK: - Line item tax

    private func makeLineItem(
        itemId: String,
        amount: Int,
        taxAmount: Int?,
        taxCode: String?
    ) -> ClientSession.Order.LineItem {
        ClientSession.Order.LineItem(
            itemId: itemId,
            quantity: 1,
            amount: amount,
            discountAmount: nil,
            name: itemId,
            description: itemId,
            taxAmount: taxAmount,
            taxCode: taxCode,
            productType: nil
        )
    }

    // Regression: the mapper used to fill every line item's `taxAmount` with the order's
    // `totalTaxAmount` and its `taxCode` with the customer's `taxId`, so a three-item order reported
    // the whole order's tax three times and a tax code that was really a customer registration ID.
    func test_init_from_mapsLineItemTaxFromTheLineItemNotTheOrderOrCustomer() {
        // Given — per-item tax that differs from both decoys
        let configuration = makeConfiguration(
            lineItems: [
                makeLineItem(itemId: "item_1", amount: 600, taxAmount: 60, taxCode: "VAT_20"),
                makeLineItem(itemId: "item_2", amount: 400, taxAmount: 20, taxCode: "VAT_5")
            ],
            totalTaxAmount: 80,
            customer: ClientSession.Customer(id: "customer_id", taxId: "CUSTOMER_TAX_ID")
        )

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then
        XCTAssertEqual(sut.lineItems?.map(\.taxAmount), [60, 20])
        XCTAssertEqual(sut.lineItems?.map(\.taxCode), ["VAT_20", "VAT_5"])
    }

    func test_init_from_mapsAbsentLineItemTaxToNil_notTheOrderTotal() {
        // Given — the line item carries no tax, but the order and customer do
        let configuration = makeConfiguration(
            lineItems: [makeLineItem(itemId: "item_1", amount: 1000, taxAmount: nil, taxCode: nil)],
            totalTaxAmount: 200,
            customer: ClientSession.Customer(id: "customer_id", taxId: "CUSTOMER_TAX_ID")
        )

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then — absent means absent; it must not be back-filled from the order
        XCTAssertNil(sut.lineItems?.first?.taxAmount)
        XCTAssertNil(sut.lineItems?.first?.taxCode)
    }

    // MARK: - Amount and currency

    // The two values CheckoutComponents used to expose as bare scalars on `.ready`.
    func test_init_from_mapsAmountAndCurrency() {
        // Given
        let configuration = makeConfiguration(totalOrderAmount: 2500, currencyCode: "EUR")

        // When
        let sut = PrimerClientSession(from: configuration)

        // Then
        XCTAssertEqual(sut.totalAmount, 2500)
        XCTAssertEqual(sut.currencyCode, "EUR")
        XCTAssertEqual(sut.orderId, "order_id")
    }
}
