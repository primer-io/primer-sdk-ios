//
//  AdyenKlarnaRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
final class AdyenKlarnaRepositoryImpl: AdyenKlarnaRepository, LogReporter {

    private let apiClient: PrimerAPIClientProtocol
    private let tokenizationService: TokenizationServiceProtocol
    private let webAuthService: WebAuthenticationService
    private let createPaymentService: CreateResumePaymentServiceProtocol
    private let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol
    private let pollingModuleFactory: (URL) -> PollingModule
    private let settings: PrimerSettingsProtocol

    private var resumePaymentId: String?
    private var currentPollingModule: PollingModule?

    init(
        apiClient: PrimerAPIClientProtocol? = nil,
        tokenizationService: TokenizationServiceProtocol = TokenizationService(),
        webAuthService: WebAuthenticationService = DefaultWebAuthenticationService(),
        createPaymentServiceFactory: @escaping (String) -> CreateResumePaymentServiceProtocol = {
            CreateResumePaymentService(paymentMethodType: $0)
        },
        apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule(),
        pollingModuleFactory: @escaping (URL) -> PollingModule = { PollingModule(url: $0) },
        settings: PrimerSettingsProtocol = PrimerSettings.current
    ) {
        self.apiClient = apiClient ?? PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        self.tokenizationService = tokenizationService
        self.webAuthService = webAuthService
        createPaymentService = createPaymentServiceFactory(PrimerPaymentMethodType.adyenKlarna.rawValue)
        self.apiConfigurationModule = apiConfigurationModule
        self.pollingModuleFactory = pollingModuleFactory
        self.settings = settings
    }

    func fetchPaymentOptions(configId: String) async throws -> [AdyenKlarnaPaymentOption] {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: error)
            throw error
        }

        let response = try await apiClient.listAdyenKlarnaPaymentTypes(
            clientToken: decodedJWTToken,
            paymentMethodConfigId: configId
        )

        return response.result.map {
            AdyenKlarnaPaymentOption(id: $0.id, name: $0.name)
        }
    }

    func tokenize(
        paymentMethodType: String,
        sessionInfo: AdyenKlarnaSessionInfo
    ) async throws -> (redirectUrl: URL, statusUrl: URL) {
        guard let paymentMethodConfig = PrimerAPIConfiguration.current?.paymentMethods?
            .first(where: { $0.type == paymentMethodType }),
            let configId = paymentMethodConfig.id
        else {
            let error = PrimerError.invalidValue(
                key: "paymentMethodType",
                value: paymentMethodType,
                reason: "Payment method not found in configuration or missing config ID"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: paymentMethodType,
            sessionInfo: sessionInfo
        )

        let tokenData = try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        )

        guard let token = tokenData.token else {
            let error = PrimerError.invalidValue(key: "paymentMethodTokenData.token")
            ErrorHandler.handle(error: error)
            throw error
        }

        let paymentResponse = try await createPaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: token)
        )

        resumePaymentId = paymentResponse.id

        guard let requiredAction = paymentResponse.requiredAction else {
            let error = PrimerError.invalidValue(
                key: "paymentResponse.requiredAction",
                value: nil,
                reason: "Adyen Klarna payment requires a redirect action"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: error)
            throw error
        }

        guard let redirectUrlStr = decodedJWTToken.redirectUrl,
            let redirectUrl = URL(string: redirectUrlStr),
            let statusUrlStr = decodedJWTToken.statusUrl,
            let statusUrl = URL(string: statusUrlStr)
        else {
            let error = PrimerError.invalidValue(
                key: "decodedJWTToken.redirectUrl/statusUrl",
                value: nil,
                reason: "Missing redirect or status URL in client token"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        return (redirectUrl: redirectUrl, statusUrl: statusUrl)
    }

    func openWebAuthentication(paymentMethodType: String, url: URL) async throws -> URL {
        guard url.hasWebBasedScheme else {
            try await openDeepLink(url: url)
            return url
        }

        let scheme = try settings.paymentMethodOptions.validSchemeForUrlScheme()
        return try await webAuthService.connect(
            paymentMethodType: paymentMethodType,
            url: url,
            scheme: scheme
        )
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        let pollingModule = pollingModuleFactory(statusUrl)
        currentPollingModule = pollingModule
        defer { currentPollingModule = nil }
        return try await pollingModule.start()
    }

    func cancelPolling(paymentMethodType: String) {
        currentPollingModule?.cancel(withError: PrimerError.cancelled(paymentMethodType: paymentMethodType))
    }

    func resumePayment(paymentMethodType: String, resumeToken: String) async throws -> PaymentResult {
        guard let paymentId = resumePaymentId else {
            let error = PrimerError.invalidValue(
                key: "resumePaymentId",
                value: nil,
                reason: "Resume payment ID not available. Tokenization must be called first."
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        let paymentResponse = try await createPaymentService.resumePaymentWithPaymentId(
            paymentId,
            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
        )

        return PaymentResult(
            paymentId: paymentResponse.id ?? "",
            status: PaymentStatus(from: paymentResponse.status),
            amount: paymentResponse.amount,
            currencyCode: paymentResponse.currencyCode,
            paymentMethodType: paymentMethodType
        )
    }

    @MainActor
    private func openDeepLink(url: URL) async throws {
        let success = await UIApplication.shared.open(url)
        guard success else {
            let error = PrimerError.failedToRedirect(url: url.schemeAndHost)
            ErrorHandler.handle(error: error)
            throw error
        }
    }
}
