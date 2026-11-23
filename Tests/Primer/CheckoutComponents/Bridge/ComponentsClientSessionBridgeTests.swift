//
//  ComponentsClientSessionBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ComponentsClientSessionBridgeTests: XCTestCase {

    private var configuration: PrimerAPIConfiguration?
    private var sut: ComponentsClientSessionBridge!

    override func setUp() {
        super.setUp()
        configuration = nil
        sut = ComponentsClientSessionBridge { [self] in configuration }
    }

    override func tearDown() {
        sut = nil
        configuration = nil
        super.tearDown()
    }

    // MARK: - getClientSession

    func test_getClientSession_returnsNil_whenConfigurationMissing() {
        XCTAssertNil(sut.getClientSession())
    }

    func test_getClientSession_returnsMappedSession_whenConfigurationPresent() {
        configuration = makeConfiguration(clientSession: makeClientSession(orderId: "order-123"))

        let session = sut.getClientSession()

        XCTAssertNotNil(session)
        XCTAssertEqual(session?.orderId, "order-123")
    }

    // MARK: - getOrderedAllowedCardNetworks

    func test_getOrderedAllowedCardNetworks_returnsNil_whenConfigurationMissing() {
        XCTAssertNil(sut.getOrderedAllowedCardNetworks())
    }

    func test_getOrderedAllowedCardNetworks_returnsNil_whenPaymentMethodMissing() {
        configuration = makeConfiguration(clientSession: makeClientSession(orderId: "order-123"))

        XCTAssertNil(sut.getOrderedAllowedCardNetworks())
    }

    func test_getOrderedAllowedCardNetworks_returnsList_whenPaymentMethodPresent() {
        configuration = makeConfiguration(
            clientSession: makeClientSession(
                orderId: "order-123",
                orderedAllowedCardNetworks: ["VISA", "MASTERCARD", "AMEX"]
            )
        )

        XCTAssertEqual(sut.getOrderedAllowedCardNetworks(), ["VISA", "MASTERCARD", "AMEX"])
    }

    // MARK: - getCheckoutModules

    func test_getCheckoutModules_returnsNil_whenConfigurationMissing() {
        XCTAssertNil(sut.getCheckoutModules())
    }

    func test_getCheckoutModules_returnsNil_whenModulesMissing() {
        configuration = makeConfiguration(checkoutModules: nil)
        XCTAssertNil(sut.getCheckoutModules())
    }

    func test_getCheckoutModules_returnsEmpty_whenModulesEmpty() {
        configuration = makeConfiguration(checkoutModules: [])
        XCTAssertEqual(sut.getCheckoutModules()?.count, 0)
    }

    func test_getCheckoutModules_flattensPostalCodeOptions() {
        let postal = PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions(
            firstName: true,
            lastName: false,
            postalCode: true,
            countryCode: true
        )
        configuration = makeConfiguration(
            checkoutModules: [.init(type: "BILLING_ADDRESS", requestUrlStr: nil, options: postal)]
        )

        let modules = sut.getCheckoutModules()

        XCTAssertEqual(modules?.count, 1)
        XCTAssertEqual(modules?.first?.type, "BILLING_ADDRESS")
        XCTAssertEqual(modules?.first?.options?["firstName"], true)
        XCTAssertEqual(modules?.first?.options?["lastName"], false)
        XCTAssertEqual(modules?.first?.options?["postalCode"], true)
        XCTAssertEqual(modules?.first?.options?["countryCode"], true)
        XCTAssertNil(modules?.first?.options?["city"])
    }

    func test_getCheckoutModules_flattensCardInformationOptions() throws {
        let json = #"{"cardHolderName":true,"saveCardCheckbox":false}"#.data(using: .utf8)!
        let card = try JSONDecoder().decode(
            PrimerAPIConfiguration.CheckoutModule.CardInformationOptions.self,
            from: json
        )
        configuration = makeConfiguration(
            checkoutModules: [.init(type: "CARD_INFORMATION", requestUrlStr: nil, options: card)]
        )

        let modules = sut.getCheckoutModules()

        XCTAssertEqual(modules?.first?.type, "CARD_INFORMATION")
        XCTAssertEqual(modules?.first?.options?["cardHolderName"], true)
        XCTAssertEqual(modules?.first?.options?["saveCardCheckbox"], false)
    }

    func test_getCheckoutModules_returnsNilOptions_forUnsupportedOptionType() {
        configuration = makeConfiguration(
            checkoutModules: [.init(type: "SHIPPING", requestUrlStr: nil, options: nil)]
        )

        let modules = sut.getCheckoutModules()

        XCTAssertEqual(modules?.first?.type, "SHIPPING")
        XCTAssertNil(modules?.first?.options)
    }

    func test_getPaymentMethodOptions_returnsNil_whenConfigurationMissing() {
        XCTAssertNil(sut.getPaymentMethodOptions())
    }

    func test_getPaymentMethodOptions_returnsTheFeeOfEachMethod() {
        configuration = makeConfiguration(paymentMethodOptions: [
            ["type": "PAYPAL", "surcharge": 50],
            ["type": "APPLE_PAY", "surcharge": 0],
            ["type": "KLARNA"]
        ])

        let options = sut.getPaymentMethodOptions()

        XCTAssertEqual(options?.map(\.type), ["PAYPAL", "APPLE_PAY", "KLARNA"])
        XCTAssertEqual(options?.map(\.surcharge), [50, 0, nil])
        XCTAssertEqual(options?.map(\.networks.isEmpty), [true, true, true])
    }

    func test_getPaymentMethodOptions_returnsTheFeeOfEachCardNetwork_zeroIncluded() {
        configuration = makeConfiguration(paymentMethodOptions: [[
            "type": "PAYMENT_CARD",
            "networks": [
                ["type": "VISA", "surcharge": 100],
                ["type": "CARTES_BANCAIRES", "surcharge": 0],
                ["type": "MASTERCARD"]
            ]
        ]])

        let card = sut.getPaymentMethodOptions()?.first

        XCTAssertEqual(card?.type, "PAYMENT_CARD")
        XCTAssertNil(card?.surcharge)
        XCTAssertEqual(card?.networks.map(\.type), ["VISA", "CARTES_BANCAIRES", "MASTERCARD"])
        XCTAssertEqual(card?.networks.map(\.surcharge), [100, 0, nil])
    }

    // MARK: - Helpers

    private func makeConfiguration(paymentMethodOptions: [[String: Any]]) -> PrimerAPIConfiguration {
        makeConfiguration(clientSession: ClientSession.APIResponse(
            clientSessionId: "client-session-id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        ))
    }

    private func makeConfiguration(
        clientSession: ClientSession.APIResponse? = nil,
        checkoutModules: [PrimerAPIConfiguration.CheckoutModule]? = nil
    ) -> PrimerAPIConfiguration {
        PrimerAPIConfiguration(
            coreUrl: nil,
            pciUrl: nil,
            binDataUrl: nil,
            assetsUrl: nil,
            clientSession: clientSession,
            paymentMethods: nil,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: checkoutModules
        )
    }

    private func makeClientSession(
        orderId: String,
        orderedAllowedCardNetworks: [String]? = nil
    ) -> ClientSession.APIResponse {
        let paymentMethod = orderedAllowedCardNetworks.map { networks in
            ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: networks,
                descriptor: nil
            )
        }
        return ClientSession.APIResponse(
            clientSessionId: "client-session-id",
            paymentMethod: paymentMethod,
            order: .init(
                id: orderId,
                merchantAmount: nil,
                totalOrderAmount: 1234,
                totalTaxAmount: nil,
                countryCode: nil,
                currencyCode: nil,
                fees: nil,
                lineItems: nil
            ),
            customer: nil,
            testId: nil
        )
    }
}
