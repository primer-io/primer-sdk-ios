//
//  MockCreateResumePaymentService.swift
//  PrimerSDK_Tests
//
//  Created by Jack Newcombe on 22/05/2024.
//

import Foundation
@testable import PrimerSDK

final class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {
    func completePayment(clientToken: PrimerSDK.DecodedJWTToken,
                         completeUrl: URL,
                         body: Request.Body.Payment.Complete) -> PrimerSDK.Promise<Void> {
        Promise { seal in
            seal.fulfill()
        }
    }

    func completePayment(clientToken: PrimerSDK.DecodedJWTToken, completeUrl: URL, body: Request.Body.Payment.Complete) async throws {}

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

    func createPayment(clientToken: PrimerSDK.DecodedJWTToken, paymentRequest: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        if let result = onCreatePayment?(paymentRequest) {
            return result
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
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

    func resumePaymentWithPaymentId(clientToken: PrimerSDK.DecodedJWTToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        if let result = onResumePayment?(paymentId, paymentResumeRequest) {
            return result
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
