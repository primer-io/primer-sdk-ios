//
//  DropInUI_TokenizationViewModelTests.swift
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
    
    // MARK: - UNIVERSAL CHECKOUT
    
    // MARK: Auto Payment Handling
    
    func test_checkout_with_web_redirect_auto_payment_handling_include_surcharge_and_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .auto, isAwaitingSDKDismiss: true, isSurchargeIncluded: true)
    }
    
    func test_checkout_with_web_redirect_auto_payment_handling_do_not_include_surcharge_and_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .auto, isAwaitingSDKDismiss: true, isSurchargeIncluded: false)
    }
    
    func test_checkout_with_web_redirect_auto_payment_handling_include_surcharge_and_do_not_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .auto, isAwaitingSDKDismiss: false, isSurchargeIncluded: true)
    }
    
    func test_checkout_with_web_redirect_auto_payment_handling_do_not_include_surcharge_and_do_not_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .auto, isAwaitingSDKDismiss: false, isSurchargeIncluded: false)
    }
    
    // MARK: Manual Payment Handling
    
    func test_checkout_with_web_redirect_manual_payment_handling_include_surcharge_and_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .manual, isAwaitingSDKDismiss: true, isSurchargeIncluded: true)
    }
    
    func test_checkout_with_web_redirect_manual_payment_handling_do_not_include_surcharge_and_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .manual, isAwaitingSDKDismiss: true, isSurchargeIncluded: false)
    }
    
    func test_checkout_with_web_redirect_manual_payment_handling_include_surcharge_and_do_not_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .manual, isAwaitingSDKDismiss: false, isSurchargeIncluded: true)
    }
    
    func test_checkout_with_web_redirect_manual_payment_handling_do_not_include_surcharge_and_do_not_await_sdk_dismiss() throws {
        try self.assess_checkout_with_web_redirect(intent: .checkout, paymentHandling: .manual, isAwaitingSDKDismiss: false, isSurchargeIncluded: false)
    }
    
    
    
    // MARK: - VAULT MANAGER
    
    
    func assess_checkout_with_web_redirect(
        intent: PrimerSessionIntent,
        paymentHandling: PrimerPaymentHandling,
        isAwaitingSDKDismiss: Bool,
        isSurchargeIncluded: Bool
    ) throws {
        let expectation = XCTestExpectation(description: "Successful UC Web Redirect Payment Method | Payment flow: \(paymentHandling) | Awaits SDK dismiss: \(isAwaitingSDKDismiss)")
        
        self.resetTestingEnvironment()
                
        let settings = PrimerSettings(
            paymentHandling: paymentHandling,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io"),
            uiOptions: isAwaitingSDKDismiss ? PrimerUIOptions(isInitScreenEnabled: false, isSuccessScreenEnabled: false, isErrorScreenEnabled: false, theme: nil) : nil
        )
        
        self.isImplementingManualPaymentFlow = paymentHandling == .manual
                
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "mock_client_session_id",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: isSurchargeIncluded ? [["surcharge": 99]] : nil),
            order: nil,
            customer: nil)
        let apiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: [Mocks.PaymentMethods.webRedirectPaymentMethod])
        
                
        PrimerInternal.shared.configure(settings: settings, delegate: self)
        PrimerInternal.shared.intent = intent
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
        
        let apiClient = MockPrimerAPIClient()
        apiClient.tokenizePaymentMethodResult = (Mocks.primerPaymentMethodTokenData, nil)
        apiClient.paymentResult = (Mocks.payment, nil)
        apiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        
        let tokenizationViewModel = WebRedirectPaymentMethodTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod, apiClient: apiClient)
        tokenizationViewModel.start()
        
        if isAwaitingSDKDismiss {
            self.dismissalCompletion = {
                switch paymentHandling {
                case .auto:
                    if isSurchargeIncluded {
                        XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "Callback event should be 'primerClientSessionWillUpdate' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                        XCTAssert(self.eventsCalled[1] == "primerClientSessionDidUpdate", "Callback event should be 'primerClientSessionDidUpdate' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                        XCTAssert(self.eventsCalled[2] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 2 ? self.eventsCalled[2] : "nil")")
                        XCTAssert(self.eventsCalled[3] == "primerDidCompleteCheckoutWithData", "Callback event should be 'primerDidCompleteCheckoutWithData' but was \(self.eventsCalled.count > 3 ? self.eventsCalled[3] : "nil")")
                        XCTAssert(self.eventsCalled[4] == "primerDidDismiss", "Callback event should be 'primerDidDismiss' but was \(self.eventsCalled.count > 4 ? self.eventsCalled[4] : "nil")")
                        
                    } else {
                        XCTAssert(self.eventsCalled[0] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                        XCTAssert(self.eventsCalled[1] == "primerDidCompleteCheckoutWithData", "Callback event should be 'primerDidCompleteCheckoutWithData' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                        XCTAssert(self.eventsCalled[2] == "primerDidDismiss", "Callback event should be 'primerDidDismiss' but was \(self.eventsCalled.count > 2 ? self.eventsCalled[2] : "nil")")
                    }
                    
                case .manual:
                    if isSurchargeIncluded {
                        XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "Callback event should be 'primerClientSessionWillUpdate' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                        XCTAssert(self.eventsCalled[1] == "primerClientSessionDidUpdate", "Callback event should be 'primerClientSessionDidUpdate' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                        XCTAssert(self.eventsCalled[2] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 2 ? self.eventsCalled[2] : "nil")")
                        XCTAssert(self.eventsCalled[3] == "primerDidTokenizePaymentMethod", "Callback event should be 'primerDidTokenizePaymentMethod' but was \(self.eventsCalled.count > 3 ? self.eventsCalled[3] : "nil")")
                        XCTAssert(self.eventsCalled[4] == "primerDidDismiss", "Callback event should be 'primerDidDismiss' but was \(self.eventsCalled.count > 4 ? self.eventsCalled[4] : "nil")")
                        
                    } else {
                        XCTAssert(self.eventsCalled[0] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                        XCTAssert(self.eventsCalled[1] == "primerDidTokenizePaymentMethod", "Callback event should be 'primerDidTokenizePaymentMethod' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                        XCTAssert(self.eventsCalled[2] == "primerDidDismiss", "Callback event should be 'primerDidDismiss' but was \(self.eventsCalled.count > 2 ? self.eventsCalled[2] : "nil")")
                    }
                }
                
                expectation.fulfill()
            }
        }
        
        self.paymentCompletion = { checkoutData, err in
            if case .manual = paymentHandling {
                XCTAssert(false, "'primerDidCompleteCheckoutWithData' delegate function should not be called when payment handling is 'auto'")
            }
            
            if let err = err {
                XCTAssert(false, "Failed with error \(err.localizedDescription) when it should have succeeded.")
            } else if let checkoutData = checkoutData {
                if checkoutData.payment?.id == Mocks.payment.id {
                    if !isAwaitingSDKDismiss {
                        if isSurchargeIncluded {
                            XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "Callback event should be 'primerClientSessionWillUpdate' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                            XCTAssert(self.eventsCalled[1] == "primerClientSessionDidUpdate", "Callback event should be 'primerClientSessionDidUpdate' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                            XCTAssert(self.eventsCalled[2] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 2 ? self.eventsCalled[2] : "nil")")
                            XCTAssert(self.eventsCalled[3] == "primerDidCompleteCheckoutWithData", "Callback event should be 'primerDidCompleteCheckoutWithData' but was \(self.eventsCalled.count > 3 ? self.eventsCalled[3] : "nil")")
                            
                        } else {
                            XCTAssert(self.eventsCalled[0] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                            XCTAssert(self.eventsCalled[1] == "primerDidCompleteCheckoutWithData", "Callback event should be 'primerDidCompleteCheckoutWithData' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                        }
                        expectation.fulfill()
                    }
                } else {
                    XCTAssert(false, "Payment id should be the one provided on the mocked API client.")
                }
            } else {
                XCTAssert(false, "Should always receive checkout data or error")
            }
        }
        
        self.tokenizationCompletion = { paymentMethodTokenData, err in
            if let err = err {
                XCTAssert(false, "Failed with error \(err.localizedDescription) when it should have succeeded.")
            } else if let paymentMethodTokenData = paymentMethodTokenData {
                XCTAssert(true, "All good!")
                if !isAwaitingSDKDismiss {
                    if paymentMethodTokenData.id == Mocks.primerPaymentMethodTokenData.id {
                        if isSurchargeIncluded {
                            XCTAssert(self.eventsCalled[0] == "primerClientSessionWillUpdate", "Callback event should be 'primerClientSessionWillUpdate' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                            XCTAssert(self.eventsCalled[1] == "primerClientSessionDidUpdate", "Callback event should be 'primerClientSessionDidUpdate' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                            XCTAssert(self.eventsCalled[2] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 2 ? self.eventsCalled[2] : "nil")")
                            XCTAssert(self.eventsCalled[3] == "primerDidTokenizePaymentMethod", "Callback event should be 'primerDidTokenizePaymentMethod' but was \(self.eventsCalled.count > 3 ? self.eventsCalled[3] : "nil")")
                            
                        } else {
                            XCTAssert(self.eventsCalled[0] == "primerWillCreatePaymentWithData", "Callback event should be 'primerWillCreatePaymentWithData' but was \(self.eventsCalled.count > 0 ? self.eventsCalled[0] : "nil")")
                            XCTAssert(self.eventsCalled[1] == "primerDidTokenizePaymentMethod", "Callback event should be 'primerDidTokenizePaymentMethod' but was \(self.eventsCalled.count > 1 ? self.eventsCalled[1] : "nil")")
                        }
                        
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
    
    // MARK: - HELPERS
    
    func resetTestingEnvironment() {
        Primer.shared.delegate = nil
        PrimerHeadlessUniversalCheckout.current.delegate = nil
        self.paymentCompletion = nil
        self.tokenizationCompletion = nil
        self.dismissalCompletion = nil
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
