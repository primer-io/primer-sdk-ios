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
        currencyCode: String? = "GBP"
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
                totalTaxAmount: nil,
                countryCode: .gb,
                currencyCode: currencyCode.flatMap { CurrencyLoader().getCurrency($0) },
                fees: fees,
                lineItems: nil
            ),
            customer: nil,
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
