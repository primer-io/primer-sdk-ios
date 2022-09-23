//
//  CreateResumePaymentService.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/02/22.
//

#if canImport(UIKit)

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    init(apiClient: PrimerAPIClientProtocol)
    func createPayment(paymentRequest: Request.Body.Payment.Create, completion: @escaping (Response.Body.Payment?, Error?) -> Void)
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (Response.Body.Payment?, Error?) -> Void)
}

internal class CreateResumePaymentService: CreateResumePaymentServiceProtocol {
    
    private var apiClient: PrimerAPIClientProtocol
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create, completion: @escaping (Response.Body.Payment?, Error?) -> Void) {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
                
        self.apiClient.createPayment(clientToken: clientToken, paymentRequestBody: paymentRequest) { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
            case .success(let paymentResponse):
                completion(paymentResponse, nil)
            }
        }
    }
    
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (Response.Body.Payment?, Error?) -> Void) {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
                
        self.apiClient.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest) { result in
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
