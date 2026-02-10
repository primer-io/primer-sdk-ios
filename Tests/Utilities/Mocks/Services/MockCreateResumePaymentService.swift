//
//  MockCreateResumePaymentService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerNetworking
@testable import PrimerSDK

final class MockCreateResumePaymentService: CreateResumePaymentServiceProtocol {
    
    var onResumePayment: ((String, Request.Body.Payment.Resume) -> Response.Body.Payment?)?
    var onCreatePayment: ((Request.Body.Payment.Create) -> Response.Body.Payment?)?

    func completePayment(clientToken: DecodedJWTToken, completeUrl: URL, body: Request.Body.Payment.Complete) async throws {}

    func createPayment(paymentRequest: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        guard let result = onCreatePayment?(paymentRequest) else {
            throw PrimerError.unknown()
        }
        return result
    }

    func resumePaymentWithPaymentId(_ paymentId: String,
                                    paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        guard let result = onResumePayment?(paymentId, paymentResumeRequest) else {
            throw PrimerError.unknown()
        }

        return result
    }
}
