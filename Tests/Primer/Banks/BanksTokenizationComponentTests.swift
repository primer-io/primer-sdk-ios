//
//  BanksTokenizationComponentTests.swift
//  
//
//  Created by Jack Newcombe on 07/05/2024.
//

import XCTest
@testable import PrimerSDK

class MockBanksAPIClient: PrimerAPIClientBanksProtocol {

    var result: BanksListSessionResponse?

    var error: Error?

    func listAdyenBanks(clientToken: PrimerSDK.DecodedJWTToken, request: Request.Body.Adyen.BanksList, completion: @escaping PrimerSDK.APICompletion<BanksListSessionResponse>) {
        if let error = error {
            completion(.failure(error))
        } else if let result = result {
            completion(.success(result))
        }
    }
}

final class BanksTokenizationComponentTests: XCTestCase {

    var apiClient: MockBanksAPIClient!

    var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!

    var stepDelegate: MockBanksStepDelegate!

    var validationDelegate: MockBanksValidationDelegate!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var uiManager: MockPrimerUIManager!

    var sut: BanksTokenizationComponent!

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

    func testValidationSuccess() throws {
        try SDKSessionHelper.test {
            XCTAssertNoThrow(try self.sut.validate())
        }
    }

    func testValidationFailure() throws {
        XCTAssertThrowsError(try sut.validate())
    }

    func testFetchBanksSuccess() throws {
        let banks: BanksListSessionResponse = .init(
            result: [.init(id: "id", name: "name", iconUrlStr: "icon", disabled: false)]
        )

        apiClient.result = banks

        let expectation = self.expectation(description: "Bank fetch is successful")

        try SDKSessionHelper.test { done in
            _ = self.sut.retrieveListOfBanks().done { result in
                XCTAssertEqual(result, banks.result)
                expectation.fulfill()
                done()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testFullPaymentFlow() throws {
        apiClient.result = .init(result: [
            .init(id: "bank_id", name: "bank_name", iconUrlStr: "icon_url_str", disabled: false)
        ])

        let appState = MockAppState(clientToken: MockAppState.mockClientToken)
        DependencyContainer.register(appState as AppStateProtocol)

        let expectDidFinishFlow = self.expectation(description: "Should finish")
        let defaultBanksComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal,
                                                          tokenizationProvidingModel: sut) {
            expectDidFinishFlow.fulfill()
            return WebRedirectComponent(paymentMethodType: .adyenIDeal,
                                        tokenizationModelDelegate: self.sut)
        }
        defaultBanksComponent.stepDelegate = stepDelegate
        defaultBanksComponent.validationDelegate = validationDelegate


        let expectIsLoadingStep = self.expectation(description: "Did start loading")
        let expectDidGetBanksStep = self.expectation(description: "Did get bank step")
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

        let expectDidStartValidating = self.expectation(description: "Did validate")
        let expectDidValidate = self.expectation(description: "Did validate")
        validationDelegate.onDidUpdate = { status, data in
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

        let expectDidTokenize = self.expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.value(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCreatePayment = self.expectation(description: "Did create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectDidCompleteCheckout = self.expectation(description: "Did complete checkout")
        delegate.onDidCompleteCheckoutWithData = { data in
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

        self.apiClient.result = .init(result: [
            .init(id: "bank_id", name: "bank_name", iconUrlStr: "icon_url_str", disabled: false)
        ])

        let appState = MockAppState(clientToken: MockAppState.mockClientToken)
        DependencyContainer.register(appState as AppStateProtocol)

        let settings = PrimerSettings(paymentHandling: .manual)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let expectDidFinishFlow = self.expectation(description: "Should finish")
        let defaultBanksComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal,
                                                          tokenizationProvidingModel: sut) {
            expectDidFinishFlow.fulfill()
            return WebRedirectComponent(paymentMethodType: .adyenIDeal,
                                        tokenizationModelDelegate: self.sut)
        }
        defaultBanksComponent.stepDelegate = stepDelegate
        defaultBanksComponent.validationDelegate = validationDelegate

        let expectIsLoadingStep = self.expectation(description: "Did start loading")
        let expectDidGetBanksStep = self.expectation(description: "Did get bank step")
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

        let expectDidStartValidating = self.expectation(description: "Did validate")
        let expectDidValidate = self.expectation(description: "Did validate")
        validationDelegate.onDidUpdate = { status, data in
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

        let expectDidTokenize = self.expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Promise.value(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidTokenizePaymentMethod = self.expectation(description: "Did tokenize delegate method")
        delegate.onDidTokenizePaymentMethod = { _, decisionHandler in
            decisionHandler(.continueWithNewClientToken(MockAppState.mockResumeToken))
            expectDidTokenizePaymentMethod.fulfill()
        }

        let expectDidResume = self.expectation(description: "Did resume")
        let expectDidFinishPayment = self.expectation(description: "Did finish payment")
        delegate.onDidResumeWith = { _, decisionHandler in
            decisionHandler(.complete())
            
            self.sut.didFinishPayment = { data in
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

    // MARK: Helpers

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
                     dateStr: nil,
                     order: nil,
                     orderId: "order_id",
                     requiredAction: nil,
                     status: .success,
                     paymentFailureReason: nil)
    }
}

class MockBanksStepDelegate: PrimerHeadlessSteppableDelegate {

    var onReceiveStep: ((BanksStep) -> Void)?

    func didReceiveStep(step: PrimerHeadlessStep) {
        onReceiveStep?(step as! BanksStep)
    }
}

class MockBanksValidationDelegate: PrimerHeadlessValidatableDelegate {

    var onDidUpdate: ((PrimerValidationStatus, PrimerCollectableData?) -> Void)?

    func didUpdate(validationStatus: PrimerValidationStatus, for data: PrimerCollectableData?) {
        onDidUpdate?(validationStatus, data)
    }
}
