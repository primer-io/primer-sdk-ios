//
//  CreateResumePaymentService.swift
//  PrimerSDK_Tests
//
//  Created by Jack Newcombe on 22/05/2024.
//

import Foundation
@testable import PrimerSDK

class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {
    func completePayment(clientToken: PrimerSDK.DecodedJWTToken,
                         completeUrl: URL,
                         body: Request.Body.Payment.Complete) -> PrimerSDK.Promise<Void> {
        Promise { seal in
            seal.fulfill()
        }
    }
    

    static var apiClient: (any PrimerSDK.PrimerAPIClientProtocol)?

    // MARL: createPayment

    var onCreatePayment: ((Request.Body.Payment.Create) -> Response.Body.Payment?)?

    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment> {
        Promise { seal in
            if let result = onCreatePayment?(paymentRequest) {
                seal.fulfill(result)
            } else {
                seal.reject(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
            }
        }
    }

    // MARK: resumePaymentWithPaymentId

    var onResumePayment: ((String, Request.Body.Payment.Resume) -> Response.Body.Payment?)?

    func resumePaymentWithPaymentId(_ paymentId: String,
                                    paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment> {
        Promise { seal in
            if let result = onResumePayment?(paymentId, paymentResumeRequest) {
                seal.fulfill(result)
            } else {
                seal.reject(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
            }
        }
    }
}
