//
//  TokenizationViewModelTests.swift
//  ExampleAppTests
//
//  Created by Evangelos on 23/9/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class DropInUI_TokenizationViewModelTests: XCTestCase {
    
    private var paymentCompletion: ((PrimerCheckoutData?, Error?) -> Void)?
    private var tokenizationCompletion: ((PrimerPaymentMethodTokenData?, Error?) -> Void)?
    private var dismissalCompletion: (() -> Void)?
    private var isImplementingManualPaymentFlow: Bool = false
    
    private var eventsCalled: [String] = []
    
    let webRedirectPaymentMethod = PrimerPaymentMethod(
        id: "mock_payment_method",
        implementationType: .webRedirect,
        type: "MOCK_WEB_REDIRECT_PAYMENT_METHOD",
        name: "Mock Payment Method",
        processorConfigId: "mock_processor_config_id",
        surcharge: 99,
        options: nil,
        displayMetadata: nil)
    let mockPaymentMethodTokenData = PrimerPaymentMethodTokenData(
        analyticsId: "mock_analytics_id",
        id: "mock_payment_method_token_data_id",
        isVaulted: false,
        isAlreadyVaulted: false,
        paymentInstrumentType: .unknown,
        paymentMethodType: "MOCK_WEB_REDIRECT_PAYMENT_METHOD",
        paymentInstrumentData: nil,
        threeDSecureAuthentication: nil,
        token: "mock_payment_method_token",
        tokenType: .singleUse,
        vaultData: nil)
    let mockPayment = Response.Body.Payment(
        id: "mock_id",
        paymentId: "mock_payment_id",
        amount: 1000,
        currencyCode: "EUR",
        customer: nil,
        customerId: "mock_customer_id",
        dateStr: nil,
        order: nil,
        orderId: nil,
        requiredAction: nil,
        status: .settled,
        paymentFailureReason: nil)
    let mockPrimerAPIConfiguration = PrimerAPIConfiguration(
        coreUrl: "https://core.primer.io",
        pciUrl: "https://pci.primer.io",
        clientSession: nil,
        paymentMethods: [],
        keys: nil,
        checkoutModules: nil)
    
    func test_web_redirect_auto_payment() throws {
        let expectation = XCTestExpectation(description: "UC Web Redirect | Checkout with auto flow | Success")
        
        self.resetTestingEnvironment()
        
        let awaitDismissal = true
        
        let settings = PrimerSettings(
            paymentHandling: .auto,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io"),
            uiOptions: awaitDismissal ? PrimerUIOptions(isInitScreenEnabled: false, isSuccessScreenEnabled: false, isErrorScreenEnabled: false, theme: nil) : nil
        )
        
        Primer.shared.configure(settings: settings, delegate: self)
        
        PrimerInternal.shared.intent = .checkout
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        
        let apiClient = MockPrimerAPIClient()
        apiClient.tokenizePaymentMethodResult = (mockPaymentMethodTokenData, nil)
        apiClient.paymentResult = (mockPayment, nil)
        apiClient.fetchConfigurationWithActionsResult = (mockPrimerAPIConfiguration, nil)
        
        let tokenizationViewModel = WebRedirectPaymentMethodTokenizationViewModel(config: webRedirectPaymentMethod, apiClient: apiClient)
        tokenizationViewModel.start()
        
        self.paymentCompletion = { checkoutData, err in
            if awaitDismissal {
                self.dismissalCompletion = {
                    XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "First callback event should be 'primerClientSessionWillUpdate'")
                    XCTAssert(self.eventsCalled[1] == "primerWillCreatePaymentWithData", "First callback event should be 'primerWillCreatePaymentWithData'")
                    XCTAssert(self.eventsCalled[2] == "primerDidCompleteCheckoutWithData", "First callback event should be 'primerDidCompleteCheckoutWithData'")
                    XCTAssert(self.eventsCalled[3] == "primerDidDismiss", "First callback event should be 'primerDidDismiss'")
                    expectation.fulfill()
                }
            }
            
            if let err = err {
                XCTAssert(false, "Failed with error \(err.localizedDescription) when it should have succeeded.")
            } else if let checkoutData = checkoutData {
                if checkoutData.payment?.id == self.mockPayment.id {
                    XCTAssert(true, "All good!")
                    if !awaitDismissal {
                        XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "First callback event should be 'primerClientSessionWillUpdate'")
                        XCTAssert(self.eventsCalled[1] == "primerWillCreatePaymentWithData", "First callback event should be 'primerWillCreatePaymentWithData'")
                        XCTAssert(self.eventsCalled[2] == "primerDidCompleteCheckoutWithData", "First callback event should be 'primerDidCompleteCheckoutWithData'")
                        expectation.fulfill()
                    }
                } else {
                    XCTAssert(false, "Payment id should be the one provided on the mocked API client.")
                }
            } else {
                XCTAssert(false, "Should always receive checkout data or error")
            }
        }
        
        wait(for: [expectation], timeout: 60)
    }
    
    func test_web_redirect_manual_payment() throws {
        let expectation = XCTestExpectation(description: "UC Web Redirect | Checkout with auto flow | Success")
        
        self.resetTestingEnvironment()
        
        let awaitDismissal = false
        
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io"),
            uiOptions: awaitDismissal ? PrimerUIOptions(isInitScreenEnabled: false, isSuccessScreenEnabled: false, isErrorScreenEnabled: false, theme: nil) : nil
        )
        self.isImplementingManualPaymentFlow = true
        
        Primer.shared.configure(settings: settings, delegate: self)
        
        PrimerInternal.shared.intent = .checkout
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        
        let apiClient = MockPrimerAPIClient()
        apiClient.tokenizePaymentMethodResult = (mockPaymentMethodTokenData, nil)
        apiClient.paymentResult = (mockPayment, nil)
        apiClient.fetchConfigurationWithActionsResult = (mockPrimerAPIConfiguration, nil)
        
        let tokenizationViewModel = WebRedirectPaymentMethodTokenizationViewModel(config: webRedirectPaymentMethod, apiClient: apiClient)
        tokenizationViewModel.start()
        
        self.paymentCompletion = { checkoutData, err in
            XCTAssert(false, "Should not have been called")
        }
        
        self.tokenizationCompletion = { paymentMethodTokenData, err in
            if awaitDismissal {
                self.dismissalCompletion = {
                    XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "First callback event should be 'primerClientSessionWillUpdate'")
                    XCTAssert(self.eventsCalled[1] == "primerWillCreatePaymentWithData", "First callback event should be 'primerWillCreatePaymentWithData'")
                    XCTAssert(self.eventsCalled[2] == "primerDidTokenizePaymentMethod", "First callback event should be 'primerDidCompleteCheckoutWithData'")
                    XCTAssert(self.eventsCalled[3] == "primerDidDismiss", "First callback event should be 'primerDidDismiss'")
                    expectation.fulfill()
                }
            }
            
            if let err = err {
                XCTAssert(false, "Failed with error \(err.localizedDescription) when it should have succeeded.")
            } else if let paymentMethodTokenData = paymentMethodTokenData {
                XCTAssert(true, "All good!")
                if !awaitDismissal {
                    if paymentMethodTokenData.id == self.mockPaymentMethodTokenData.id {
                        XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "First callback event should be 'primerClientSessionWillUpdate'")
                        XCTAssert(self.eventsCalled[1] == "primerWillCreatePaymentWithData", "First callback event should be 'primerWillCreatePaymentWithData'")
                        XCTAssert(self.eventsCalled[2] == "primerDidTokenizePaymentMethod", "First callback event should be 'primerDidCompleteCheckoutWithData'")
                        expectation.fulfill()
                    } else {
                        XCTAssert(false, "Payment method token id should be the one provided on the mocked API client.")
                    }
                }
                
            } else {
                XCTAssert(false, "Should always receive checkout data or error")
            }
        }
        
        wait(for: [expectation], timeout: 60)
    }
    
    func test_web_redirect_auto_vaulting() throws {
        let expectation = XCTestExpectation(description: "UC Web Redirect | Checkout with auto flow | Success")
        
        self.resetTestingEnvironment()
        
        let awaitDismissal = false
        
        let settings = PrimerSettings(
            paymentHandling: .auto,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io"),
            uiOptions: awaitDismissal ? PrimerUIOptions(isInitScreenEnabled: false, isSuccessScreenEnabled: false, isErrorScreenEnabled: false, theme: nil) : nil
        )
        
        Primer.shared.configure(settings: settings, delegate: self)
        
        PrimerInternal.shared.intent = .vault
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        
        let apiClient = MockPrimerAPIClient()
        apiClient.tokenizePaymentMethodResult = (mockPaymentMethodTokenData, nil)
        
        let tokenizationViewModel = WebRedirectPaymentMethodTokenizationViewModel(config: webRedirectPaymentMethod, apiClient: apiClient)
        tokenizationViewModel.start()
        
        self.paymentCompletion = { checkoutData, err in
            XCTAssert(false, "Should not have been called")
        }
        
        self.tokenizationCompletion = { paymentMethodTokenData, err in
            if awaitDismissal {
                self.dismissalCompletion = {
                    XCTAssert(self.eventsCalled[0] == "primerDidTokenizePaymentMethod", "First callback event should be 'primerDidTokenizePaymentMethod'")
                    XCTAssert(self.eventsCalled[1] == "primerDidDismiss", "First callback event should be 'primerDidDismiss'")
                    expectation.fulfill()
                }
            }
            
            if let err = err {
                XCTAssert(false, "Failed with error \(err.localizedDescription) when it should have succeeded.")
            } else if let paymentMethodTokenData = paymentMethodTokenData {
                XCTAssert(true, "All good!")
                if !awaitDismissal {
                    if paymentMethodTokenData.id == self.mockPaymentMethodTokenData.id {
                        XCTAssert(self.eventsCalled[0] == "primerDidTokenizePaymentMethod", "First callback event should be 'primerDidTokenizePaymentMethod'")
                        expectation.fulfill()
                    } else {
                        XCTAssert(false, "Payment method token id should be the one provided on the mocked API client.")
                    }
                }
                
            } else {
                XCTAssert(false, "Should always receive checkout data or error")
            }
        }
        
        wait(for: [expectation], timeout: 60)
    }
    
    func resetTestingEnvironment() {
        self.paymentCompletion = nil
        self.tokenizationCompletion = nil
        self.eventsCalled = []
    }
}

extension DropInUI_TokenizationViewModelTests: PrimerDelegate {
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        self.eventsCalled.append("primerDidCompleteCheckoutWithData")
        self.paymentCompletion?(data, nil)
    }
    
    func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        self.eventsCalled.append("primerDidTokenizePaymentMethod")
        self.tokenizationCompletion?(paymentMethodTokenData, nil)
        
        if isImplementingManualPaymentFlow {
            decisionHandler(.succeed())
        }
    }
    
    func primerClientSessionWillUpdate() {
        self.eventsCalled.append("primerClientSessionWillUpdate")
    }
    
    func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        self.eventsCalled.append("primerClientSessionDidUpdate")
    }
    
    func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        self.eventsCalled.append("primerWillCreatePaymentWithData")
        decisionHandler(.continuePaymentCreation())
    }
    
    func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        self.eventsCalled.append("primerDidEnterResumePendingWithPaymentAdditionalInfo")
    }
    
    func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        self.eventsCalled.append("primerDidResumeWith")
    }
    
    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        self.eventsCalled.append("primerDidFailWithError")
        self.paymentCompletion?(nil, error)
        self.tokenizationCompletion?(nil, error)
    }
    
    func primerDidDismiss() {
        self.eventsCalled.append("primerDidDismiss")
        self.dismissalCompletion?()
    }
}

#endif
