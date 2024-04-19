//
//  HUC_TokenizationViewModelTests.swift
//  ExampleAppTests
//
//  Created by Evangelos on 3/10/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class HUC_TokenizationViewModelTests: XCTestCase {

    private var paymentCompletion: ((PrimerCheckoutData?, Error?) -> Void)?
    var availablePaymentMethodsLoadedCompletion: (([PrimerHeadlessUniversalCheckout.PaymentMethod]?, Error?) -> Void)?
    private var tokenizationCompletion: ((PrimerPaymentMethodTokenData?, Error?) -> Void)?
    private var resumeCompletion: ((String?, Error?) -> Void)?
    private var isImplementingManualPaymentFlow: Bool = false
    private var eventsCalled: [String] = []

    private var isImplementingPaymentMethodWithRequiredAction = false
    private var abortPayment = false

    override func tearDown() {
        VaultService.apiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil

        PrimerAPIConfigurationModule.apiClient = nil
        PaymentMethodTokenizationViewModel.apiClient = nil
        TokenizationService.apiClient = nil
        PollingModule.apiClient = nil
        CreateResumePaymentService.apiClient = nil

        PrimerHeadlessUniversalCheckout.current.delegate = nil
        PrimerHeadlessUniversalCheckout.current.uiDelegate = nil

        self.paymentCompletion = nil
        self.availablePaymentMethodsLoadedCompletion = nil
        self.tokenizationCompletion = nil
        self.resumeCompletion = nil
        self.isImplementingManualPaymentFlow = false
        self.isImplementingPaymentMethodWithRequiredAction = false
        self.abortPayment = false
        self.eventsCalled = []
    }

    // MARK: - HEADLESS UNIVERSAL CHECKOUT

    func test_huc_start() throws {
        let expectation = XCTestExpectation(description: "Successful HUC initialization")

        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,
                orderedAllowedCardNetworks: [
                    CardNetwork.visa.rawValue,
                    CardNetwork.masterCard.rawValue
                ]
            ),
            order: nil,
            customer: nil,
            testId: nil)
        guard let mockPrimerApiConfiguration = self.createMockApiConfiguration(clientSession: clientSession, mockPaymentMethods: [Mocks.PaymentMethods.webRedirectPaymentMethod]) else {
            XCTFail("Unable to start mock tokenization")
            return
        }

        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (mockPrimerApiConfiguration, nil)
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        PrimerHeadlessUniversalCheckout.current.start(withClientToken: MockAppState.mockClientToken, delegate: self, uiDelegate: self) { availablePaymentMethods, err in
            if let err = err {
                XCTAssert(false, "SDK failed with error \(err.localizedDescription) while it should have succeeded.")
            } else if let availablePaymentMethods = availablePaymentMethods {
                XCTAssert(availablePaymentMethods.count == mockPrimerApiConfiguration.paymentMethods?.count, "SDK should have returned the mocked payment methods.")
            } else {
                XCTAssert(false, "SDK should have returned an error or payment methods.")
            }

            expectation.fulfill()
        }

        self.availablePaymentMethodsLoadedCompletion = { availablePaymentMethods, err in
            if let err = err {
                XCTAssert(false, "SDK failed with error \(err.localizedDescription) while it should have succeeded.")
            } else if let availablePaymentMethods = availablePaymentMethods {
                XCTAssert(availablePaymentMethods.count == mockPrimerApiConfiguration.paymentMethods?.count, "SDK should have returned the mocked payment methods.")
            } else {
                XCTAssert(false, "SDK should have returned an error or payment methods.")
            }
        }

        wait(for: [expectation], timeout: 10)
    }

    // MARK: - CREATE PAYMENT

    // MARK: PAYMENT HANDLING: AUTO

    // MARK: Native UI Manager

    func test_native_ui_manager_with_auto_payment_handling_and_no_surcharge() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .auto,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: false)
    }

    func test_native_ui_manager_with_auto_payment_handling_and_surcharge() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .auto,
            isSurchargeIncluded: true,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: false)
    }

    // MARK: Raw Data Manager

    func test_raw_data_manager_with_auto_payment_handling_and_no_surcharge() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.paymentCardPaymentMethod,
            paymentHandling: .auto,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: false,
            abortPayment: false)
    }

    //    func test_raw_data_manager_with_auto_payment_handling_and_surcharge() throws {
    //        try self.assess_huc_payment_method(
    //            Mocks.PaymentMethods.paymentCardPaymentMethod,
    //            paymentHandling: .auto,
    //            isSurchargeIncluded: true,
    //            isImplementingPaymentMethodWithRequiredAction: false,
    //            abortPayment: false)
    //    }

    // MARK: PAYMENT HANDLING: MANUAL

    // MARK: Native UI Manager

    func test_native_ui_manager_with_manual_payment_handling_and_no_surcharge() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .manual,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: false)
    }

    func test_native_ui_manager_with_manual_payment_handling_and_surcharge() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .manual,
            isSurchargeIncluded: true,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: false)
    }

    // MARK: Raw Data Manager

    func test_raw_data_manager_with_manual_payment_handling_and_no_surcharge() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.paymentCardPaymentMethod,
            paymentHandling: .manual,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: false,
            abortPayment: false)
    }

    //    func test_raw_data_manager_with_manual_payment_handling_and_surcharge() throws {
    //        try self.assess_huc_payment_method(
    //            Mocks.PaymentMethods.paymentCardPaymentMethod,
    //            paymentHandling: .manual,
    //            isSurchargeIncluded: true,
    //            isImplementingPaymentMethodWithRequiredAction: true,
    //            abortPayment: false)
    //    }

    // MARK: - ABORT PAYMENT

    // MARK: PAYMENT HANDLING: AUTO

    // MARK: Native UI Manager

    func test_native_ui_manager_with_auto_payment_handling_and_no_surcharge_and_abort() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .auto,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: true)
    }

    func test_native_ui_manager_with_auto_payment_handling_and_surcharge_and_abort() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .auto,
            isSurchargeIncluded: true,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: true)
    }

    // MARK: Raw Data Manager

    func test_raw_data_manager_with_auto_payment_handling_and_no_surcharge_and_abort() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.paymentCardPaymentMethod,
            paymentHandling: .auto,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: false,
            abortPayment: true)
    }

    // MARK: PAYMENT HANDLING: MANUAL

    // MARK: Native UI Manager

    func test_native_ui_manager_with_manual_payment_handling_and_no_surcharge_and_abort() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .manual,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: true)
    }

    func test_native_ui_manager_with_manual_payment_handling_and_surcharge_and_abort() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.adyenGiroPayRedirectPaymentMethod,
            paymentHandling: .manual,
            isSurchargeIncluded: true,
            isImplementingPaymentMethodWithRequiredAction: true,
            abortPayment: true)
    }

    // MARK: Raw Data Manager

    func test_raw_data_manager_with_manual_payment_handling_and_no_surcharge_and_abort() throws {
        try self.assess_huc_payment_method(
            Mocks.PaymentMethods.paymentCardPaymentMethod,
            paymentHandling: .manual,
            isSurchargeIncluded: false,
            isImplementingPaymentMethodWithRequiredAction: false,
            abortPayment: true)
    }

    // MARK: - HELPERS

    func assess_huc_payment_method(
        _ paymentMethod: PrimerPaymentMethod,
        paymentHandling: PrimerPaymentHandling,
        isSurchargeIncluded: Bool,
        isImplementingPaymentMethodWithRequiredAction: Bool,
        abortPayment: Bool
    ) throws {
        let expectation = XCTestExpectation(description: "Successful HUC initialization")

        self.isImplementingManualPaymentFlow = (paymentHandling == .manual)
        self.isImplementingPaymentMethodWithRequiredAction = isImplementingPaymentMethodWithRequiredAction
        self.abortPayment = abortPayment

        let settings = PrimerSettings(paymentHandling: paymentHandling)
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: isSurchargeIncluded ? [["surcharge": 99]] : nil,
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

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.validateClientTokenResult = (SuccessResponse(success: true), nil)
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

        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.uiDelegate = self

        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: {$0.type == paymentMethod.type}) else {
            XCTAssert(false, "Failed to find payment method \(paymentMethod.type) in mocked API configuration response")
            return
        }

        // Hack to override not having image URLs to download PM logos when mocking
        paymentMethod.baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)

        if self.isImplementingManualPaymentFlow {
            self.tokenizationCompletion = { paymentMethodTokenData, err in
                if let err = err {
                    XCTAssert(false, "SDK failed with error \(err.localizedDescription) while it should have succeeded.")
                } else if paymentMethodTokenData != nil, !isImplementingPaymentMethodWithRequiredAction, !isSurchargeIncluded {
                    XCTAssert(self.eventsCalled.count == 4, "4 events should have been called.")
                    XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                    XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                    XCTAssert(self.eventsCalled[2] == "primerHeadlessUniversalCheckoutTokenizationDidStart", "'\(self.eventsCalled[2])' called instead if 'primerHeadlessUniversalCheckoutTokenizationDidStart'.")
                    XCTAssert(self.eventsCalled[3] == "primerHeadlessUniversalCheckoutDidTokenizePaymentMethod", "'\(self.eventsCalled[3])' called instead if 'primerHeadlessUniversalCheckoutDidTokenizePaymentMethod'.")
                } else if paymentMethodTokenData == nil {
                    XCTAssert(false, "SDK should have returned an error or payment methods.")
                }
                if !isImplementingPaymentMethodWithRequiredAction, !isSurchargeIncluded {
                    expectation.fulfill()
                }
            }

            self.resumeCompletion = { resumeToken, err in
                if let err = err {
                    XCTFail("SDK failed with error \(err.localizedDescription) while it should have succeeded.")

                } else if let resumeToken = resumeToken {
                    XCTAssert(resumeToken == "resume_token", "Successfully called the resume handler")

                    if !isSurchargeIncluded {
                        XCTAssert(self.eventsCalled.count == 6, "6 events should have been called.")
                        XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                        XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                        XCTAssert(self.eventsCalled[2] == "primerHeadlessUniversalCheckoutTokenizationDidStart", "'\(self.eventsCalled[2])' called instead if 'primerHeadlessUniversalCheckoutTokenizationDidStart'.")
                        XCTAssert(self.eventsCalled[3] == "primerHeadlessUniversalCheckoutDidTokenizePaymentMethod", "'\(self.eventsCalled[3])' called instead if 'primerHeadlessUniversalCheckoutDidTokenizePaymentMethod'.")
                        XCTAssert(self.eventsCalled[4] == "primerHeadlessUniversalCheckoutPaymentMethodDidShow", "'\(self.eventsCalled[4])' called instead if 'primerHeadlessUniversalCheckoutPaymentMethodDidShow'.")
                        XCTAssert(self.eventsCalled[5] == "primerHeadlessUniversalCheckoutDidResumeWith", "'\(self.eventsCalled[5])' called instead if 'primerHeadlessUniversalCheckoutDidResumeWith'.")

                    } else {
                        print(self.eventsCalled)
                        XCTAssert(self.eventsCalled.count == 8, "8 events should have been called.")
                        XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                        XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutClientSessionWillUpdate", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutClientSessionWillUpdate'.")
                        XCTAssert(self.eventsCalled[2] == "primerHeadlessUniversalCheckoutClientSessionDidUpdate", "'\(self.eventsCalled[2])' called instead if 'primerHeadlessUniversalCheckoutClientSessionDidUpdate'.")
                        XCTAssert(self.eventsCalled[3] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[3])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                        XCTAssert(self.eventsCalled[4] == "primerHeadlessUniversalCheckoutTokenizationDidStart", "'\(self.eventsCalled[4])' called instead if 'primerHeadlessUniversalCheckoutTokenizationDidStart'.")
                        XCTAssert(self.eventsCalled[5] == "primerHeadlessUniversalCheckoutDidTokenizePaymentMethod", "'\(self.eventsCalled[5])' called instead if 'primerHeadlessUniversalCheckoutDidTokenizePaymentMethod'.")
                        XCTAssert(self.eventsCalled[6] == "primerHeadlessUniversalCheckoutPaymentMethodDidShow", "'\(self.eventsCalled[6])' called instead if 'primerHeadlessUniversalCheckoutPaymentMethodDidShow'.")
                        XCTAssert(self.eventsCalled[7] == "primerHeadlessUniversalCheckoutDidResumeWith", "'\(self.eventsCalled[7])' called instead if 'primerHeadlessUniversalCheckoutDidResumeWith'.")
                    }

                } else {
                    XCTAssert(false, "SDK should have returned an error or resume token.")
                }

                expectation.fulfill()
            }

        } else {
            self.paymentCompletion = { _, _ in
                if isSurchargeIncluded {
                    print(self.eventsCalled)
                    XCTAssert(self.eventsCalled.count == 6, "6 events should have been called.")
                    XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                    XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutClientSessionWillUpdate", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutClientSessionWillUpdate'.")
                    XCTAssert(self.eventsCalled[2] == "primerHeadlessUniversalCheckoutClientSessionDidUpdate", "'\(self.eventsCalled[2])' called instead if 'primerHeadlessUniversalCheckoutClientSessionDidUpdate'.")
                    XCTAssert(self.eventsCalled[3] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[3])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                    XCTAssert(self.eventsCalled[4] == "primerHeadlessUniversalCheckoutTokenizationDidStart", "'\(self.eventsCalled[4])' called instead if 'primerHeadlessUniversalCheckoutTokenizationDidStart'.")
                    XCTAssert(self.eventsCalled[5] == "primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData", "'\(self.eventsCalled[5])' called instead if 'primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData'.")

                } else {
                    XCTAssert(self.eventsCalled.count == 4, "4 events should have been called.")
                    XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                    XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                    XCTAssert(self.eventsCalled[2] == "primerHeadlessUniversalCheckoutTokenizationDidStart", "'\(self.eventsCalled[2])' called instead if 'primerHeadlessUniversalCheckoutTokenizationDidStart'.")
                    XCTAssert(self.eventsCalled[3] == "primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData", "'\(self.eventsCalled[3])' called instead if 'primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData'.")
                }

                expectation.fulfill()
            }
        }

        if self.abortPayment {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print(self.eventsCalled)

                if isSurchargeIncluded {
                    XCTAssert(self.eventsCalled.count == 6, "6 events should have been called.")
                    XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                    XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutClientSessionWillUpdate", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutClientSessionWillUpdate'.")
                    XCTAssert(self.eventsCalled[2] == "primerHeadlessUniversalCheckoutClientSessionDidUpdate", "'\(self.eventsCalled[2])' called instead if 'primerHeadlessUniversalCheckoutClientSessionDidUpdate'.")
                    XCTAssert(self.eventsCalled[3] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[3])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                    XCTAssert(self.eventsCalled[4] == "primerHeadlessUniversalCheckoutClientSessionWillUpdate", "'\(self.eventsCalled[4])' called instead if 'primerHeadlessUniversalCheckoutClientSessionWillUpdate'.")
                    XCTAssert(self.eventsCalled[5] == "primerHeadlessUniversalCheckoutClientSessionDidUpdate", "'\(self.eventsCalled[5])' called instead if 'primerHeadlessUniversalCheckoutClientSessionDidUpdate'.")

                } else {
                    XCTAssert(self.eventsCalled.count == 2, "2 events should have been called.")
                    XCTAssert(self.eventsCalled[0] == "primerHeadlessUniversalCheckoutPreparationDidStart", "'\(self.eventsCalled[0])' called instead if 'primerHeadlessUniversalCheckoutPreparationDidStart'.")
                    XCTAssert(self.eventsCalled[1] == "primerHeadlessUniversalCheckoutWillCreatePaymentWithData", "'\(self.eventsCalled[1])' called instead if 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData'.")
                }

                expectation.fulfill()
            }
        }

        if paymentMethod.paymentMethodManagerCategories?.contains(.nativeUI) == true {
            do {
                let paymentMethodNativeUIManager = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: paymentMethod.type)
                try paymentMethodNativeUIManager.showPaymentMethod(intent: .checkout)

            } catch {
                XCTAssert(false, error.localizedDescription)
                expectation.fulfill()
            }

        } else if paymentMethod.paymentMethodManagerCategories?.contains(.rawData) == true {
            do {
                let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethod.type, delegate: self)

                let rawCardData = PrimerCardData(
                    cardNumber: "4111 1111 1111 1111",
                    expiryDate: "03/2030",
                    cvv: "123",
                    cardholderName: "John Smith")

                rawDataManager.rawData = rawCardData

                rawDataManager.submit()

            } catch {
                XCTAssert(false, error.localizedDescription)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 60)
    }
}

// MARK: - PRIMER HEADLESS UNIVERSAL CHECKOUT DELEGATES

extension HUC_TokenizationViewModelTests: PrimerHeadlessUniversalCheckoutDelegate {

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods")
        self.availablePaymentMethodsLoadedCompletion?(paymentMethods, nil)
    }

    func primerHeadlessUniversalCheckoutWillUpdateClientSession() {
        eventsCalled.append("primerHeadlessUniversalCheckoutClientSessionWillUpdate")
    }

    func primerHeadlessUniversalCheckoutDidUpdateClientSession(_ clientSession: PrimerClientSession) {
        eventsCalled.append("primerHeadlessUniversalCheckoutClientSessionDidUpdate")
    }

    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo")
    }

    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        eventsCalled.append("primerHeadlessUniversalCheckoutWillCreatePaymentWithData")

        if self.abortPayment {
            decisionHandler(.abortPaymentCreation())
        } else {
            decisionHandler(.continuePaymentCreation())
        }
    }

    func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        eventsCalled.append("primerHeadlessUniversalCheckoutTokenizationDidStart")
    }

    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidTokenizePaymentMethod")

        self.tokenizationCompletion?(paymentMethodTokenData, nil)

        let testClientToken = """

eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE2NjQ5NTM1OTkwLCJhY2Nlc3NUb2tlbiI6ImIwY2E0NTFhLTBmYmItNGZlYS1hY2UwLTgxMDYwNGQ4OTBkYSIsImFuYWx5dGljc1VybCI6Imh0dHBzOi8vYW5hbHl0aWNzLmFwaS5zYW5kYm94LmNvcmUucHJpbWVyLmlvL21peHBhbmVsIiwiYW5hbHl0aWNzVXJsVjIiOiJodHRwczovL2FuYWx5dGljcy5zYW5kYm94LmRhdGEucHJpbWVyLmlvL2NoZWNrb3V0L3RyYWNrIiwiaW50ZW50IjoiQURZRU5fR0lST1BBWV9SRURJUkVDVElPTiIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwic3RhdHVzVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vcmVzdW1lLXRva2Vucy9lOTM3ZDQyMS0zYzE2LTRjMmUtYTBjOC01OGQxY2RhNWM0NmUiLCJyZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdC5hZHllbi5jb20vaHBwL2NoZWNrb3V0LnNodG1sP3U9c2tpcERldGFpbHMmcD1lSnlOVTl0eW16QVEtUnJ6QmdQaVluamd3UVdTdUUwY2g5aE9waThlV2F4dDFTQXhrbkROMzJjaGwyblR6clF6ekk3WWN5U2RQYnVpYlZ0elJnMlhZaTcyMG9HTEFTVm92YXlwMlV2VnpJV0JnNkpHcW5TcGVBUEtvdi1Zc2FBTi1DOTNBMG9qbGhKcnA2aW9NbGxCZXVCS3RyUzNXS2NVQ05hUHlXSmRXbmdnTzFKaFpvekpUcGkzTzc3dVZxQk5rZDNmZlJEZU5lUEpqdWxiU0xPYkl2dDJ2MTV0cjR0RlVjNnp2ekxQYjFxaTZRZGN3aDRHRFpCeXFiZFNWYUMydk5xRzljLTc5bGJ0ZnVHWlRvbWNHcHBtRCpGeUdUd0gqVk5PbmhZeCplQTg4a042TFNET29KSDVobmpWNWZRZ3dwc3YtV0puaXRYc0txZzhsWWlZcTRmbkpTSHJpWjliNkVJRFdHOHpsdXZGcnFWZ2NJV0xReWFGVVpTWnRDeXlkVm5PRjllSXRVQ05MWVZ0MEJmWm1YUlBhdzJZMSp2eU5qMGEwKnFKUDV1UUstellFZGdKT2ZvbzJ4YVViZEJEaDFZOUNJZko1azhDWmpTb00yZWdjYmw4RlRZWHlFVXhKVlFjbFJsRXpoNkdXakpzOFN2bkRzeFJWaFAtNmxQM3NMN1AtWnVRU0kxR29seUVYd1dUY0pBY0RxSXgwSlk3R2dkbEp5OU9PMjUzdUJ3UnJMSnJ3RGJ5QkVLUEdVajhhUlVRei1hWkY5a0JJMkJUbDhWMkdGY2VxMmpJZ2doR0loYlIxbUNHSDMqNFlYdUNmbGpueVg0S1BtR0pIZTg4WmdmVXhWVTFCWnZSTVBKZFZzVlRCcFlHUFl6Tmh0YTg0cVpQaVV1STdibTJHNnpjR1AxMkl3eCo4dDE2YzNJWXVhRnp3NmdWZVBYZ0M3eUR2dzJjelRwdEpPSzJtblcxS2ZYUjBpY3V4dmZRZGp2blRKeVllSkVmVENNdkNYMHZJYjZUZTlxZkMqa2EqWGh3Tnp5QTQ5YmRlLVVxbi1QTE9lSWJNZTEtblBmSldwcmlCY3BiWlBRIn0.UJnuMt3yT7uuUbDbRMKsP9FnTW89yRPL-z4G2dikpr8
"""

        if isImplementingManualPaymentFlow {
            if self.isImplementingPaymentMethodWithRequiredAction {
                decisionHandler(.continueWithNewClientToken(testClientToken))
            } else {
                decisionHandler(.complete())
            }
        }
    }

    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidResumeWith")
        self.resumeCompletion?(resumeToken, nil)
    }

    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData")
        self.paymentCompletion?(data, nil)
    }

    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo")
    }

    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        eventsCalled.append("primerHeadlessUniversalCheckoutDidFail")
    }
}

extension HUC_TokenizationViewModelTests: PrimerHeadlessUniversalCheckoutUIDelegate {

    func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) {
        eventsCalled.append("primerHeadlessUniversalCheckoutPreparationDidStart")
    }

    func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) {
        eventsCalled.append("primerHeadlessUniversalCheckoutPaymentMethodDidShow")
    }
}

extension HUC_TokenizationViewModelTests: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?) {

    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {

    }
}

extension HUC_TokenizationViewModelTests: TokenizationTestDelegate {
    func cleanup() {
        self.paymentCompletion = nil
        self.availablePaymentMethodsLoadedCompletion = nil
        self.tokenizationCompletion = nil
        self.resumeCompletion = nil
        self.isImplementingManualPaymentFlow = false
        self.isImplementingPaymentMethodWithRequiredAction = false
        self.abortPayment = false
        self.eventsCalled = []
    }
}
