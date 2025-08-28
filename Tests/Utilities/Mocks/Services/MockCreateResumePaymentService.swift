//
//  MockCreateResumePaymentService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

final class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {
    

    var onResumePayment: ((String, Request.Body.Payment.Resume) -> Response.Body.Payment?)?
    var onCreatePayment: ((Request.Body.Payment.Create) -> Response.Body.Payment?)?

    func completePayment(clientToken: PrimerSDK.DecodedJWTToken,
                         completeUrl: URL,
                         body: Request.Body.Payment.Complete) -> PrimerSDK.Promise<Void> {
        Promise { seal in
            seal.fulfill()
        }
    }

    func completePayment(clientToken: DecodedJWTToken, completeUrl: URL, body: Request.Body.Payment.Complete) async throws {}

    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment> {
        Promise { seal in
            if let result = onCreatePayment?(paymentRequest) {
                seal.fulfill(result)
            } else {
                seal.reject(PrimerError.unknown())
            }
        }
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        guard let result = onCreatePayment?(paymentRequest) else {
            throw PrimerError.unknown()
        }
        return result
    }

    func resumePaymentWithPaymentId(_ paymentId: String,
                                    paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment> {
        Promise { seal in
            if let result = onResumePayment?(paymentId, paymentResumeRequest) {
                seal.fulfill(result)
            } else {
                seal.reject(PrimerError.unknown())
            }
        }
    }

    func resumePaymentWithPaymentId(_ paymentId: String,
                                    paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        guard let result = onResumePayment?(paymentId, paymentResumeRequest) else {
            throw PrimerError.unknown()
        }

        return result
    }
}
