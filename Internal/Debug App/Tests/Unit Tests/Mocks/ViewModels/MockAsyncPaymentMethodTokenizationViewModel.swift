//
//  Async.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 14/10/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import WebKit
@testable import PrimerSDK

#if canImport(UIKit)

import XCTest

class AsyncPaymentMethodTokenizationViewModelTests: XCTestCase, PrimerDelegate {
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {
        
    }
    

//    func test_async_payment_method_success_flow() throws {
//        MockLocator.registerDependencies()
//        
//        let vc = UIViewController()
//        
//        Primer.shared.delegate = self
//        Primer.shared.showUniversalCheckout(on: vc, clientToken: nil)
//        
//        let config = PaymentMethodConfig(id: "async_mock", options: nil, processorConfigId: nil, type: .hoolah)
//        let viewModel: MockAsyncPaymentMethodTokenizationViewModel? = MockAsyncPaymentMethodTokenizationViewModel(config: config)
//        viewModel!.returnedPaymentMethodJson = """
//            {
//              "paymentInstrumentData" : {
//                "paymentMethodConfigId" : "8ab7a3f2-2288-40ab-a86b-8303d2c1e3ec",
//                "paymentMethodType" : "HOOLAH",
//                "sessionInfo" : {
//
//                }
//              },
//              "vaultData" : null,
//              "threeDSecureAuthentication" : {
//                "responseCode" : "NOT_PERFORMED",
//                "protocolVersion" : null,
//                "reasonText" : null,
//                "reasonCode" : null,
//                "challengeIssued" : null
//              },
//              "tokenType" : "SINGLE_USE",
//              "token" : "KCZlrAosRRa5GBa6XsB-qHwxNjM0MjMwOTI3",
//              "analyticsId" : "2uLGOtPxWriK98szePJ0Xklt",
//              "paymentInstrumentType" : "OFF_SESSION_PAYMENT"
//            }
//            """
//        
//        let exp0 = XCTestExpectation(description: "Did start tokenization flow")
//        viewModel!.didStartTokenization = {
//            exp0.fulfill()
//        }
//        
//        let exp1 = XCTestExpectation(description: "Start presenting payment method")
//        viewModel!.willPresentExternalView = {
//            exp1.fulfill()
//        }
//        
//        let exp2 = XCTestExpectation(description: "Did present payment method")
//        viewModel!.didPresentExternalView = {
//            exp2.fulfill()
//        }
//        
//        let exp3 = XCTestExpectation(description: "Start dismissing payment method")
//        viewModel!.willDismissExternalView = {
//            exp3.fulfill()
//        }
//        
//        let exp4 = XCTestExpectation(description: "Did dismiss payment method")
//        viewModel!.didDismissExternalView = {
//            exp4.fulfill()
//        }
//        
//        let exp5 = XCTestExpectation(description: "Did return a payment method")
//        viewModel!.completion = { (tok, err) in
//            if let tok = tok {
//                exp5.fulfill()
//            }
//        }
//        
//        viewModel!.startTokenizationFlow()
//
//        wait(for: [exp0, exp1, exp2, exp3, exp4, exp5], timeout: 10.0)
//    }
    
//    func test_async_payment_method_fail_validation() throws {
//        MockLocator.registerDependencies()
//        
//        let vc = UIViewController()
//        
//        Primer.shared.delegate = self
//        Primer.shared.showUniversalCheckout(clientToken: "")
//        
//        let config = PrimerPaymentMethod(id: "async_mock", implementationType: .webRedirect, type: "", name: nil, processorConfigId: nil, surcharge: nil, options: nil, displayMetadata: nil)
//        let viewModel: CheckoutWithVaultedPaymentMethodViewModel? = CheckoutWithVaultedPaymentMethodViewModel(configuration: config, selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData())
//        viewModel?.continueAfterFailure = 
//        
//        let exp0 = XCTestExpectation(description: "Did start tokenization flow")
//        viewModel!.didStartTokenization = {
//            exp0.fulfill()
//        }
//        
//        let exp1 = XCTestExpectation(description: "Did complete with error")
//        viewModel!.didFinishPayment = { (err) in
//            if let err = err {
//                exp1.fulfill()
//            }
//        }
//        
//        viewModel!.startTokenizationFlow()
//
//        wait(for: [exp0, exp1], timeout: 10.0)
//    }
//    
//    // ---
//    
//    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
//        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
//            completion("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MzQzMTcwODgsImFjY2Vzc1Rva2VuIjoiOTUxODRhNWYtMWMxNS00OGQ0LTk4MzYtYmM4ZWFkZmYzMzFiIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnN0YWdpbmcuY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zdGFnaW5nLnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc3RhZ2luZy5wcmltZXIuaW8iLCJlbnYiOiJTVEFHSU5HIiwicGF5bWVudEZsb3ciOiJQUkVGRVJfVkFVTFQifQ.aybIRUso7r9LJcL3pg8_Rg2aVMHDUikcooA3KcCX43g", nil)
//        }
//    }
//    
//    func onTokenizeSuccess(_ paymentMethodToken: PrimerPay, resumeHandler: ResumeHandlerProtocol) {
//        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
//            resumeHandler.handle(newClientToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MzQzMTc4MjgsImFjY2Vzc1Rva2VuIjoiNjhiYmEzNzEtNjk3Yy00NjZkLTg4NTAtNDE4ODIxZTc0MTc0IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnN0YWdpbmcuY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJIT09MQUhfUkVESVJFQ1RJT04iLCJzdGF0dXNVcmwiOiJodHRwczovL2FwaS5zdGFnaW5nLnByaW1lci5pby9yZXN1bWUtdG9rZW5zL2YxYjJiZjFiLThkYzYtNGQxZS1iYTc3LTY5MDE3NDJkNTU0ZiIsInJlZGlyZWN0VXJsIjoiaHR0cHM6Ly9kZW1vLWpzLmRlbW8taG9vbGFoLmNvP09SREVSX0NPTlRFWFRfVE9LRU49ODM2N2VkNDYtMDQ4MS00OGEwLThlNzItYmI5N2VmYTJmZDBlJnBsYXRmb3JtPWJlc3Bva2UmdmVyc2lvbj0xLjAuMSJ9.Nm-RoYC8jNfHscHw1XiWzzAleoV_-ZEu5GJXidTjXg8")
//        }
//    }
    
    func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            resumeHandler.handleSuccess()
        }
    }
    
}

#endif
