//
//  KlarnaService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 22/02/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockKlarnaService: KlarnaServiceProtocol {

    var createPaymentSessionCalled = false
    
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        createPaymentSessionCalled = true
        completion(.success("redirectUrl"))
    }
    
    func finalizePaymentSession(_ completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void) {
        
    }
    
}

#endif
