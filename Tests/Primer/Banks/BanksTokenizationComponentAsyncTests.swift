//
//  BanksTokenizationComponentAsyncTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class BanksTokenizationComponentAsyncTests: XCTestCase {
    // MARK: - Test Dependencies

    private var apiClient: MockBanksAPIClient!
    private var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    private var stepDelegate: MockBanksStepDelegate!
    private var validationDelegate: MockBanksValidationDelegate!
    private var tokenizationService: MockTokenizationService!
    private var createResumePaymentService: MockCreateResumePaymentService!
    private var uiManager: MockPrimerUIManager!
    private var sut: BanksTokenizationComponent!

    // MARK: - Helper Methods

    private let paymentResponseBody = Response.Body.Payment(
        id: "id",
        paymentId: "payment_id",
        amount: 123,
        currencyCode: "GBP",
        customer: Request.Body.ClientSession.Customer(
            firstName: "first_name",
            lastName: "last_name",
            emailAddress: "email_address",
            mobileNumber: "+44(0)7891234567",
            billingAddress: PaymentAPIModelAddress(
                firstName: "billing_first_name",
                lastName: "billing_last_name",
                addressLine1: "billing_line_1",
                addressLine2: "billing_line_2",
                city: "billing_city",
                state: "billing_state",
                countryCode: "billing_country_code",
                postalCode: "billing_postal_code"
            ),
            shippingAddress: PaymentAPIModelAddress(
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

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        let paymentMethod = Mocks.PaymentMethods.idealFormWithRedirectPaymentMethod
        apiClient = MockBanksAPIClient()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        sut = BanksTokenizationComponent(config: paymentMethod,
                                         uiManager: uiManager,
                                         tokenizationService: tokenizationService,
                                         createResumePaymentService: createResumePaymentService,
                                         apiClient: apiClient)

        stepDelegate = MockBanksStepDelegate()
        validationDelegate = MockBanksValidationDelegate()

        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
    }

    override func tearDownWithError() throws {
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        delegate = nil
        validationDelegate = nil
        stepDelegate = nil

        sut = nil
        apiClient = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil

        SDKSessionHelper.tearDown()

        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    // MARK: - Validation Tests

    func test_validate_withValidSession_shouldSucceed() throws {
        try SDKSessionHelper.test {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func test_validate_withInvalidSession_shouldThrowError() throws {
        XCTAssertThrowsError(try sut.validate())
    }

    // MARK: - Banks Retrieval Tests

    func test_fetchBanks_shouldReturnBanksSuccessfully() throws {
        let banks: BanksListSessionResponse = .init(
            result: [.init(id: "id", name: "name", iconUrlStr: "icon", disabled: false)]
        )

        apiClient.result = banks

        let expectation = expectation(description: "Bank fetch is successful")

        try SDKSessionHelper.test { done in
            Task {
                let result = try? await self.sut.retrieveListOfBanks()
                XCTAssertEqual(result, banks.result)
                expectation.fulfill()
                done()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Flow Tests

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() throws {
        apiClient.result = .init(result: [
            .init(id: "bank_id", name: "bank_name", iconUrlStr: "icon_url_str", disabled: false)
        ])

        let appState = MockAppState(clientToken: MockAppState.mockClientToken)
        DependencyContainer.register(appState as AppStateProtocol)

        let expectDidFinishFlow = expectation(description: "Should finish")
        let defaultBanksComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal,
                                                          tokenizationProvidingModel: sut) {
            expectDidFinishFlow.fulfill()
            return WebRedirectComponent(paymentMethodType: .adyenIDeal,
                                        tokenizationModelDelegate: self.sut)
        }
        defaultBanksComponent.stepDelegate = stepDelegate
        defaultBanksComponent.validationDelegate = validationDelegate

        let expectIsLoadingStep = expectation(description: "Did start loading")
        let expectDidGetBanksStep = expectation(description: "Did get bank step")
        stepDelegate.onReceiveStep = { step in
            switch step {
            case .loading:
                expectIsLoadingStep.fulfill()
            case .banksRetrieved(let banks):
                XCTAssertEqual(banks.first!.id, "bank_id")
                expectDidGetBanksStep.fulfill()
            }
        }

        defaultBanksComponent.start()

        wait(for: [expectIsLoadingStep, expectDidGetBanksStep], timeout: 2.0, enforceOrder: true)

        let expectDidStartValidating = expectation(description: "Did validate")
        let expectDidValidate = expectation(description: "Did validate")
        validationDelegate.onDidUpdate = { status, _ in
            switch status {
            case .validating:
                expectDidStartValidating.fulfill()
            case .valid:
                expectDidValidate.fulfill()
            default:
                XCTFail()
            }
        }

        defaultBanksComponent.updateCollectedData(collectableData: .bankId(bankId: "bank_id"))

        wait(for: [expectDidStartValidating, expectDidValidate], timeout: 2.0)

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.success(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCreatePayment = expectation(description: "Did create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectDidCompleteCheckout = expectation(description: "Did complete checkout")
        delegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        defaultBanksComponent.submit()

        wait(for: [
            expectDidFinishFlow,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidCompleteCheckout
        ], timeout: 15.0, enforceOrder: true)
    }

    func test_startFlow_manualPaymentHandling_shouldCompleteSuccessfully() throws {
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

        self.apiClient.result = .init(result: [
            .init(id: "bank_id", name: "bank_name", iconUrlStr: "icon_url_str", disabled: false)
        ])

        let appState = MockAppState(clientToken: MockAppState.mockClientToken)
        DependencyContainer.register(appState as AppStateProtocol)

        let settings = PrimerSettings(paymentHandling: .manual)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let expectDidFinishFlow = expectation(description: "Should finish")
        let defaultBanksComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal,
                                                          tokenizationProvidingModel: sut) {
            expectDidFinishFlow.fulfill()
            return WebRedirectComponent(paymentMethodType: .adyenIDeal,
                                        tokenizationModelDelegate: self.sut)
        }
        defaultBanksComponent.stepDelegate = stepDelegate
        defaultBanksComponent.validationDelegate = validationDelegate

        let expectIsLoadingStep = expectation(description: "Did start loading")
        let expectDidGetBanksStep = expectation(description: "Did get bank step")
        stepDelegate.onReceiveStep = { step in
            switch step {
            case .loading:
                expectIsLoadingStep.fulfill()
            case .banksRetrieved(let banks):
                XCTAssertEqual(banks.first!.id, "bank_id")
                expectDidGetBanksStep.fulfill()
            }
        }

        defaultBanksComponent.start()

        wait(for: [expectIsLoadingStep, expectDidGetBanksStep], timeout: 5.0, enforceOrder: true)

        let expectDidStartValidating = expectation(description: "Did validate")
        let expectDidValidate = expectation(description: "Did validate")
        validationDelegate.onDidUpdate = { status, _ in
            switch status {
            case .validating:
                expectDidStartValidating.fulfill()
            case .valid:
                expectDidValidate.fulfill()
            default:
                XCTFail()
            }
        }

        defaultBanksComponent.updateCollectedData(collectableData: .bankId(bankId: "bank_id"))

        wait(for: [expectDidStartValidating, expectDidValidate], timeout: 5.0)

        let mockViewController = MockPrimerRootViewController()
        uiManager.primerRootViewController = mockViewController

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.success(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidTokenizePaymentMethod = expectation(description: "Did tokenize delegate method")
        delegate.onDidTokenizePaymentMethod = { _, decisionHandler in
            decisionHandler(.continueWithNewClientToken(MockAppState.mockResumeToken))
            expectDidTokenizePaymentMethod.fulfill()
        }

        let expectDidResume = expectation(description: "Did resume")
        let expectDidFinishPayment = expectation(description: "Did finish payment")
        delegate.onDidResumeWith = { _, decisionHandler in
            decisionHandler(.complete())

            self.sut.didFinishPayment = { _ in
                expectDidFinishPayment.fulfill()
            }

            expectDidResume.fulfill()
        }

        defaultBanksComponent.submit()

        wait(for: [
            expectDidFinishFlow,
            expectDidTokenize,
            expectDidTokenizePaymentMethod,
            expectDidResume,
            expectDidFinishPayment
        ], timeout: 25.0, enforceOrder: true)
    }
}

// MARK: - Mock Classes

final class MockBanksStepDelegate: PrimerHeadlessSteppableDelegate {
    var onReceiveStep: ((BanksStep) -> Void)?

    func didReceiveStep(step: PrimerHeadlessStep) {
        onReceiveStep?(step as! BanksStep)
    }
}

final class MockBanksValidationDelegate: PrimerHeadlessValidatableDelegate {
    var onDidUpdate: ((PrimerValidationStatus, PrimerCollectableData?) -> Void)?

    func didUpdate(validationStatus: PrimerValidationStatus, for data: PrimerCollectableData?) {
        onDidUpdate?(validationStatus, data)
    }
}
