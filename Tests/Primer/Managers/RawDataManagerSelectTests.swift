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
    private var tokenizedCard: CardPaymentInstrument?
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

    func test_submit_card_pickTheCardDoesNotOffer_reachesNeitherTheSelectNorTheToken() {
        PrimerInternal.shared.sdkIntegrationType = .headless
        addTeardownBlock { PrimerInternal.shared.sdkIntegrationType = nil }

        let selectCalls = selectCallsAtTokenize(of: coBadgedCard(pickedNetwork: .visa), lookupNetworks: [.cartesBancaires, .masterCard])

        XCTAssertEqual(selectCalls.map(\.network), ["CARTES_BANCAIRES"])
        XCTAssertNotNil(tokenizedCard)
        XCTAssertNil(tokenizedCard?.preferredNetwork)
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

    func test_typing_networkChangesInQuickSuccession_sendOneSelectWithTheLastNetwork() async throws {
        let gate = prepareForTyping(sut)

        sut.rawData = visaCard()
        sut.rawData = coBadgedCard(pickedNetwork: nil)
        await MainActor.run {}
        cardLookup.stubbedMetadata = .remoteLookup([.cartesBancaires, .masterCard])
        _ = try? await sut.validateRawData(withCardNetworksMetadata: cardLookup.stubbedMetadata)
        try await releaseSelections(afterHolding: 3, on: gate)
        try await waitForSelectCalls(1)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.type), ["PAYMENT_CARD"])
        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["CARTES_BANCAIRES"])
    }

    func test_typing_unchangedNetwork_sendsNoSecondSelect() async throws {
        let gate = prepareForTyping(sut)

        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForSelectCalls(1)
        sut.rawData = visaCard()
        await MainActor.run {}

        let heldCount = await gate.heldCount
        XCTAssertEqual(heldCount, 0)
        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["VISA"])
    }

    func test_surcharge_everyFeeZero_isOff() {
        SDKSessionHelper.updateAllowedCardNetworks(
            cardNetworks: [.visa],
            paymentMethodOptions: [
                ["type": "APPLE_PAY", "surcharge": 0],
                ["type": "PAYMENT_CARD", "networks": [["type": "VISA", "surcharge": 0]]]
            ]
        )

        XCTAssertEqual(PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled, false)
    }

    func test_failedSubmit_typingTheEarlierNetworkAgain_sendsIt() async throws {
        let gate = prepareForTyping(sut)
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }
        tokenizationService.onTokenize = { _ in .failure(PrimerError.unknown()) }
        let expectDidFail = expectation(description: "Payment failed")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForSelectCalls(1)
        sut.rawData = masterCard()
        try await waitForHeldSelections(1, on: gate)
        sut.submit()
        await gate.release()
        await fulfillment(of: [expectDidFail], timeout: 5.0)
        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForSelectCalls(3)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["VISA", "MASTERCARD", "VISA"])
    }

    func test_submit_card_networkSentWhileTyping_sendsNoSecondSelect() async throws {
        let gate = prepareForTyping(sut)
        let request = NetworkSelectionGate()
        clientSessionActions.onSelectPaymentMethod = { await request.wait() }
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }
        tokenizationService.onTokenize = { _ in .failure(PrimerError.unknown()) }
        let expectDidFail = expectation(description: "Payment stopped after tokenizing")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForHeldSelections(1, on: request)
        sut.submit()
        try await Task.sleep(nanoseconds: 300_000_000)
        await request.release()
        await fulfillment(of: [expectDidFail], timeout: 5.0)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["VISA"])
    }

    func test_submit_card_sessionUpdatedElsewhereAfterTheTypingSelect_selectsAgain() async throws {
        let gate = prepareForTyping(sut)
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }
        tokenizationService.onTokenize = { _ in .failure(PrimerError.unknown()) }
        let expectDidFail = expectation(description: "Payment stopped after tokenizing")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForSelectCalls(1)
        SDKSessionHelper.updateAllowedCardNetworks(
            cardNetworks: [.cartesBancaires, .masterCard, .visa],
            paymentMethodOptions: [["type": "PAYMENT_CARD", "networks": [["type": "CARTES_BANCAIRES", "surcharge": 50]]]]
        )
        sut.submit()
        await fulfillment(of: [expectDidFail], timeout: 5.0)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["VISA", "VISA"])
    }

    func test_typing_unchangedUpdateWhileTheSelectRuns_sendsItAgainWhenThatSelectFails() async throws {
        let gate = prepareForTyping(sut)
        let request = NetworkSelectionGate()
        failFirstSelect(holdingItOn: request)

        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForHeldSelections(1, on: request)
        sut.rawData = visaCard()
        try await waitForHeldSelections(1, on: gate)
        await request.release()
        await gate.release()
        try await waitForSelectCalls(2)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["VISA", "VISA"])
    }

    func test_typing_unchangedUpdateWhileTheSelectRuns_sendsNoSecondSelect() async throws {
        let gate = prepareForTyping(sut)
        let request = NetworkSelectionGate()
        clientSessionActions.onSelectPaymentMethod = { await request.wait() }

        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForHeldSelections(1, on: request)
        sut.rawData = visaCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        await request.release()
        try await waitForSelectCalls(1)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["VISA"])
    }

    func test_typing_rawDataClearedWhileASelectWaits_dropsIt() async throws {
        let gate = prepareForTyping(sut)

        sut.rawData = visaCard()
        try await waitForHeldSelections(1, on: gate)
        sut.rawData = nil
        await MainActor.run {}
        await gate.release()
        sut.rawData = masterCard()
        try await releaseSelections(afterHolding: 1, on: gate)
        try await waitForSelectCalls(1)

        XCTAssertEqual(clientSessionActions.selectPaymentMethodCalls.map(\.network), ["MASTERCARD"])
    }

    private func failFirstSelect(holdingItOn request: NetworkSelectionGate) {
        clientSessionActions.onSelectPaymentMethod = { [weak actions = clientSessionActions] in
            guard actions?.selectPaymentMethodCalls.count == 1 else { return }
            await request.wait()
            throw PrimerError.unknown(message: "Select failed")
        }
    }

    func test_typing_inDropIn_sendsNoSelect() async throws {
        addTeardownBlock { PrimerInternal.shared.sdkIntegrationType = nil }
        let rawDataManager = try RawDataManager(paymentMethodType: "PAYMENT_CARD", isUsedInDropIn: true)
        let gate = prepareForTyping(rawDataManager)

        rawDataManager.rawData = visaCard()
        _ = try? await rawDataManager.validateRawData(withCardNetworksMetadata: .remoteLookup([.visa]))
        await MainActor.run {}

        let heldCount = await gate.heldCount
        XCTAssertEqual(heldCount, 0)
        XCTAssertTrue(clientSessionActions.selectPaymentMethodCalls.isEmpty)
    }

    private func prepareForTyping(_ rawDataManager: RawDataManager) -> NetworkSelectionGate {
        SDKSessionHelper.updateAllowedCardNetworks(
            cardNetworks: [.cartesBancaires, .masterCard, .visa],
            paymentMethodOptions: [["type": "PAYMENT_CARD", "networks": [["type": "CARTES_BANCAIRES", "surcharge": 50]]]]
        )
        (rawDataManager.rawDataTokenizationBuilder as? PrimerRawCardDataTokenizationBuilder)?.cardValidationService = cardLookup
        rawDataManager.clientSessionActionsModule = clientSessionActions
        let gate = NetworkSelectionGate()
        rawDataManager.waitForNetworkSelection = gate.wait
        return gate
    }

    private func waitForSelectCalls(_ count: Int) async throws {
        try await withTimeout(2.0) {
            while self.clientSessionActions.selectPaymentMethodCalls.count < count { await Task.yield() }
        }
        await MainActor.run {}
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
        tokenizationService.onTokenize = { requestBody in
            selectCalls = self.clientSessionActions.selectPaymentMethodCalls
            self.tokenizedCard = requestBody.paymentInstrument as? CardPaymentInstrument
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

    private func masterCard() -> PrimerCardData {
        PrimerCardData(cardNumber: "5555 5555 5555 4444", expiryDate: "03/2030", cvv: "123", cardholderName: "John Appleseed")
    }
}
