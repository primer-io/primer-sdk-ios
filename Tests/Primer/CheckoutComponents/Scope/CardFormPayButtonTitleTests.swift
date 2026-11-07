//
//  CardFormPayButtonTitleTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class CardFormPayButtonTitleTests: XCTestCase {

    private let gbp = Currency(code: "GBP", decimalDigits: 2)

    override func setUp() async throws {
        try await super.setUp()
        await ContainerTestHelpers.resetSharedContainer()
    }

    override func tearDown() async throws {
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_payButtonTitle_withoutOptions_returnsDefaultTitle() {
        XCTAssertEqual(title(nil, amount: "£10.00"), "Pay")
    }

    func test_payButtonTitle_withDefaultOptions_returnsDefaultTitle() {
        XCTAssertEqual(title(PrimerCardFormUIOptions(), amount: "£10.00"), "Pay")
    }

    func test_payButtonTitle_withCustomText_returnsCustomText() {
        XCTAssertEqual(title(PrimerCardFormUIOptions(payButtonText: "Complete order"), amount: "£10.00"), "Complete order")
    }

    func test_payButtonTitle_withBlankCustomText_returnsDefaultTitle() {
        XCTAssertEqual(title(PrimerCardFormUIOptions(payButtonText: "  "), amount: "£10.00"), "Pay")
    }

    func test_payButtonTitle_withPaddedCustomText_trimsIt() {
        let options = PrimerCardFormUIOptions(payButtonText: " Buy now ", payButtonAmountVisible: true)
        XCTAssertEqual(title(options, amount: "£10.00"), "Buy now £10.00")
    }

    func test_payButtonTitle_withAmountVisibleAndNoCustomText_usesTranslatedPayWithAmountText() {
        XCTAssertEqual(title(PrimerCardFormUIOptions(payButtonAmountVisible: true), amount: "10,00 €"), "10,00 € bezahlen")
    }

    func test_payButtonTitle_withCustomTextAndAmountVisible_appendsAmountToCustomText() {
        let options = PrimerCardFormUIOptions(payButtonText: "Complete order", payButtonAmountVisible: true)
        XCTAssertEqual(title(options, amount: "£10.00"), "Complete order £10.00")
    }

    func test_payButtonTitle_withAmountVisibleAndNoAmount_returnsTitleAlone() {
        XCTAssertEqual(title(PrimerCardFormUIOptions(payButtonAmountVisible: true), amount: nil), "Pay")
    }

    func test_decoding_withoutPayButtonKeys_usesDefaults() throws {
        let options = try JSONDecoder().decode(PrimerCardFormUIOptions.self, from: Data("{}".utf8))

        XCTAssertFalse(options.payButtonAddNewCard)
        XCTAssertNil(options.payButtonText)
        XCTAssertFalse(options.payButtonAmountVisible)
    }

    func test_decoding_withPayButtonKeys_readsThem() throws {
        let json = #"{"payButtonAddNewCard":true,"payButtonText":"Complete order","payButtonAmountVisible":true}"#
        let options = try JSONDecoder().decode(PrimerCardFormUIOptions.self, from: Data(json.utf8))

        XCTAssertTrue(options.payButtonAddNewCard)
        XCTAssertEqual(options.payButtonText, "Complete order")
        XCTAssertTrue(options.payButtonAmountVisible)
    }

    func test_formattedPayAmount_withoutSurcharge_returnsSessionAmount() async {
        let sut = await makeScope(amount: 1000)
        XCTAssertEqual(sut.formattedPayAmount(surchargeAmount: nil), "£10.00")
    }

    func test_formattedPayAmount_withNetworkSurcharge_addsSurcharge() async {
        let sut = await makeScope(amount: 1000, order: makeOrder(totalOrderAmount: 1000))
        XCTAssertEqual(sut.formattedPayAmount(surchargeAmount: 150), "£11.50")
    }

    func test_formattedPayAmount_whenSessionHasSurchargeFee_countsSurchargeOnce() async {
        let sut = await makeScope(amount: 1150, order: makeOrder(totalOrderAmount: 1150, surchargeFee: 150))
        XCTAssertEqual(sut.formattedPayAmount(surchargeAmount: 150), "£11.50")
    }

    func test_formattedPayAmount_whenNetworkHasNoSurchargeButSessionHasFee_removesFee() async {
        let sut = await makeScope(amount: 1150, order: makeOrder(totalOrderAmount: 1150, surchargeFee: 150))
        XCTAssertEqual(sut.formattedPayAmount(surchargeAmount: nil), "£10.00")
    }

    func test_formattedPayAmount_withMerchantAmount_ignoresSurcharge() async {
        let sut = await makeScope(amount: 1000, order: makeOrder(merchantAmount: 1000, totalOrderAmount: 1000))
        XCTAssertEqual(sut.formattedPayAmount(surchargeAmount: 150), "£10.00")
    }

    func test_formattedPayAmount_withoutCurrency_returnsNil() async {
        let sut = await makeScope(amount: 1000, currency: nil)
        XCTAssertNil(sut.formattedPayAmount(surchargeAmount: nil))
    }

    private func title(_ options: PrimerCardFormUIOptions?, amount: String?) -> String {
        PrimerCardFormUIOptions.payButtonTitle(
            options,
            formattedAmount: amount,
            defaultTitle: "Pay",
            defaultTitleWithAmount: { "\($0) bezahlen" }
        )
    }

    private func makeScope(
        amount: Int?,
        currency: Currency? = Currency(code: "GBP", decimalDigits: 2),
        order: ClientSession.Order? = nil
    ) async -> DefaultCardFormScope {
        DefaultCardFormScope(
            checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            configurationService: MockConfigurationService(
                apiConfiguration: order.map(makeConfiguration),
                currency: currency,
                amount: amount,
                locale: Locale(identifier: "en_GB")
            )
        )
    }

    private func makeConfiguration(order: ClientSession.Order) -> PrimerAPIConfiguration {
        PrimerAPIConfiguration(
            coreUrl: nil,
            pciUrl: nil,
            binDataUrl: nil,
            assetsUrl: nil,
            clientSession: ClientSession.APIResponse(
                clientSessionId: "client-session-id",
                paymentMethod: nil,
                order: order,
                customer: nil,
                testId: nil
            ),
            paymentMethods: nil,
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )
    }

    private func makeOrder(merchantAmount: Int? = nil, totalOrderAmount: Int, surchargeFee: Int? = nil) -> ClientSession.Order {
        ClientSession.Order(
            id: "order-id",
            merchantAmount: merchantAmount,
            totalOrderAmount: totalOrderAmount,
            totalTaxAmount: nil,
            countryCode: .gb,
            currencyCode: gbp,
            fees: surchargeFee.map { [ClientSession.Order.Fee(type: .surcharge, amount: $0)] },
            lineItems: nil
        )
    }
}
