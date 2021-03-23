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
    
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        confirmBillingAgreementCalled = true
    }
    
    var startBillingAgreementSessionCalled = false
    
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        startBillingAgreementSessionCalled = true
    }
    
    var startOrderSessionCalled = false
    
    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        startOrderSessionCalled = true
    }
}

#endif
