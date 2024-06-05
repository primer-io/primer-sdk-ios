//
//  ApplePayPresentationManagerTests.swift
//  
//
//  Created by Jack Newcombe on 23/05/2024.
//

import XCTest
@testable import PrimerSDK

final class ApplePayPresentationManagerTests: XCTestCase {

    var sut: ApplePayPresentationManager!

    override func setUpWithError() throws {
        sut = ApplePayPresentationManager()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testCreateRequest() throws {
        let applePayRequest = ApplePayRequest(currency: Currency(code: "GBP", decimalDigits: 2),
                                              merchantIdentifier: "merchant_id",
                                              countryCode: .gb,
                                              items: [
                                                try .init(name: "line_item_name",
                                                          unitAmount: 123,
                                                          quantity: 1,
                                                          discountAmount: nil,
                                                          taxAmount: nil)
                                              ])
        let request = sut.createRequest(for: applePayRequest)

        XCTAssertEqual(request.countryCode, "GB")
        XCTAssertEqual(request.currencyCode, "GBP")
        XCTAssertEqual(request.merchantIdentifier, "merchant_id")

        XCTAssertNotNil(request.paymentSummaryItems.first)
        XCTAssertEqual(request.paymentSummaryItems.first!.amount.doubleValue, 1.23, accuracy: 0.01)
        XCTAssertEqual(request.paymentSummaryItems.first!.label, "line_item_name")
        XCTAssertEqual(request.paymentSummaryItems.first!.type, .final)
    }

    func testIsPresentable() {
        XCTAssertTrue(sut.isPresentable)

        registerApplePayOptions()
        XCTAssertTrue(sut.isPresentable)

        registerAllowedCardNetworks()
        XCTAssertTrue(sut.isPresentable)
    }

    func testErrorForDisplay() {
        let error = sut.errorForDisplay
        XCTAssertTrue(error.localizedDescription.hasPrefix("[unable-to-present-payment-method] Unable to present payment method APPLE_PAY"))

        registerApplePayOptions()
        let error2 = sut.errorForDisplay
        XCTAssertTrue(error2.localizedDescription.hasPrefix("[unable-to-make-payments-on-provided-networks] Unable to make payments on provided networks"))
    }

    // MARK: Helpers

    func registerApplePayOptions() {
        let settings = PrimerSettings(paymentMethodOptions:
            .init(applePayOptions:
                .init(merchantIdentifier: "merchant_id", merchantName: "merchant_name", checkProvidedNetworks: true)
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    func registerAllowedCardNetworks() {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = .init(clientSessionId: "client_session_id",
                                                                             paymentMethod: .init(vaultOnSuccess: false,
                                                                                                  options: nil,
                                                                                                  orderedAllowedCardNetworks: [
                                                                                                    "CARTES_BANCAIRES"
                                                                                                  ]),
                                                                             order: nil,
                                                                             customer: nil,
                                                                             testId: nil)

    }
}
