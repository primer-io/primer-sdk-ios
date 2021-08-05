//
//  ApayaService.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 04/08/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockApayaService: ApayaServiceProtocol {
    var didCallCreatePaymentSession = false
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        didCallCreatePaymentSession = true
        completion(.success("https://primer.io"))
    }
}

#endif
