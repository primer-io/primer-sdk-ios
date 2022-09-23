//
//  CreateResumePaymentService.swift
//  PrimerSDK_Tests
//
//  Created by Dario Carlomagno on 27/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

@testable import PrimerSDK

class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {
    
    private var apiClient: PrimerAPIClientProtocol
    private let rawPaymentResponse = """
        {
          "id": "AY6mjuo9111",
          "date": "2022-04-27T13:07:11.845401",
          "status": "SUCCESS",
          "currencyCode": "EUR",
          "orderId": "ios_order_id_TUqYLuja",
          "amount": 8888,
          "customerId": "ios_customer_id"
        }
        """
    
    private let rawPaymentCreateRequest = """
{"paymentMethodToken":"S5oJoPWgTraPoTPWF72wZXwxNj0000000xMDY0ODMx"}
"""
    private let rawPaymentResumeRequest = """
{"resumeToken":"AY6mjuo9111"}
"""
    
    required init(apiClient: PrimerAPIClientProtocol) {
        self.apiClient = apiClient
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create, completion: @escaping (Response.Body.Payment?, Error?) -> Void) {
        guard let data = rawPaymentResponse.data(using: .utf8) else {
            return
        }
        
        do {
            let response = try JSONParser().parse(Response.Body.Payment.self, from: data)
            completion(response, nil)
        } catch {
            completion(nil, error)
        }
        
    }
    
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (Response.Body.Payment?, Error?) -> Void) {
                
        guard let data = rawPaymentResponse.data(using: .utf8) else {
            return
        }
        
        do {
            let response = try JSONParser().parse(Response.Body.Payment.self, from: data)
            completion(response, nil)
        } catch {
            completion(nil, error)
        }
    }
}
