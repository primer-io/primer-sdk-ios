//
//  VaultManagerTests.swift
//
//
//  Created by Jack Newcombe on 10/06/2024.
//

import XCTest
@testable import PrimerSDK

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
            customer: .init(id: "id",
                            firstName: "first_name",
                            lastName: "last_name",
                            billingAddress: .init(firstName: "first_name",
                                                  lastName: "last_name",
                                                  addressLine1: "address_line_1",
                                                  addressLine2: "address_line_2",
                                                  city: "city",
                                                  postalCode: "EC4M 7RF",
                                                  state: "UK",
                                                  countryCode: .gb))
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

        let expectDidFetchVaultedPaymentMethods = self.expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let expectDidCompleteCheckout = self.expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectCreatePayment = self.expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectExchangeTokenData = self.expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return Mocks.primerPaymentMethodTokenData
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

        let expectDidFetchVaultedPaymentMethods = self.expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let expectDidResumeWith = self.expectation(description: "On did resume with token and decision")
        headlessCheckoutDelegate.onDidResumeWith = { token, decisionHandler in
            XCTAssertEqual(token, "4321")
            decisionHandler(.complete())
            expectDidResumeWith.fulfill()
        }

        let expectDidTokenize = self.expectation(description: "On did tokenize")
        headlessCheckoutDelegate.onDidTokenizePaymentMethod = { _, decisionHandler in
            expectDidTokenize.fulfill()
            decisionHandler(.continueWithNewClientToken(MockAppState.mockResumeToken))
        }

        let expectExchangeTokenData = self.expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return Mocks.primerPaymentMethodTokenData
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

        let expectDidFetchVaultedPaymentMethods = self.expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let expectDidCompleteCheckout = self.expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectCreatePayment = self.expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBodyWithRedirectAction
        }

        let expectExchangeTokenData = self.expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return Mocks.primerPaymentMethodTokenData
        }

        let expectResumePayment = self.expectation(description: "On resume payment")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectResumePayment.fulfill()
            return self.paymentResponseAfterResume
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.startPaymentFlow(vaultedPaymentMethodId: Mocks.primerPaymentMethodTokenData.id!)

        waitForExpectations(timeout: 15.0)
    }

    func testFullPaymentFlow_ACH() throws {

        let apiClient = MockPrimerAPIClient()
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.sdkCompleteUrlResult = (Response.Body.Complete(), nil)
        PrimerAPIConfigurationModule.apiClient = apiClient

        let expectDidFetchVaultedPaymentMethods = self.expectation(description: "Did fetch vaulted payment methods")
        sut.fetchVaultedPaymentMethods { _, _ in
            expectDidFetchVaultedPaymentMethods.fulfill()
        }

        waitForExpectations(timeout: 2.0)

        let expectExchangeTokenData = self.expectation(description: "Token data exchanged")
        tokenizationService.onExchangePaymentMethodToken = { _, _ in
            expectExchangeTokenData.fulfill()
            return self.primerPaymentMethodTokenData
        }

        let expectCreatePayment = self.expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentACHResponseBody
        }

        let expectDidCompleteCheckout = self.expectation(description: "Headless checkout completed")
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

    // MARK: Helpers

    var tokenizationResponseBody: Response.Body.Tokenization {
        .init(analyticsId: "analytics_id",
              id: "id",
              isVaulted: false,
              isAlreadyVaulted: false,
              paymentInstrumentType: .offSession,
              paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
              paymentInstrumentData: nil,
              threeDSecureAuthentication: nil,
              token: "token",
              tokenType: .singleUse,
              vaultData: nil)
    }

    var paymentResponseBody: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "GBP",
                     customer: .init(firstName: "first_name",
                                     lastName: "last_name",
                                     emailAddress: "email_address",
                                     mobileNumber: "+44(0)7891234567",
                                     billingAddress: .init(firstName: "billing_first_name",
                                                           lastName: "billing_last_name",
                                                           addressLine1: "billing_line_1",
                                                           addressLine2: "billing_line_2",
                                                           city: "billing_city",
                                                           state: "billing_state",
                                                           countryCode: "billing_country_code",
                                                           postalCode: "billing_postal_code"),
                                     shippingAddress: .init(firstName: "shipping_first_name",
                                                            lastName: "shipping_last_name",
                                                            addressLine1: "shipping_line_1",
                                                            addressLine2: "shipping_line_2",
                                                            city: "shipping_city",
                                                            state: "shipping_state",
                                                            countryCode: "shipping_country_code",
                                                            postalCode: "shipping_postal_code")),
                     customerId: "customer_id",
                     orderId: "order_id",
                     status: .success)
    }

    var paymentResponseBodyWithRedirectAction: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "GBP",
                     customer: .init(firstName: "first_name",
                                     lastName: "last_name",
                                     emailAddress: "email_address",
                                     mobileNumber: "+44(0)7891234567",
                                     billingAddress: .init(firstName: "billing_first_name",
                                                           lastName: "billing_last_name",
                                                           addressLine1: "billing_line_1",
                                                           addressLine2: "billing_line_2",
                                                           city: "billing_city",
                                                           state: "billing_state",
                                                           countryCode: "billing_country_code",
                                                           postalCode: "billing_postal_code"),
                                     shippingAddress: .init(firstName: "shipping_first_name",
                                                            lastName: "shipping_last_name",
                                                            addressLine1: "shipping_line_1",
                                                            addressLine2: "shipping_line_2",
                                                            city: "shipping_city",
                                                            state: "shipping_state",
                                                            countryCode: "shipping_country_code",
                                                            postalCode: "shipping_postal_code")),
                     customerId: "customer_id",
                     orderId: "order_id",
                     requiredAction: .init(clientToken: MockAppState.mockClientTokenWithRedirect,
                                           name: .checkout,
                                           description: "description"),
                     status: .success)
    }

    var paymentACHResponseBody: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "USD",
                     customer: .init(firstName: "first_name",
                                     lastName: "last_name",
                                     emailAddress: "email_address",
                                     mobileNumber: "+44(0)7891234567",
                                     billingAddress: .init(firstName: "billing_first_name",
                                                           lastName: "billing_last_name",
                                                           addressLine1: "billing_line_1",
                                                           addressLine2: "billing_line_2",
                                                           city: "billing_city",
                                                           state: "billing_state",
                                                           countryCode: "billing_country_code",
                                                           postalCode: "billing_postal_code"),
                                     shippingAddress: .init(firstName: "shipping_first_name",
                                                            lastName: "shipping_last_name",
                                                            addressLine1: "shipping_line_1",
                                                            addressLine2: "shipping_line_2",
                                                            city: "shipping_city",
                                                            state: "shipping_state",
                                                            countryCode: "shipping_country_code",
                                                            postalCode: "shipping_postal_code")),
                     customerId: "customer_id",
                     orderId: "order_id",
                     requiredAction: .init(clientToken: MockAppState.stripeACHToken,
                                           name: .checkout,
                                           description: "description"),
                     status: .success)
    }

    var paymentResponseAfterResume: Response.Body.Payment {
        .init(id: "id",
              paymentId: "payment_id",
              amount: 1234,
              currencyCode: "GBP",
              customerId: "customer_id",
              orderId: "order_id",
              status: .success)
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
        vaultData: nil)
}

private class MockVaultService: VaultServiceProtocol {

    func fetchVaultedPaymentMethods() -> PrimerSDK.Promise<Void> {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        let paymentMethod = Mocks.primerPaymentMethodTokenData
        paymentMethod.paymentInstrumentData = Mocks.primerPaymentMethodInstrumentationData
        appState.paymentMethods = [paymentMethod]
        appState.selectedPaymentMethodId = Mocks.primerPaymentMethodTokenData.id

        return Promise.value
    }

    func deleteVaultedPaymentMethod(with id: String) -> PrimerSDK.Promise<Void> {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        if Mocks.primerPaymentMethodTokenData.id == id {
            appState.paymentMethods = []
            appState.selectedPaymentMethodId = nil
        }

        return Promise.value
    }

}
