//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockPayPalService: PayPalServiceProtocol {

    var confirmBillingAgreementCalled = false

    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        confirmBillingAgreementCalled = true
    }

    var startBillingAgreementSessionCalled = false

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        startBillingAgreementSessionCalled = true
        completion(.success("https://primer.io"))
    }

    var startOrderSessionCalled = false

    func startOrderSession(_ completion: @escaping (Result<PayPalCreateOrderResponse, Error>) -> Void) {
        startOrderSessionCalled = true
        let res = PayPalCreateOrderResponse(orderId: "oid", approvalUrl: "https://primer.io")
        completion(.success(res))
    }
    
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void) {
        
    }
}

#endif
