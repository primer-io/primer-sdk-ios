//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    func createPayment(paymentRequest: Payment.CreateRequest, completion: @escaping (Payment.Response?, Error?) -> Void)
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (Payment.Response?, Error?) -> Void)
}

internal class CreateResumePaymentService {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
}

extension CreateResumePaymentService: CreateResumePaymentServiceProtocol {

    func createPayment(paymentRequest: Payment.CreateRequest, completion: @escaping (Payment.Response?, Error?) -> Void) {
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.createPayment(clientToken: clientToken, paymentRequestBody: paymentRequest) { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
            case .success(let paymentResponse):
                completion(paymentResponse, nil)
            }
        }
    }
    
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (Payment.Response?, Error?) -> Void) {
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest) { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
            case .success(let paymentResponse):
                completion(paymentResponse, nil)
            }
        }

    }
}

#endif
