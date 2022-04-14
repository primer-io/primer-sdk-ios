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

    func confirmBillingAgreement(_ completion: @escaping (Result<PaymentMethod.PayPal.ConfirmBillingAgreement.Response, Error>) -> Void) {
        confirmBillingAgreementCalled = true
    }

    var startBillingAgreementSessionCalled = false

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        startBillingAgreementSessionCalled = true
        completion(.success(""))
    }

    var startOrderSessionCalled = false

    func startOrderSession(_ completion: @escaping (Result<PaymentMethod.PayPal.CreateOrder.Response, Error>) -> Void) {
        startOrderSessionCalled = true
        let res = PaymentMethod.PayPal.CreateOrder.Response(orderId: "oid", approvalUrl: "https://primer.io")
        completion(.success(res))
    }
    
    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<PaymentMethod.PayPal.PayerInfo.Response, Error>) -> Void) {
        
    }
}

#endif
