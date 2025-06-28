//
//  CreateResumePaymentService.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/02/22.
//

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment>
    func createPayment(paymentRequest: Request.Body.Payment.Create) async throws -> Response.Body.Payment
    func completePayment(clientToken: DecodedJWTToken,
                         completeUrl: URL,
                         body: Request.Body.Payment.Complete) -> Promise<Void>
    func completePayment(clientToken: DecodedJWTToken,
                         completeUrl: URL,
                         body: Request.Body.Payment.Complete) async throws
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment>
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment
}

private enum CreateResumePaymentCallType: String {
    case create
    case resume
}

final class CreateResumePaymentService: CreateResumePaymentServiceProtocol {
    let apiClient: PrimerAPIClientCreateResumePaymentProtocol

    let paymentMethodType: String

    init(paymentMethodType: String,
         apiClient: PrimerAPIClientCreateResumePaymentProtocol = PrimerAPIClient()) {
        self.paymentMethodType = paymentMethodType
        self.apiClient = apiClient
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment> {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise(error: err)
        }

        return Promise { seal in
            self.apiClient.createPayment(clientToken: clientToken,
                                         paymentRequestBody: paymentRequest) { result in
                switch result {
                case .failure(let error):
                    seal.reject(error)
                case .success(let paymentResponse):
                    do {
                        try self.validateResponse(paymentResponse: paymentResponse, callType: .create)
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create) async throws -> Response.Body.Payment {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let paymentResponse = try await self.apiClient.createPayment(
            clientToken: clientToken,
            paymentRequestBody: paymentRequest
        )

        try self.validateResponse(paymentResponse: paymentResponse, callType: .create)
        return paymentResponse
    }

    /**
     * Validates the response from the payment API.
     *
     * This private method checks the `checkoutOutcome` of the payment response and throws an error if the
     * payment creation should fail based on the provided call type. It handles both the new checkoutOutcome logic
     * and the old logic based on the payment status.
     *
     * - Parameters:
     *   - paymentResponse: A `Response.Body.Payment` object representing the payment response.
     *   - callType: A `CreateResumePaymentCallType` indicating whether this is a create or resume call.
     *
     * - Throws: A `PrimerError` if the payment creation should fail.
     */
    private func validateResponse(paymentResponse: Response.Body.Payment, callType: CreateResumePaymentCallType) throws {
        if let checkoutOutcome = paymentResponse.checkoutOutcome {
            switch checkoutOutcome {
            case .complete: return
            case .failure: throw createPaymentFailedError(paymentResponse: paymentResponse)
            default: break // Continue with old logic
            }
        }

        /* Old logic */
        let shouldFail = (callType == .resume && paymentResponse.shouldFailPaymentCreationWhenPending) || paymentResponse
            .shouldFailPaymentCreationImmediately

        if shouldFail {
            throw createPaymentFailedError(paymentResponse: paymentResponse)
        }
    }

    // Helper method to create a payment failed error
    private func createPaymentFailedError(paymentResponse: Response.Body.Payment, description: String? = nil) -> PrimerError {
        PrimerError.paymentFailed(
            paymentMethodType: paymentMethodType,
            paymentId: paymentResponse.id ?? "unknown",
            orderId: paymentResponse.orderId ?? nil,
            status: paymentResponse.status.rawValue,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
    }

    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment> {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise(error: err)
        }

        return Promise { seal in
            self.apiClient.resumePayment(clientToken: clientToken,
                                         paymentId: paymentId,
                                         paymentResumeRequest: paymentResumeRequest) { result in
                switch result {
                case .failure(let err):
                    let error = PrimerError.failedToResumePayment(
                        paymentMethodType: self.paymentMethodType,
                        description: err.localizedDescription,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )

                    seal.reject(error)
                case .success(let paymentResponse):
                    do {
                        try self.validateResponse(paymentResponse: paymentResponse, callType: .resume)
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) async throws -> Response.Body.Payment {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        do {
            let paymentResponse = try await self.apiClient.resumePayment(
                clientToken: clientToken,
                paymentId: paymentId,
                paymentResumeRequest: paymentResumeRequest
            )

            try self.validateResponse(paymentResponse: paymentResponse, callType: .resume)
            return paymentResponse
        } catch {
            let error = PrimerError.failedToResumePayment(
                paymentMethodType: self.paymentMethodType,
                description: error.localizedDescription,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: error)
            throw error
        }
    }

    /**
     * Completes a payment using the provided JWT token and URL.
     *
     * This private method performs an API call to complete a payment, using a decoded JWT token for authentication
     * and a URL indicating where the completion request should be sent.
     *
     * - Parameters:
     *   - clientToken: A `DecodedJWTToken` representing the client's authentication token.
     *   - completeUrl: An `URL` indicating the endpoint for completing the ACH payment.
     *
     * - Returns: A `Promise<Void>` that resolves if the payment is completed successfully, or rejects if there is
     *            an error during the API call.
     */
    func completePayment(clientToken: DecodedJWTToken,
                         completeUrl: URL,
                         body: Request.Body.Payment.Complete) -> Promise<Void> {
        return Promise { seal in
            self.apiClient.completePayment(clientToken: clientToken,
                                           url: completeUrl,
                                           paymentRequest: body) { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    func completePayment(
        clientToken: DecodedJWTToken,
        completeUrl: URL,
        body: Request.Body.Payment.Complete
    ) async throws {
        try await self.apiClient.completePayment(
            clientToken: clientToken,
            url: completeUrl,
            paymentRequest: body
        )
    }
}

private extension Response.Body.Payment {
    var shouldFailPaymentCreationImmediately: Bool {
        id == nil || status == .failed
    }

    var shouldFailPaymentCreationWhenPending: Bool {
        status == .pending && showSuccessCheckoutOnPendingPayment != true
    }
}
