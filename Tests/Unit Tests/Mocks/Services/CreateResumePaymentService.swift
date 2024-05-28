//
//  CreateResumePaymentService.swift
//  PrimerSDK_Tests
//
//  Created by Jack Newcombe on 22/05/2024.
//

import Foundation
@testable import PrimerSDK

class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {

    static var apiClient: (any PrimerSDK.PrimerAPIClientProtocol)?
    
    // MARL: createPayment

    var onCreatePayment: ((Request.Body.Payment.Create) -> Response.Body.Payment?)?

    func createPayment(paymentRequest: Request.Body.Payment.Create,
                       completion: @escaping (Response.Body.Payment?, (any Error)?) -> Void) {
        if let result = onCreatePayment?(paymentRequest) {
            completion(result, nil)
        } else {
            completion(nil, PrimerError.generic(message: "", userInfo: nil, diagnosticsId: ""))
        }
    }

    // MARK: resumePaymentWithPaymentId

    var onResumePayment: ((String, Request.Body.Payment.Resume) -> Response.Body.Payment?)?

    func resumePaymentWithPaymentId(_ paymentId: String,
                                    paymentResumeRequest: Request.Body.Payment.Resume,
                                    completion: @escaping (Response.Body.Payment?, (any Error)?) -> Void) {
        if let result = onResumePayment?(paymentId, paymentResumeRequest) {
            completion(result, nil)
        } else {
            completion(nil, PrimerError.generic(message: "", userInfo: nil, diagnosticsId: ""))
        }
    }
    

}
