//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

@testable import PrimerSDK

class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {
    
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

    func createPayment(paymentRequest: Payment.CreateRequest, completion: @escaping (Payment.Response?, Error?) -> Void) {
        guard let data = rawPaymentResponse.data(using: .utf8) else {
            return
        }
        
        do {
            let response = try JSONParser().parse(Payment.Response.self, from: data)
            completion(response, nil)
        } catch {
            completion(nil, error)
        }
        
    }
    
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (Payment.Response?, Error?) -> Void) {
                
        guard let data = rawPaymentResponse.data(using: .utf8) else {
            return
        }
        
        do {
            let response = try JSONParser().parse(Payment.Response.self, from: data)
            completion(response, nil)
        } catch {
            completion(nil, error)
        }
    }
}
