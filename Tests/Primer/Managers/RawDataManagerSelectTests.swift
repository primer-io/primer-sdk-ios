//
//  RawDataManagerSelectTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerNetworking
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

final class RawDataManagerSelectTests: XCTestCase {

    private var headlessCheckoutDelegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    private var tokenizationService: MockTokenizationService!
    private var clientSessionActions: MockClientSessionActionsModule!
    private var cardLookup: StubCardValidationService!
    private var sut: RawDataManager!

    override func setUpWithError() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod])
        headlessCheckoutDelegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        tokenizationService = MockTokenizationService()
        clientSessionActions = MockClientSessionActionsModule()
        cardLookup = StubCardValidationService()

        sut = try RawDataManager(paymentMethodType: "PAYMENT_CARD")
        sut.tokenizationService = tokenizationService
        sut.clientSessionActionsModule = clientSessionActions

        PrimerHeadlessUniversalCheckout.current.delegate = headlessCheckoutDelegate
    }

    override func tearDownWithError() throws {
        sut = nil
        cardLookup = nil
        clientSessionActions = nil
        tokenizationService = nil
        headlessCheckoutDelegate = nil
        SDKSessionHelper.tearDown()
    }

    func test_submit_card_withLookupResult_selectsTheLookupNetworkBeforeTokenizing() {
        let selectCalls = selectCallsAtTokenize(of: coBadgedCard(pickedNetwork: nil), lookupNetworks: [.cartesBancaires, .masterCard])

        XCTAssertEqual(selectCalls.map(\.type), ["PAYMENT_CARD"])
        XCTAssertEqual(selectCalls.map(\.network), ["CARTES_BANCAIRES"])
    }

    func test_submit_card_lookupFails_selectsTheFirstDigitsNetwork() {
        let selectCalls = selectCallsAtTokenize(of: coBadgedCard(pickedNetwork: nil), lookupNetworks: nil)

        XCTAssertEqual(cardLookup.remoteMetadataRequests, ["5017679210000700"])
        XCTAssertEqual(selectCalls.map(\.network), ["MAESTRO"])
    }

    func test_submit_card_noSurcharge_selectsWithoutANetworkOrALookup() {
        let selectCalls = selectCallsAtTokenize(of: coBadgedCard(pickedNetwork: nil), lookupNetworks: nil, surcharged: false)

        XCTAssertTrue(cardLookup.remoteMetadataRequests.isEmpty)
        XCTAssertEqual(selectCalls.map(\.network), [nil])
    }

    func test_submit_card_selectFails_failsWithTheSelectErrorWithoutTokenizing() {
        let selectError = PrimerError.unknown(message: "Select failed")
        clientSessionActions.selectPaymentMethodError = selectError
        var tokenizeCallCount = 0
        tokenizationService.onTokenize = { _ in
            tokenizeCallCount += 1
            return .failure(PrimerError.unknown())
        }
        var reportedError: Error?
        let expectDidFail = expectation(description: "Payment failed")
        headlessCheckoutDelegate.onDidFail = { error in
            reportedError = error
            expectDidFail.fulfill()
        }

        sut.rawData = visaCard()
        sut.submit()

        waitForExpectations(timeout: 5.0)
        XCTAssertEqual((reportedError as? PrimerError)?.diagnosticsId, selectError.diagnosticsId)
        XCTAssertEqual(tokenizeCallCount, 0)
    }

    func test_submit_card_fromCheckoutComponentsFactory_sendsNoSelect() throws {
        let rawDataManager = try XCTUnwrap(
            DefaultRawDataManagerFactory().createRawDataManager(paymentMethodType: "PAYMENT_CARD", delegate: nil) as? RawDataManager
        )
        rawDataManager.tokenizationService = tokenizationService
        rawDataManager.clientSessionActionsModule = clientSessionActions
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }
        let expectTokenize = expectation(description: "Card tokenized")
        tokenizationService.onTokenize = { _ in
            expectTokenize.fulfill()
            return .failure(PrimerError.unknown())
        }
        let expectDidFail = expectation(description: "Payment stopped after tokenizing")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        rawDataManager.rawData = visaCard()
        rawDataManager.submit()

        waitForExpectations(timeout: 5.0)
        XCTAssertTrue(clientSessionActions.selectPaymentMethodCalls.isEmpty)
    }

    func test_submit_blik_selectsTheMethodWithoutNetworkBeforeThePayment() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.adyenBlikPaymentMethod])
        let blikManager = try RawDataManager(paymentMethodType: "ADYEN_BLIK")
        blikManager.tokenizationService = tokenizationService
        blikManager.clientSessionActionsModule = clientSessionActions
        var selectCalls: [(type: String, network: String?)] = []
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            selectCalls = self.clientSessionActions.selectPaymentMethodCalls
            decisionHandler(.abortPaymentCreation())
        }
        let expectDidFail = expectation(description: "Payment stopped before it was created")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        blikManager.rawData = PrimerOTPData(otp: "123456")
        blikManager.submit()

        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(selectCalls.map(\.type), ["ADYEN_BLIK"])
        XCTAssertEqual(selectCalls.map(\.network), [nil])
    }

    private func selectCallsAtTokenize(
        of card: PrimerCardData,
        lookupNetworks: [CardNetwork]?,
        surcharged: Bool = true
    ) -> [(type: String, network: String?)] {
        SDKSessionHelper.updateAllowedCardNetworks(
            cardNetworks: [.cartesBancaires, .masterCard, .visa],
            paymentMethodOptions: surcharged ? [["type": "PAYMENT_CARD", "networks": [["type": "CARTES_BANCAIRES", "surcharge": 50]]]] : nil
        )
        cardLookup.stubbedMetadata = lookupNetworks.map(PrimerCardNumberEntryMetadata.remoteLookup)
        (sut.rawDataTokenizationBuilder as? PrimerRawCardDataTokenizationBuilder)?.cardValidationService = cardLookup
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }
        var selectCalls: [(type: String, network: String?)] = []
        tokenizationService.onTokenize = { _ in
            selectCalls = self.clientSessionActions.selectPaymentMethodCalls
            return .failure(PrimerError.unknown())
        }
        let expectDidFail = expectation(description: "Payment stopped after tokenizing")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        sut.rawData = card
        sut.submit()

        waitForExpectations(timeout: 5.0)
        return selectCalls
    }

    private func coBadgedCard(pickedNetwork: CardNetwork?) -> PrimerCardData {
        PrimerCardData(
            cardNumber: "5017679210000700",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Appleseed",
            cardNetwork: pickedNetwork
        )
    }

    private func visaCard() -> PrimerCardData {
        PrimerCardData(
            cardNumber: "4111 1111 1111 1111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Appleseed"
        )
    }
}
