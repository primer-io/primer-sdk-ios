//
//  ApayaTests.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 01/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class ApayaDataModelTests: XCTestCase {
    
    let rootUrl = "https://primer.io/apaya/result/?"
    
    func test_apaya_web_view_result_created_from_correct_url() throws {
        let url = URL(string: rootUrl + "success=1&token=A9IotQFdJBSYjth7h)hGWmFAgzVjxU6xeGGT)AaAbB=&pt=ExamplePTValue&status=SETUP_SUCCESS&HashedIdentifier=602&MX=MX&MCC=208&MNC=91&success=1")
        
        let state: AppStateProtocol = MockAppState()
        state.primerConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        let settings = PrimerSettings(currency: .GBP)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        do {
            let apayaWebViewResponse = try PaymentMethod.Apaya.WebViewResponse(url: url!)
            XCTAssertEqual(apayaWebViewResponse.success, "1")
        } catch {
            XCTFail()
        }
    }
    
    func test_apaya_web_view_result_fails_on_success_not_provided() throws {
        let state: AppStateProtocol = MockAppState()
        state.primerConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        let settings = PrimerSettings(currency: .GBP)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let url = URL(string: rootUrl + "pt=ExamplePTValue&status=SETUP_SUCCESS&HashedIdentifier=602&MX=MX&MCC=208&MNC=91")
        do {
            _ = try PaymentMethod.Apaya.WebViewResponse(url: url!)
            XCTFail()
        }
        catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_apaya_web_view_result_fails_on_error_url() throws {
        let url = URL(string: rootUrl + "success=0&status=SETUP_ERROR")
        do {
            _ = try PaymentMethod.Apaya.WebViewResponse(url: url!)
            XCTFail()
        }
        catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_apaya_web_view_result_nil_on_cancel_url() throws {
        let url = URL(string: rootUrl + "success=0&status=SETUP_ABANDONED")
        do {
            _ = try PaymentMethod.Apaya.WebViewResponse(url: url!)
            XCTFail()
        }
        catch {
            if let err = error as? PrimerError {
                switch err {
                case .failedOnWebViewFlow:
                    XCTAssertNotNil(err)
                default:
                    break
                }
                
            } else {
                XCTFail("Error should be .webViewFlowCancelled")
            }
        }
    }
    
    func test_apaya_carrier() throws {
        var carrier: PaymentMethod.Apaya.Carrier!
        
        carrier = PaymentMethod.Apaya.Carrier(mcc: 234, mnc: 99)
        if carrier != PaymentMethod.Apaya.Carrier.EE_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = PaymentMethod.Apaya.Carrier(mcc: 234, mnc: 11)
        if carrier != PaymentMethod.Apaya.Carrier.O2_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = PaymentMethod.Apaya.Carrier(mcc: 234, mnc: 15)
        if carrier != PaymentMethod.Apaya.Carrier.Vodafone_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = PaymentMethod.Apaya.Carrier(mcc: 234, mnc: 20)
        if carrier != PaymentMethod.Apaya.Carrier.Three_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = PaymentMethod.Apaya.Carrier(mcc: 242, mnc: 99)
        if carrier != PaymentMethod.Apaya.Carrier.Strex_Norway {
            XCTFail("Wrong carrier")
        }
    }
    
}


#endif
