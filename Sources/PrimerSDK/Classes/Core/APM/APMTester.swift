//
//  APMService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/9/21.
//

import Foundation
import PassKit
import WebKit

class APMTester {
    
    func testApaya() {
        let apm = try! APM.WebBased.createApayaVaultAPM()

        let apmViewModel = APMViewModel.WebBased(apm: apm)
        
        firstly {
            apmViewModel.tokenize()
        }
        .done { paymentMethod in
            
        }
        .catch { err in
            
        }
    }
    
    func testKlarna() {
        let apm = try! APM.WebBased.createKlarnaVaultAPM()
        

        let apmViewModel = APMViewModel.WebBased(apm: apm)
        
        firstly {
            apmViewModel.tokenize()
        }
        .done { paymentMethod in
            
        }
        .catch { err in
            
        }
    }
    
    func testApplePay() {
        let apm = SDKBasedAPM(name: "APPLE_PAY", apmRequest: SDKBasedAPM.applePayAPMRequest)
        

        let apmViewModel = APMViewModel.SDKBased(apm: apm)
        
//        firstly {
//            apmViewModel.tokenize()
//        }
//        .done { paymentMethod in
//            
//        }
//        .catch { err in
//            
//        }
    }
    
}

extension SDKBasedAPM {
    static var applePayAPMRequest: APMRequest {
        let request = PKPaymentRequest()
        return request
    }
}
