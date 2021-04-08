//
//  KlarnaService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 22/02/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockKlarnaService: KlarnaServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {

    }

    func createKlarnaCustomerToken(_ completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {

    }

    func finalizePaymentSession(_ completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void) {

    }

}

#endif
