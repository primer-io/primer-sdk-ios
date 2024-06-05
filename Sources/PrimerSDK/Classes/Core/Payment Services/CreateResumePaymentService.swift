//
//  CreateResumePaymentService.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/02/22.
//

import Foundation

internal protocol CreateResumePaymentServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment>
    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment>
}

internal class CreateResumePaymentService: CreateResumePaymentServiceProtocol {

    static var apiClient: PrimerAPIClientProtocol?

    let paymentMethodType: String

    init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func createPayment(paymentRequest: Request.Body.Payment.Create) -> Promise<Response.Body.Payment> {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise(error: err)
        }

        let apiClient: PrimerAPIClientProtocol = CreateResumePaymentService.apiClient ?? PrimerAPIClient()
        return Promise { seal in
            apiClient.createPayment(clientToken: clientToken, paymentRequestBody: paymentRequest) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    seal.reject(self.handleCreatePaymentError(error: error))
                case .success(let paymentResponse):
                    do {
                        try self.validateCreatePaymentResponse(paymentResponse: paymentResponse)
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    private func handleCreatePaymentError(error: Error?) -> Error {

        if let error = error, case let InternalError.serverError(statusCode, _, _, _) = error {
            if (400...499).contains(statusCode) {
                return PrimerError.paymentFailed(paymentMethodType: paymentMethodType,
                                                 description: "Failed to create payment",
                                                 userInfo: .errorUserInfoDictionary(),
                                                 diagnosticsId: UUID().uuidString)
            }
        }

        let err = PrimerError.paymentFailed(
            paymentMethodType: paymentMethodType,
            description: "Failed to resume payment",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: err)
        return err
    }

    private func validateCreatePaymentResponse(paymentResponse: Response.Body.Payment) throws {
        if paymentResponse.id == nil {
            let err = PrimerError.paymentFailed(
                paymentMethodType: self.paymentMethodType,
                description: "Failed to resume payment",
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err

        } else if paymentResponse.status == .failed {
            let err = PrimerError.failedToProcessPayment(
                paymentMethodType: paymentMethodType,
                paymentId: paymentResponse.id ?? "nil",
                status: paymentResponse.status.rawValue,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    func resumePaymentWithPaymentId(_ paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume) -> Promise<Response.Body.Payment> {
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return Promise(error: err)
        }

        return Promise { seal in
            let apiClient: PrimerAPIClientProtocol = CreateResumePaymentService.apiClient ?? PrimerAPIClient()
            apiClient.resumePayment(clientToken: clientToken,
                                    paymentId: paymentId,
                                    paymentResumeRequest: paymentResumeRequest) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    seal.reject(self.handleCreatePaymentError(error: error))
                case .success(let paymentResponse):
                    do {
                        try self.validateCreatePaymentResponse(paymentResponse: paymentResponse)
                        seal.fulfill(paymentResponse)
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
    }
}
