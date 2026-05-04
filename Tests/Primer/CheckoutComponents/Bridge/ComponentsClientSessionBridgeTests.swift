//
//  ComponentsClientSessionBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@_spi(PrimerInternal) @testable import PrimerSDK

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

    // MARK: - Helpers

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

    private func makeClientSession(orderId: String) -> ClientSession.APIResponse {
        ClientSession.APIResponse(
            clientSessionId: "client-session-id",
            paymentMethod: nil,
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
