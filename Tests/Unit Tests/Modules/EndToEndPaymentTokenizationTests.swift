//
//  EndToEndPaymentTokenizationTests.swift
//
//
//  Created by Jack Newcombe on 01/05/2024.
//

import XCTest
@testable import PrimerSDK

final class EndToEndPaymentTokenizationTests: XCTestCase {

    var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!

    var rawDataManagerDelegate: MockPrimerHeadlessUniversalCheckoutRawDataManagerDelegate!

    var uiDelegate: MockPrimerHeadlessUniversalCheckoutUIDelegate!

    let timeout = 10.0

    override func setUpWithError() throws {
        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        delegate.strictMode = true
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        uiDelegate.strictMode = true
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        rawDataManagerDelegate = MockPrimerHeadlessUniversalCheckoutRawDataManagerDelegate()
        uiDelegate.strictMode = true
    }

    override func tearDownWithError() throws {
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil

        PrimerHeadlessUniversalCheckout.current.delegate = nil
        PrimerHeadlessUniversalCheckout.current.uiDelegate = nil

        PrimerAPIConfigurationModule.apiClient = nil
        PaymentMethodTokenizationViewModel.apiClient = nil
        TokenizationService.apiClient = nil
        PollingModule.apiClient = nil
        CreateResumePaymentService.apiClient = nil
        DefaultCardValidationService.apiClient = nil
    }

    // MARK: NativeUIManager Tests

    func testNativeUIManager_presentAdyenGiroPay_withoutSurcharge_auto() throws {
        setupSettings(handling: .auto)

        let paymentMethod = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)
        
        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod)

        try presentNativeUIManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    func testNativeUIManager_presentAdyenGiroPay_withSurcharge_auto() throws {
        setupSettings(handling: .auto)

        let surchargeAmount: Int = 99

        let paymentMethod = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod, surchargeAmount: 99)

        try presentNativeUIManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    func testNativeUIManager_presentAdyenGiroPay_withoutSurcharge_manual() throws {
        setupSettings(handling: .manual)

        let paymentMethod = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod, 
                                                           handling: .manual)

        try presentNativeUIManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    func testNativeUIManager_presentAdyenGiroPay_withSurcharge_manual() throws {
        setupSettings(handling: .manual)

        let surchargeAmount: Int = 99

        let paymentMethod = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod, 
                                                           handling: .manual,
                                                           surchargeAmount: 99)

        try presentNativeUIManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    func testNativeUIManager_presentAdyenGiroPay_withoutSurcharge_auto_abort() throws {
        setupSettings(handling: .auto)

        let paymentMethod = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod,
                                                           shouldAbort: true)

        try presentNativeUIManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    // MARK: RawDataManager Tests

    func testRawDataManager_presentPaymentCard_withoutSurcharge_auto() throws {
        setupSettings(handling: .auto)

        let paymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod)

        try submitWithRawDataManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    func testRawDataManager_presentPaymentCard_withoutSurcharge_manual() throws {
        setupSettings(handling: .manual)

        let paymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod,
                                                           handling: .manual)

        try submitWithRawDataManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }

    func testRawDataManager_presentAdyenGiroPay_withoutSurcharge_auto_abort() throws {
        setupSettings(handling: .auto)

        let paymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(
            paymentMethod: paymentMethod
        )
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod,
                                                           shouldAbort: true)

        try submitWithRawDataManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }


    // JN TODO: Check with Semir - why doesn't RDM support surcharge? can we fix it?
//    func testRawDataManager_presentAdyenGiroPay_withSurcharge() throws {
//        setupSettings(handling: .auto)
//
//        let surchargeAmount: Int = 99
//
//        let paymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod
//        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
//        let apiConfiguration = setupApiConfiguration(
//            paymentMethod: paymentMethod,
//            surchargeAmount: surchargeAmount
//        )
//        setupMockApiClients(apiConfiguration: apiConfiguration)
//
//        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod, surchargeAmount: 99)
//
//        try submitWithRawDataManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
//    }

    // MARK: Presentation helpers

    func presentNativeUIManager(paymentMethod: PrimerPaymentMethod,
                                expecting orderedExpectations: [XCTestExpectation]) throws {
        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: {$0.type == paymentMethod.type}) else {
            XCTFail("Failed to find payment method \(paymentMethod.type) in mocked API configuration response")
            return
        }

        do {
            let paymentMethodNativeUIManager = try PrimerHeadlessUniversalCheckout.NativeUIManager(
                paymentMethodType: paymentMethod.type
            )
            try paymentMethodNativeUIManager.showPaymentMethod(intent: .checkout)
        } catch {
            XCTFail(error.localizedDescription)
        }

        wait(for: orderedExpectations, timeout: timeout, enforceOrder: true)
    }

    func submitWithRawDataManager(paymentMethod: PrimerPaymentMethod,
                                  expecting orderedExpectations: [XCTestExpectation]) throws {
        do {
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethod.type,
                                                                                    delegate: rawDataManagerDelegate)

            let rawCardData = PrimerCardData(
                cardNumber: "4111 1111 1111 1111",
                expiryDate: "03/2030",
                cvv: "123",
                cardholderName: "John Smith"
            )

            rawDataManager.rawData = rawCardData
            rawDataManager.submit()
        } catch {
            XCTAssert(false, error.localizedDescription)
        }

        wait(for: orderedExpectations, timeout: timeout, enforceOrder: true)
    }


    // MARK: Other Helpers

    func expectationsForDelegates(paymentMethod: PrimerPaymentMethod,
                                  handling: PrimerPaymentHandling = .auto,
                                  shouldAbort: Bool = false,
                                  surchargeAmount: Int? = nil) -> [XCTestExpectation] {

        var orderedExpectations: [XCTestExpectation] = []

        let expectPreparationDidStart = self.expectation(description: "Expected UI delegate method: preparationDidStart")
        uiDelegate.onUIDidStartPreparation = { paymentMethodType in
            XCTAssertEqual(paymentMethodType, paymentMethod.type)
            expectPreparationDidStart.fulfill()
        }
        orderedExpectations.append(expectPreparationDidStart)

        if let surchargeAmount = surchargeAmount {
            let expectClientSessionWillUpdate = self.expectation(description: "Expected delegate method: willUpdateClientSession")
            delegate.onWillUpdateClientSession = {
                expectClientSessionWillUpdate.fulfill()
            }
            orderedExpectations.append(expectClientSessionWillUpdate)


            let expectClientSessionDidUpdate = self.expectation(description: "Expected delegate method: didUpdateClientSession")
            delegate.onDidUpdateClientSession = { session in
                guard let _surchargeAmount = self.clientSession?.paymentMethod?.options?[0]["surcharge"] as? Int else {
                    XCTFail(); return
                }
                XCTAssertEqual(_surchargeAmount, surchargeAmount)
                expectClientSessionDidUpdate.fulfill()
            }
            orderedExpectations.append(expectClientSessionDidUpdate)
        }

        let expectWillCreatePaymentWithData = self.expectation(description: "Expected delegate method: willCreatePaymentWithData")
        delegate.onWillCreatePaymentWithData = { data, decisionHandler in
            XCTAssertEqual(data.paymentMethodType.type, paymentMethod.type)
            decisionHandler(shouldAbort ? .abortPaymentCreation() : .continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }
        orderedExpectations.append(expectWillCreatePaymentWithData)

        if shouldAbort {
            let expectDidFail = self.expectation(description: "Expected delegate method: didFail")
            delegate.onDidFail = { err in
                XCTAssertNotNil(err)
                expectDidFail.fulfill()
            }
            orderedExpectations.append(expectDidFail)

            if handling == .auto, paymentMethod.internalPaymentMethodType != .paymentCard  {
                let expectOnDismiss = self.expectation(description: "Expected delegate method: onDimiss")
                uiDelegate.onUIDidDismissPaymentMethod = {
                    expectOnDismiss.fulfill()
                }
                orderedExpectations.append(expectOnDismiss)
            }
            return orderedExpectations
        }

        let expectDidStartTokenization = self.expectation(description: "Expected delegate method: didStartTokenization")
        delegate.onDidStartTokenization = { paymentMethodType in
            XCTAssertEqual(paymentMethodType, paymentMethod.type)
            expectDidStartTokenization.fulfill()
        }
        orderedExpectations.append(expectDidStartTokenization)

        if handling == .manual {
            let expectDidTokenizePaymentMethod = self.expectation(description: "Expected delegate method: didTokenizePaymentMethod")
            delegate.onDidTokenizePaymentMethod = { data, decisionHandler in
                // TODO: based on isImplementingPaymentMethodWithRequiredAction from HUC tests
                if paymentMethod.internalPaymentMethodType == .paymentCard {
                    decisionHandler(.complete())
                } else {
                    decisionHandler(.continueWithNewClientToken(MockAppState.mockResumeToken))
                }
                expectDidTokenizePaymentMethod.fulfill()
            }
            orderedExpectations.append(expectDidTokenizePaymentMethod)

            if paymentMethod.internalPaymentMethodType != .paymentCard {
                let expectUIDidShowPaymentMethod = self.expectation(description: "Expected delegate method: UIDidShowPaymentMethod")
                uiDelegate.onUIDidShowPaymentMethod = { paymentMethodType in
                    XCTAssertEqual(paymentMethodType, paymentMethod.type)
                    expectUIDidShowPaymentMethod.fulfill()
                }
                orderedExpectations.append(expectUIDidShowPaymentMethod)

                let expectDidResumeWith = self.expectation(description: "Expected delegate method: didResumeWith")
                delegate.onDidResumeWith = { resumeToken, decisionHandler in
                    // TODO: decision handler?
                    expectDidResumeWith.fulfill()
                }
                orderedExpectations.append(expectDidResumeWith)
            }
        }
        else {
            let expectDidCompleteCheckoutWithData = self.expectation(description: "Expected delegate method: didCompleteCheckoutWithData")
            delegate.onDidCompleteCheckoutWithData = { data in
                XCTAssertNotNil(data.payment)
                XCTAssertNil(data.payment!.paymentFailureReason)
                XCTAssertEqual(data.payment?.id, "mock_id")
                expectDidCompleteCheckoutWithData.fulfill()

            }
            orderedExpectations.append(expectDidCompleteCheckoutWithData)
        }

        if handling == .auto, paymentMethod.internalPaymentMethodType != .paymentCard  {
            let expectOnDismiss = self.expectation(description: "Expected delegate method: onDimiss")
            uiDelegate.onUIDidDismissPaymentMethod = {
                expectOnDismiss.fulfill()
            }
            orderedExpectations.append(expectOnDismiss)
        }

        return orderedExpectations
    }

    var clientSession: ClientSession.APIResponse? {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession
    }
}

// MARK: SDK Helpers

extension EndToEndPaymentTokenizationTests {


    private func setupApiConfiguration(paymentMethod: PrimerPaymentMethod,
                                       surchargeAmount: Int? = nil) -> PrimerAPIConfiguration {
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: surchargeAmount != nil ? [["surcharge": surchargeAmount!]] : nil,
                orderedAllowedCardNetworks: [
                    CardNetwork.visa.rawValue,
                    CardNetwork.masterCard.rawValue
                ]
            ),
            order: nil,
            customer: nil,
            testId: nil)
        let apiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: [paymentMethod])

        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration

        return apiConfiguration
    }

    private func setupMockApiClients(apiConfiguration: PrimerAPIConfiguration) {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.validateClientTokenResult = (SuccessResponse(), nil)
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (nil, NSError(domain: "dummy-network-error", code: 100)),
            (PollingResponse(status: .complete, id: "resume_token", source: "src"), nil)
        ]
        mockApiClient.tokenizePaymentMethodResult = (Mocks.primerPaymentMethodTokenData, nil)
        mockApiClient.paymentResult = (Mocks.payment, nil)
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.listCardNetworksResult = (Mocks.listCardNetworksData, nil)

        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PaymentMethodTokenizationViewModel.apiClient = mockApiClient
        TokenizationService.apiClient = mockApiClient
        PollingModule.apiClient = mockApiClient
        CreateResumePaymentService.apiClient = mockApiClient
        DefaultCardValidationService.apiClient = mockApiClient
    }

    private func setupSettings(handling: PrimerPaymentHandling) {
        let settings = PrimerSettings(paymentHandling: handling)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

    }
}
