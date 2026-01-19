//
//  MockCreateResumeAPIClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class MockCreateResumeAPIClient: PrimerAPIClientCreateResumePaymentProtocol {
    var resumeResponse: APIResult<Response.Body.Payment>?
    var createResponse: APIResult<Response.Body.Payment>?
    var completeResponse: APIResult<Response.Body.Complete>?

    init(resumeResponse: APIResult<Response.Body.Payment>? = nil,
         createResponse: APIResult<Response.Body.Payment>? = nil,
         completeResponse: APIResult<Response.Body.Complete>? = nil) {
        self.resumeResponse = resumeResponse
        self.createResponse = createResponse
        self.completeResponse = completeResponse
    }

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
        guard let createResponse else {
            return XCTFail("No create response set")
        }
        completion(createResponse)
    }

    func createPayment(clientToken: PrimerSDK.DecodedJWTToken,
                       paymentRequestBody: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        guard let createResponse else {
            throw PrimerError.unknown()
        }
        switch createResponse {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
        guard let resumeResponse else {
            return XCTFail("No resume response set")
        }
        completion(resumeResponse)
    }

    func resumePayment(clientToken: PrimerSDK.DecodedJWTToken, paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        guard let resumeResponse else {
            throw PrimerError.unknown()
        }
        switch resumeResponse {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL, paymentRequest: Request.Body.Payment.Complete,
                         completion: @escaping APICompletion<Response.Body.Complete>) {
        guard let completeResponse else {
            return XCTFail("No complete response set")
        }
        completion(completeResponse)
    }

    func completePayment(clientToken: PrimerSDK.DecodedJWTToken,
                         url completeUrl: URL,
                         paymentRequest body: Request.Body.Payment.Complete) async throws -> Response.Body.Complete {
        guard let completeResponse else {
            throw PrimerError.unknown()
        }
        switch completeResponse {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }
}
