//
//  PayPalService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockPayPalService: PayPalServiceProtocol {

    var confirmBillingAgreementCalled = false

    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void) {
        confirmBillingAgreementCalled = true
    }

    var startBillingAgreementSessionCalled = false

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        startBillingAgreementSessionCalled = true
        completion(.success("https://primer.io"))
    }

    var startOrderSessionCalled = false

    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void) {
        startOrderSessionCalled = true
        let res = Response.Body.PayPal.CreateOrder(orderId: "oid", approvalUrl: "https://primer.io")
        completion(.success(res))
    }
    
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {
        
    }
}

#endif
