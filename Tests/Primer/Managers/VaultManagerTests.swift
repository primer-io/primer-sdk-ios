//
//  VaultManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerNetworking
@_spi(PrimerInternal) @testable import PrimerSDK
import XCTest

final class VaultManagerTests: XCTestCase {

    var headlessCheckoutDelegate: MockPrimerHeadlessUniversalCheckoutDelegate!

    var rawDataManagerDelegate: MockRawDataManagerDelegate!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    private var vaultService: MockVaultService!

    var sut: PrimerHeadlessUniversalCheckout.VaultManager!

    override func setUpWithError() throws {
        SDKSessionHelper.setUp(
            withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod],
            customer: .init(
                id: "id",
                firstName: "first_name",
                lastName: "last_name",
                billingAddress: .init(
                    firstName: "first_name",
                    lastName: "last_name",
                    addressLine1: "address_line_1",
                    addressLine2: "address_line_2",
                    city: "city",
                    postalCode: "EC4M 7RF",
                    state: "UK",
                    countryCode: .gb
                )
            )
        )
        headlessCheckoutDelegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        rawDataManagerDelegate = MockRawDataManagerDelegate()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        vaultService = MockVaultService()

        sut = PrimerHeadlessUniversalCheckout.VaultManager()
        sut.tokenizationService = tokenizationService
        sut.createResumePaymentService = createResumePaymentService
        sut.vaultService = vaultService

        PrimerHeadlessUniversalCheckout.current.delegate = headlessCheckoutDelegate

        try sut?.configure()
    }

    override func tearDownWithError() throws {
        sut = nil
        rawDataManagerDelegate = nil

        SDKSessionHelper.tearDown()

        PrimerAPIConfigurationModule.apiClient = nil
        PollingModule.apiClient = nil

        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    func testFullPaymentFlow_auto() throws {

        let expectDidFetchVaultedPaymentMethods = expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let expectDidCompleteCheckout = expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectCreatePayment = expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectExchangeTokenData = expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return .success(Mocks.primerPaymentMethodTokenData)
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.startPaymentFlow(vaultedPaymentMethodId: Mocks.primerPaymentMethodTokenData.id!)

        waitForExpectations(timeout: 5.0)
    }

    func testFullPaymentFlow_manual() throws {
        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "4321", source: "src"), nil)
        ]
        apiClient.validateClientTokenResult = (SuccessResponse(), nil)
        apiClient.listCardNetworksResult = (.init(networks: []), nil)

        let settings = PrimerSettings(paymentHandling: .manual)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let expectDidFetchVaultedPaymentMethods = expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let expectDidResumeWith = expectation(description: "On did resume with token and decision")
        headlessCheckoutDelegate.onDidResumeWith = { token, decisionHandler in
            XCTAssertEqual(token, "4321")
            decisionHandler(.complete())
            expectDidResumeWith.fulfill()
        }

        let expectDidTokenize = expectation(description: "On did tokenize")
        headlessCheckoutDelegate.onDidTokenizePaymentMethod = { _, decisionHandler in
            expectDidTokenize.fulfill()
            decisionHandler(.continueWithNewClientToken(MockAppState.mockResumeToken))
        }

        let expectExchangeTokenData = expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return .success(Mocks.primerPaymentMethodTokenData)
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.startPaymentFlow(vaultedPaymentMethodId: Mocks.primerPaymentMethodTokenData.id!)

        waitForExpectations(timeout: 15.0)
    }

    func testFullPaymentFlowWithRequiredActionResume() throws {
        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "4321", source: "src"), nil)
        ]

        let settings = PrimerSettings(paymentHandling: .auto)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let expectDidFetchVaultedPaymentMethods = expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let expectDidCompleteCheckout = expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectCreatePayment = expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBodyWithRedirectAction
        }

        let expectExchangeTokenData = expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return .success(Mocks.primerPaymentMethodTokenData)
        }

        let expectResumePayment = expectation(description: "On resume payment")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectResumePayment.fulfill()
            return self.paymentResponseAfterResume
        }

        let observer = RecordingRequiredActionObserver()
        sut.requiredActionObserver = observer

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.startPaymentFlow(vaultedPaymentMethodId: Mocks.primerPaymentMethodTokenData.id!)

        waitForExpectations(timeout: 15.0)
        XCTAssertEqual(observer.calls, [
            .redirectOpened(URL(string: "https://localhost/redirect")!, paymentId: "id"),
            .redirectReturned(paymentId: "id")
        ])
    }

    func testProcessor3DS_reportsTheChallengeAndNoRedirect() throws {
        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [(PollingResponse(status: .complete, id: "4321", source: "src"), nil)]
        DependencyContainer.register(PrimerSettings(paymentHandling: .auto) as PrimerSettingsProtocol)

        let expectDidFetchVaultedPaymentMethods = expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in expectDidFetchVaultedPaymentMethods.fulfill() }
        waitForExpectations(timeout: 2.0)

        let expectDidCompleteCheckout = expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in expectDidCompleteCheckout.fulfill() }
        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }
        tokenizationService.onExchangePaymentMethodToken = { _, _ in .success(Mocks.primerPaymentMethodTokenData) }
        createResumePaymentService.onCreatePayment = { _ in
            self.paymentResponseBody(requiredActionToken: MockAppState.mockClientTokenWithProcessor3DS)
        }
        createResumePaymentService.onResumePayment = { _, _ in self.paymentResponseAfterResume }
        let observer = RecordingRequiredActionObserver()
        sut.requiredActionObserver = observer

        sut.startPaymentFlow(vaultedPaymentMethodId: Mocks.primerPaymentMethodTokenData.id!)

        waitForExpectations(timeout: 15.0)
        XCTAssertEqual(observer.calls, [.threeDSChallengeShown(provider: "PROCESSOR", protocolVersion: nil)])
    }

    func testFullPaymentFlow_ACH() throws {

        let apiClient = MockPrimerAPIClient()
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.sdkCompleteUrlResult = (Response.Body.Complete(), nil)
        PrimerAPIConfigurationModule.apiClient = apiClient

        let expectDidFetchVaultedPaymentMethods = expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }

        waitForExpectations(timeout: 2.0)

        let expectExchangeTokenData = expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return .success(self.primerPaymentMethodTokenData)
        }

        let expectCreatePayment = expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentACHResponseBody
        }

        let expectDidCompleteCheckout = expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.startPaymentFlow(vaultedPaymentMethodId: Mocks.primerPaymentMethodTokenData.id!)

        wait(for: [
            expectExchangeTokenData,
            expectCreatePayment,
            expectDidCompleteCheckout
        ], timeout: 20.0, enforceOrder: true)
    }

    func test_startPaymentFlow_savedCard_selectsCardNetworkBeforeExchange() {
        let selectCalls = selectCallsAtExchange(for: savedMethod(type: "PAYMENT_CARD", instrumentType: .paymentCard))

        XCTAssertEqual(selectCalls.map(\.type), ["PAYMENT_CARD"])
        XCTAssertEqual(selectCalls.map(\.network), ["AMEX"])
    }

    func test_startPaymentFlow_savedCardWithoutAKnownNetwork_selectsOther() throws {
        let noNetwork = try instrumentData(json: "{}")
        let unknownNetwork = try instrumentData(json: #"{"binData":{"network":"UNKNOWN"}}"#)

        for data in [noNetwork, unknownNetwork] {
            let selectCalls = selectCallsAtExchange(for: savedMethod(type: "PAYMENT_CARD", instrumentType: .paymentCard, instrumentData: data))
            XCTAssertEqual(selectCalls.map(\.network), ["OTHER"])
        }
    }

    func test_startPaymentFlow_savedNonCard_selectsTypeWithoutNetwork() {
        let selectCalls = selectCallsAtExchange(for: savedMethod(type: "PAYPAL", instrumentType: .payPalBillingAgreement))

        XCTAssertEqual(selectCalls.map(\.type), ["PAYPAL"])
        XCTAssertEqual(selectCalls.map(\.network), [nil])
    }

    func test_startPaymentFlow_selectFails_failsWithTheSelectErrorWithoutExchange() {
        let selectError = PrimerError.unknown(message: "Select failed")
        let clientSessionActions = MockClientSessionActionsModule()
        clientSessionActions.selectPaymentMethodError = selectError
        sut.clientSessionActionsModule = clientSessionActions
        sut.vaultedPaymentMethods = [savedMethod(type: "PAYMENT_CARD", instrumentType: .paymentCard)]

        var exchangeCallCount = 0
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            exchangeCallCount += 1
            return .success(Mocks.primerPaymentMethodTokenData)
        }
        var reportedError: Error?
        let expectDidFail = expectation(description: "Payment failed")
        headlessCheckoutDelegate.onDidFail = { error in
            reportedError = error
            expectDidFail.fulfill()
        }

        sut.startPaymentFlow(vaultedPaymentMethodId: "saved-id")

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual((reportedError as? PrimerError)?.diagnosticsId, selectError.diagnosticsId)
        XCTAssertEqual(exchangeCallCount, 0)
    }

    // MARK: Helpers

    private func selectCallsAtExchange(
        for savedMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
    ) -> [(type: String, network: String?)] {
        let clientSessionActions = MockClientSessionActionsModule()
        sut.clientSessionActionsModule = clientSessionActions
        sut.vaultedPaymentMethods = [savedMethod]

        var selectCalls: [(type: String, network: String?)] = []
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            selectCalls = clientSessionActions.selectPaymentMethodCalls
            return .failure(PrimerError.unknown())
        }
        let expectDidFail = expectation(description: "Payment stopped after the exchange")
        headlessCheckoutDelegate.onDidFail = { _ in expectDidFail.fulfill() }

        sut.startPaymentFlow(vaultedPaymentMethodId: savedMethod.id)

        waitForExpectations(timeout: 2.0)
        return selectCalls
    }

    private func savedMethod(
        type: String,
        instrumentType: PaymentInstrumentType,
        instrumentData: Response.Body.Tokenization.PaymentInstrumentData = Mocks.primerPaymentMethodInstrumentationData
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: "saved-id",
            paymentMethodType: type,
            paymentInstrumentType: instrumentType,
            paymentInstrumentData: instrumentData,
            analyticsId: "analytics-id"
        )
    }

    private func instrumentData(json: String) throws -> Response.Body.Tokenization.PaymentInstrumentData {
        try JSONDecoder().decode(Response.Body.Tokenization.PaymentInstrumentData.self, from: Data(json.utf8))
    }

    var tokenizationResponseBody: Response.Body.Tokenization {
        .init(
            analyticsId: "analytics_id",
            id: "id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .offSession,
            paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "token",
            tokenType: .singleUse,
            vaultData: nil
        )
    }

    var paymentResponseBody: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 123,
            currencyCode: "GBP",
            customer: .init(
                firstName: "first_name",
                lastName: "last_name",
                emailAddress: "email_address",
                mobileNumber: "+44(0)7891234567",
                billingAddress: .init(
                    firstName: "billing_first_name",
                    lastName: "billing_last_name",
                    addressLine1: "billing_line_1",
                    addressLine2: "billing_line_2",
                    city: "billing_city",
                    state: "billing_state",
                    countryCode: "billing_country_code",
                    postalCode: "billing_postal_code"
                ),
                shippingAddress: .init(
                    firstName: "shipping_first_name",
                    lastName: "shipping_last_name",
                    addressLine1: "shipping_line_1",
                    addressLine2: "shipping_line_2",
                    city: "shipping_city",
                    state: "shipping_state",
                    countryCode: "shipping_country_code",
                    postalCode: "shipping_postal_code"
                )
            ),
            customerId: "customer_id",
            orderId: "order_id",
            status: .success
        )
    }

    func paymentResponseBody(requiredActionToken: String) -> Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 123,
            currencyCode: "GBP",
            customerId: "customer_id",
            orderId: "order_id",
            requiredAction: .init(clientToken: requiredActionToken, name: .checkout, description: "description"),
            status: .success
        )
    }

    var paymentResponseBodyWithRedirectAction: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 123,
            currencyCode: "GBP",
            customer: .init(
                firstName: "first_name",
                lastName: "last_name",
                emailAddress: "email_address",
                mobileNumber: "+44(0)7891234567",
                billingAddress: .init(
                    firstName: "billing_first_name",
                    lastName: "billing_last_name",
                    addressLine1: "billing_line_1",
                    addressLine2: "billing_line_2",
                    city: "billing_city",
                    state: "billing_state",
                    countryCode: "billing_country_code",
                    postalCode: "billing_postal_code"
                ),
                shippingAddress: .init(
                    firstName: "shipping_first_name",
                    lastName: "shipping_last_name",
                    addressLine1: "shipping_line_1",
                    addressLine2: "shipping_line_2",
                    city: "shipping_city",
                    state: "shipping_state",
                    countryCode: "shipping_country_code",
                    postalCode: "shipping_postal_code"
                )
            ),
            customerId: "customer_id",
            orderId: "order_id",
            requiredAction: .init(
                clientToken: MockAppState.mockClientTokenWithRedirect,
                name: .checkout,
                description: "description"
            ),
            status: .success
        )
    }

    var paymentACHResponseBody: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 123,
            currencyCode: "USD",
            customer: .init(
                firstName: "first_name",
                lastName: "last_name",
                emailAddress: "email_address",
                mobileNumber: "+44(0)7891234567",
                billingAddress: .init(
                    firstName: "billing_first_name",
                    lastName: "billing_last_name",
                    addressLine1: "billing_line_1",
                    addressLine2: "billing_line_2",
                    city: "billing_city",
                    state: "billing_state",
                    countryCode: "billing_country_code",
                    postalCode: "billing_postal_code"
                ),
                shippingAddress: .init(
                    firstName: "shipping_first_name",
                    lastName: "shipping_last_name",
                    addressLine1: "shipping_line_1",
                    addressLine2: "shipping_line_2",
                    city: "shipping_city",
                    state: "shipping_state",
                    countryCode: "shipping_country_code",
                    postalCode: "shipping_postal_code"
                )
            ),
            customerId: "customer_id",
            orderId: "order_id",
            requiredAction: .init(
                clientToken: MockAppState.stripeACHToken,
                name: .checkout,
                description: "description"
            ),
            status: .success
        )
    }

    var paymentResponseAfterResume: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 1234,
            currencyCode: "GBP",
            customerId: "customer_id",
            orderId: "order_id",
            status: .success
        )
    }

    var primerPaymentMethodTokenData = PrimerPaymentMethodTokenData(
        analyticsId: "mock_analytics_id",
        id: "mock_payment_method_token_data_id",
        isVaulted: false,
        isAlreadyVaulted: false,
        paymentInstrumentType: .stripeAch,
        paymentMethodType: "mock_payment_method_type",
        paymentInstrumentData: nil,
        threeDSecureAuthentication: nil,
        token: "mock_payment_method_token",
        tokenType: .singleUse,
        vaultData: nil
    )
}

private class MockVaultService: VaultServiceProtocol {
    func fetchVaultedPaymentMethods() async throws {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        let paymentMethod = Mocks.primerPaymentMethodTokenData
        paymentMethod.paymentInstrumentData = Mocks.primerPaymentMethodInstrumentationData
        appState.paymentMethods = [paymentMethod]
        appState.selectedPaymentMethodId = Mocks.primerPaymentMethodTokenData.id
    }

    func deleteVaultedPaymentMethod(with id: String) async throws {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        if Mocks.primerPaymentMethodTokenData.id == id {
            appState.paymentMethods = []
            appState.selectedPaymentMethodId = nil
        }
    }
}
