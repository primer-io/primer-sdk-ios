//
//  CreateResumePaymentService.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/02/22.
//

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    func createPayment(paymentRequest: Request.Body.Payment.Create, completion: @escaping (Response.Body.Payment?, Error?) -> Void)
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (Response.Body.Payment?, Error?) -> Void)
}

internal class CreateResumePaymentService: CreateResumePaymentServiceProtocol {

    static var apiClient: PrimerAPIClientProtocol?

    func createPayment(paymentRequest: Request.Body.Payment.Create, completion: @escaping (Response.Body.Payment?, Error?) -> Void) {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        let apiClient: PrimerAPIClientProtocol = CreateResumePaymentService.apiClient ?? PrimerAPIClient()
        apiClient.createPayment(clientToken: clientToken, paymentRequestBody: paymentRequest) { result in
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
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        let apiClient: PrimerAPIClientProtocol = CreateResumePaymentService.apiClient ?? PrimerAPIClient()
        apiClient.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest) { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
            case .success(let paymentResponse):
                completion(paymentResponse, nil)
            }
        }
    }
}
