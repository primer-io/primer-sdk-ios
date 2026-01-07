//
//  HeadlessUniversalCheckoutManualTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class HeadlessUniversalCheckoutManualTests: XCTestCase {
    private let nativePaymentMethod = Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod
    private let rawDataPaymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod
    private let timeout = 10.0

    private var delegate: MockPrimerHeadlessUniversalCheckoutDelegate!
    private var rawDataManagerDelegate: MockPrimerHeadlessUniversalCheckoutRawDataManagerDelegate!
    private var uiDelegate: MockPrimerHeadlessUniversalCheckoutUIDelegate!
    private var clientSession: ClientSession.APIResponse? {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession
    }

    override func setUpWithError() throws {
        let settings = PrimerSettings(paymentHandling: .manual)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        delegate.strictMode = true
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        uiDelegate.strictMode = true
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        rawDataManagerDelegate = MockPrimerHeadlessUniversalCheckoutRawDataManagerDelegate()

        nativePaymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        rawDataPaymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
    }

    override func tearDownWithError() throws {
        delegate = nil
        uiDelegate = nil
        rawDataManagerDelegate = nil

        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil

        PrimerHeadlessUniversalCheckout.current.delegate = nil
        PrimerHeadlessUniversalCheckout.current.uiDelegate = nil

        PrimerAPIConfigurationModule.apiClient = nil
        PollingModule.apiClient = nil
        
        let settings = PrimerSettings(paymentHandling: .auto)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    // MARK: NativeUIManager Tests

    func testNativeUIManager_presentAdyenGiroPay_withoutSurcharge() throws {
        let apiConfiguration = setupApiConfiguration(paymentMethod: nativePaymentMethod)
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: nativePaymentMethod)
        try presentNativeUIManager(paymentMethod: nativePaymentMethod, expecting: orderedExpectations)
    }

    func testNativeUIManager_presentAdyenGiroPay_withSurcharge() throws {
        let surchargeAmount = 99
        let apiConfiguration = setupApiConfiguration(paymentMethod: nativePaymentMethod, surchargeAmount: surchargeAmount)
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: nativePaymentMethod, surchargeAmount: surchargeAmount)
        try presentNativeUIManager(paymentMethod: nativePaymentMethod, expecting: orderedExpectations)
    }

    // MARK: RawDataManager Tests

    func ttttestRawDataManager_presentPaymentCard_withoutSurcharge() throws {
        let paymentMethod = Mocks.PaymentMethods.paymentCardPaymentMethod
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        let apiConfiguration = setupApiConfiguration(paymentMethod: paymentMethod)
        setupMockApiClients(apiConfiguration: apiConfiguration)

        let orderedExpectations = expectationsForDelegates(paymentMethod: paymentMethod)
        try submitWithRawDataManager(paymentMethod: paymentMethod, expecting: orderedExpectations)
    }
}

extension HeadlessUniversalCheckoutManualTests {
    private func setupApiConfiguration(paymentMethod: PrimerPaymentMethod, surchargeAmount: Int? = nil) -> PrimerAPIConfiguration {
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: surchargeAmount != nil ? [["surcharge": surchargeAmount!]] : nil,
                orderedAllowedCardNetworks: [
                    CardNetwork.visa.rawValue,
                    CardNetwork.masterCard.rawValue
                ],
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let apiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: [paymentMethod]
        )

        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        AppState.current.apiConfiguration = apiConfiguration
        AppState.current.clientToken = MockAppState.mockClientToken
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
        PollingModule.apiClient = mockApiClient
    }

    private func expectationsForDelegates(paymentMethod: PrimerPaymentMethod, shouldAbort: Bool = false,
                                          surchargeAmount: Int? = nil) -> [XCTestExpectation] {
        var orderedExpectations: [XCTestExpectation] = []

        uiDelegate.onUIDidDismissPaymentMethod = {}

        let expectPreparationDidStart = self.expectation(description: "Expected UI delegate method: preparationDidStart")
        uiDelegate.onUIDidStartPreparation = { paymentMethodType in
            XCTAssertEqual(paymentMethodType, paymentMethod.type)
            expectPreparationDidStart.fulfill()
        }
        orderedExpectations.append(expectPreparationDidStart)

        if let surchargeAmount {
            let expectClientSessionWillUpdate = self.expectation(description: "Expected delegate method: willUpdateClientSession")
            delegate.onWillUpdateClientSession = {
                expectClientSessionWillUpdate.fulfill()
            }
            orderedExpectations.append(expectClientSessionWillUpdate)

            let expectClientSessionDidUpdate = self.expectation(description: "Expected delegate method: didUpdateClientSession")
            delegate.onDidUpdateClientSession = { _ in
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

            return orderedExpectations
        }

        let expectDidStartTokenization = self.expectation(description: "Expected delegate method: didStartTokenization")
        delegate.onDidStartTokenization = { paymentMethodType in
            XCTAssertEqual(paymentMethodType, paymentMethod.type)
            expectDidStartTokenization.fulfill()
        }
        orderedExpectations.append(expectDidStartTokenization)

        let expectDidTokenizePaymentMethod = self.expectation(description: "Expected delegate method: didTokenizePaymentMethod")
        delegate.onDidTokenizePaymentMethod = { _, decisionHandler in
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
            delegate.onDidResumeWith = { _, decisionHandler in
                // TODO: decision handler?
                expectDidResumeWith.fulfill()
                decisionHandler(.complete())
            }
            orderedExpectations.append(expectDidResumeWith)
        }

        delegate.onDidFail = { _ in }

        return orderedExpectations
    }

    private func presentNativeUIManager(paymentMethod: PrimerPaymentMethod, expecting orderedExpectations: [XCTestExpectation]) throws {
        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: { $0.type == paymentMethod.type })
        else {
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

        let expectUIDidDismissPaymentMethod = self.expectation(description: "Expected UI delegate method: UIDidDismissPaymentMethod")
        uiDelegate.onUIDidDismissPaymentMethod = {
            expectUIDidDismissPaymentMethod.fulfill()
        }

        PrimerInternal.shared.dismiss()
        wait(for: [expectUIDidDismissPaymentMethod], timeout: 5.0)
    }

    private func submitWithRawDataManager(paymentMethod: PrimerPaymentMethod, expecting orderedExpectations: [XCTestExpectation]) throws {
        do {
            let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethod.type,
                                                                                    delegate: rawDataManagerDelegate)

            let mockApiClient = PrimerAPIConfigurationModule.apiClient!

            rawDataManager.tokenizationService = TokenizationService(apiClient: mockApiClient)
            rawDataManager.createResumePaymentService = CreateResumePaymentService(paymentMethodType: paymentMethod.type,
                                                                                   apiClient: mockApiClient)

            let rawDataTokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: paymentMethod.type)
            rawDataTokenizationBuilder.rawDataManager = rawDataManager
            rawDataTokenizationBuilder.cardValidationService = DefaultCardValidationService(rawDataManager: rawDataManager,
                                                                                            apiClient: mockApiClient)
            rawDataManager.rawDataTokenizationBuilder = rawDataTokenizationBuilder

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
}
