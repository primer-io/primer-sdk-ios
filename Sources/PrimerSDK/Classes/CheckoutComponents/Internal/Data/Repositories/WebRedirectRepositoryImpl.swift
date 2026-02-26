//
//  WebRedirectRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

@available(iOS 15.0, *)
final class WebRedirectRepositoryImpl: WebRedirectRepository, LogReporter {

    // MARK: - Dependencies

    private let tokenizationService: TokenizationServiceProtocol
    private let webAuthService: WebAuthenticationService
    private let createPaymentService: CreateResumePaymentServiceProtocol

    // MARK: - State

    /// Payment ID from tokenization, used during resume phase.
    /// Thread-safe because WebRedirectRepositoryImpl uses transient DI scope -
    /// each payment flow gets a fresh instance with no concurrent access.
    ///
    /// Flow: tokenize() sets this → resumePayment() reads it (sequential, same instance)
    private var resumePaymentId: String?

    /// Current polling module, stored to support cancellation.
    /// Set when polling starts, cleared when polling completes or is cancelled.
    private var currentPollingModule: PollingModule?

    // MARK: - Initialization

    init(
        tokenizationService: TokenizationServiceProtocol = TokenizationService(),
        webAuthService: WebAuthenticationService = DefaultWebAuthenticationService(),
        createPaymentServiceFactory: @escaping (String) -> CreateResumePaymentServiceProtocol = { paymentMethodType in
            CreateResumePaymentService(paymentMethodType: paymentMethodType)
        }
    ) {
        self.tokenizationService = tokenizationService
        self.webAuthService = webAuthService
        // Default to generic type, will be updated per payment
        createPaymentService = createPaymentServiceFactory("WEB_REDIRECT")
    }

    // Internal init for dependency injection with specific payment service
    init(
        tokenizationService: TokenizationServiceProtocol,
        webAuthService: WebAuthenticationService,
        createPaymentService: CreateResumePaymentServiceProtocol
    ) {
        self.tokenizationService = tokenizationService
        self.webAuthService = webAuthService
        self.createPaymentService = createPaymentService
    }

    // MARK: - WebRedirectRepository Protocol

    func tokenize(
        paymentMethodType: String,
        sessionInfo: WebRedirectSessionInfo
    ) async throws -> (redirectUrl: URL, statusUrl: URL) {
        // Get payment method configuration
        guard let paymentMethodConfig = PrimerAPIConfiguration.current?.paymentMethods?
            .first(where: { $0.type == paymentMethodType }),
              let configId = paymentMethodConfig.id else {
            let error = PrimerError.invalidValue(
                key: "paymentMethodType",
                value: paymentMethodType,
                reason: "Payment method not found in configuration or missing config ID"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        // Create payment instrument
        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: paymentMethodType,
            sessionInfo: sessionInfo
        )

        // Tokenize
        let tokenData = try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        )

        guard let token = tokenData.token else {
            let error = PrimerError.invalidValue(key: "paymentMethodTokenData.token")
            ErrorHandler.handle(error: error)
            throw error
        }

        // Create payment to get redirect URLs
        let paymentResponse = try await createPaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: token)
        )

        // Store payment ID for resume
        resumePaymentId = paymentResponse.id

        // Check for required action with redirect URLs
        guard let requiredAction = paymentResponse.requiredAction else {
            let error = PrimerError.invalidValue(
                key: "paymentResponse.requiredAction",
                value: nil,
                reason: "Web redirect payment requires a redirect action"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        // Store the new client token
        let apiConfigurationModule = PrimerAPIConfigurationModule()
        try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

        // Get the decoded JWT which contains redirect URLs
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: error)
            throw error
        }

        guard let redirectUrlStr = decodedJWTToken.redirectUrl,
              let redirectUrl = URL(string: redirectUrlStr),
              let statusUrlStr = decodedJWTToken.statusUrl,
              let statusUrl = URL(string: statusUrlStr) else {
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
        // For non-web schemes (deep links like vipps://, bankapp://), use UIApplication.open
        // This matches the Drop-In UI pattern in WebRedirectPaymentMethodTokenizationViewModel
        guard url.hasWebBasedScheme else {
            try await openDeepLink(url: url)
            // Deep links don't return a callback URL - polling handles completion
            return url
        }

        // For https URLs, use ASWebAuthenticationSession
        let scheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        return try await webAuthService.connect(
            paymentMethodType: paymentMethodType,
            url: url,
            scheme: scheme
        )
    }

    private func openDeepLink(url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                UIApplication.shared.open(url) { success in
                    if success {
                        continuation.resume()
                    } else {
                        let error = PrimerError.failedToRedirect(url: url.schemeAndHost)
                        ErrorHandler.handle(error: error)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        let pollingModule = PollingModule(url: statusUrl)
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
}
