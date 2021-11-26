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
    
    let rootUrl = "https://primer.io/apaya/result?"
    
    func test_apaya_web_view_result_created_from_correct_url() throws {
        let url = URL(string: rootUrl + "token=A9IotQFdJBSYjth7h)hGWmFAgzVjxU6xeGGT)AaAbB=&pt=ExamplePTValue&success=1&status=SETUP_SUCCESS&HashedIdentifier=602&MX=MX&MCC=208&MNC=91&success=1")
        
        let clientToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MjA0NTI2MDksImFjY2Vzc1Rva2VuIjoiZGNjNGI1NjUtZmM2Mi00NDVmLWEzNzktYTdmMDdkYzkwOTM3IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUpoWlRSaVltRTRNUzFqTm1WakxUUTJZVGt0WVdRell5MWhNV0V3T1RJMk1UYzBPVEVpTENKcFlYUWlPakUyTWpBek5qWXlNRGtzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LmlIbGhjbWRMVE1sVURKMXREY0hFVkhjT01hZUstUUJTTGFXczJVVVJnOGsiLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.RMqc8MjYhltrlfNmXK3R0IZOaHQvIzhJdNL_nScy08Y"
        
        let state: AppStateProtocol = MockAppState(clientToken: clientToken)
        state.paymentMethodConfig = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        let settings = PrimerSettings(currency: .GBP)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        do {
            let apayaWebViewResponse = try Apaya.WebViewResponse(url: url!)
            XCTAssertEqual(apayaWebViewResponse.success, "1")
        }
        catch {
            XCTFail()
        }
    }
    
    func test_apaya_web_view_result_fails_on_success_not_provided() throws {
        let url = URL(string: rootUrl + "pt=ExamplePTValue&status=SETUP_SUCCESS&HashedIdentifier=602&MX=MX&MCC=208&MNC=91")
        
        let state: AppStateProtocol = MockAppState()
        state.paymentMethodConfig = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        let settings = PrimerSettings(currency: .GBP)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        do {
            try Apaya.WebViewResponse(url: url!)
            XCTFail()
        }
        catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_apaya_web_view_result_fails_on_error_url() throws {
        let url = URL(string: rootUrl + "success=0&status=SETUP_ERROR")
        do {
            let apayaWebViewResponse = try Apaya.WebViewResponse(url: url!)
            XCTFail()
        }
        catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_apaya_web_view_result_nil_on_cancel_url() throws {
        let url = URL(string: rootUrl + "success=0&status=SETUP_ABANDONED")
        do {
            try Apaya.WebViewResponse(url: url!)
            XCTFail()
        }
        catch {
            if let apayaErr = error as? ApayaException, apayaErr == .webViewFlowCancelled {
                XCTAssertNotNil(apayaErr)
            } else {
                XCTFail("Error should be .webViewFlowCancelled")
            }
        }
    }
    
    func test_apaya_carrier() throws {
        var carrier: Apaya.Carrier!
        
        carrier = Apaya.Carrier(mcc: 234, mnc: 99)
        if carrier != Apaya.Carrier.EE_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = Apaya.Carrier(mcc: 234, mnc: 11)
        if carrier != Apaya.Carrier.O2_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = Apaya.Carrier(mcc: 234, mnc: 15)
        if carrier != Apaya.Carrier.Vodafone_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = Apaya.Carrier(mcc: 234, mnc: 20)
        if carrier != Apaya.Carrier.Three_UK {
            XCTFail("Wrong carrier")
        }
        
        carrier = Apaya.Carrier(mcc: 242, mnc: 99)
        if carrier != Apaya.Carrier.Strex_Norway {
            XCTFail("Wrong carrier")
        }
    }
    
}


#endif
