//
//  FormRedirectRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Repository Implementation

@available(iOS 15.0, *)
final class FormRedirectRepositoryImpl: FormRedirectRepository, LogReporter {

    // MARK: - Type Aliases

    typealias PaymentServiceFactory = (String) -> CreateResumePaymentServiceProtocol

    // MARK: - Dependencies

    private let tokenizationService: TokenizationServiceProtocol
    private let paymentServiceFactory: PaymentServiceFactory
    private let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol
    private let pollingModuleFactory: (URL) -> PollingModule

    private var activePollingModule: PollingModule?

    // MARK: - Initialization

    init(
        tokenizationService: TokenizationServiceProtocol = TokenizationService(),
        paymentServiceFactory: @escaping PaymentServiceFactory = { CreateResumePaymentService(paymentMethodType: $0) },
        apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule(),
        pollingModuleFactory: @escaping (URL) -> PollingModule = { PollingModule(url: $0) }
    ) {
        self.tokenizationService = tokenizationService
        self.paymentServiceFactory = paymentServiceFactory
        self.apiConfigurationModule = apiConfigurationModule
        self.pollingModuleFactory = pollingModuleFactory
    }

    // MARK: - FormRedirectRepository

    func tokenize(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo
    ) async throws -> FormRedirectTokenizationResponse {
        guard let configId = getPaymentMethodConfigId(for: paymentMethodType) else {
            let error = PrimerError.invalidValue(
                key: "paymentMethodConfigId",
                reason: "Payment method configuration not found for \(paymentMethodType)"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: paymentMethodType,
            sessionInfo: sessionInfo
        )

        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        let tokenData = try await tokenizationService.tokenize(requestBody: requestBody)

        logger.debug(message: "Tokenization successful for \(paymentMethodType)")

        return FormRedirectTokenizationResponse(tokenData: tokenData)
    }

    func createPayment(token: String, paymentMethodType: String) async throws -> FormRedirectPaymentResponse {
        logger.debug(message: "Creating payment with token for \(paymentMethodType)")

        let paymentService = paymentServiceFactory(paymentMethodType)
        let paymentRequest = Request.Body.Payment.Create(token: token)
        let paymentResponse = try await paymentService.createPayment(paymentRequest: paymentRequest)

        // Store new client token if present (contains statusUrl for polling)
        if let requiredAction = paymentResponse.requiredAction {
            try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
        }

        let statusUrl = extractStatusUrl()

        logger.debug(message: "Payment created with status: \(paymentResponse.status.rawValue), statusUrl: \(statusUrl?.absoluteString ?? "nil")")

        guard let paymentId = paymentResponse.id else {
            let error = PrimerError.invalidValue(key: "paymentId", reason: "Payment response missing payment ID")
            ErrorHandler.handle(error: error)
            throw error
        }

        return FormRedirectPaymentResponse(
            paymentId: paymentId,
            status: paymentResponse.status,
            statusUrl: statusUrl
        )
    }

    func resumePayment(paymentId: String, resumeToken: String, paymentMethodType: String) async throws -> FormRedirectPaymentResponse {
        logger.debug(message: "Resuming payment \(paymentId) with resume token for \(paymentMethodType)")

        let paymentService = paymentServiceFactory(paymentMethodType)
        let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
        let paymentResponse = try await paymentService.resumePaymentWithPaymentId(
            paymentId,
            paymentResumeRequest: resumeRequest
        )

        logger.debug(message: "Payment resumed with status: \(paymentResponse.status.rawValue)")

        return FormRedirectPaymentResponse(
            paymentId: paymentResponse.id ?? paymentId,
            status: paymentResponse.status,
            statusUrl: nil
        )
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        logger.debug(message: "Starting polling for status URL: \(statusUrl.absoluteString)")

        let pollingModule = pollingModuleFactory(statusUrl)
        activePollingModule = pollingModule

        defer {
            activePollingModule = nil
        }

        return try await pollingModule.start()
    }

    func cancelPolling(error: PrimerError) {
        activePollingModule?.cancel(withError: error)
    }

    // MARK: - Private Helpers

    private func getPaymentMethodConfigId(for paymentMethodType: String) -> String? {
        PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?
            .first { $0.type == paymentMethodType }?.id
    }

    /// Extracts the status URL from the current decoded JWT token (stored after `storeRequiredActionClientToken`)
    private func extractStatusUrl() -> URL? {
        guard let statusUrlString = PrimerAPIConfigurationModule.decodedJWTToken?.statusUrl,
              let statusUrl = URL(string: statusUrlString) else {
            return nil
        }
        return statusUrl
    }
}
