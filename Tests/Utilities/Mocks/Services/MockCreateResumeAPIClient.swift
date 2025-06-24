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
            XCTFail("No create response set")
            return
        }
        completion(createResponse)
    }

    func createPayment(clientToken: PrimerSDK.DecodedJWTToken,
                       paymentRequestBody: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        guard let createResponse else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        switch createResponse {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
        guard let resumeResponse else {
            XCTFail("No resume response set")
            return
        }
        completion(resumeResponse)
    }

    func resumePayment(clientToken: PrimerSDK.DecodedJWTToken, paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        guard let resumeResponse else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        switch resumeResponse {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL, paymentRequest: Request.Body.Payment.Complete,
                         completion: @escaping APICompletion<Response.Body.Complete>) {
        guard let completeResponse else {
            XCTFail("No complete response set")
            return
        }
        completion(completeResponse)
    }

    func completePayment(clientToken: PrimerSDK.DecodedJWTToken,
                         url completeUrl: URL,
                         paymentRequest body: Request.Body.Payment.Complete) async throws -> Response.Body.Complete {
        guard let completeResponse else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        switch completeResponse {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}
