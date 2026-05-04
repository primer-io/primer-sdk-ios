//
//  ProcessAdyenKlarnaPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
protocol ProcessAdyenKlarnaPaymentInteractor {
    func fetchPaymentOptions() async throws -> [AdyenKlarnaPaymentOption]
    func execute(selectedOption: AdyenKlarnaPaymentOption) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessAdyenKlarnaPaymentInteractorImpl: ProcessAdyenKlarnaPaymentInteractor, LogReporter {

    private let repository: AdyenKlarnaRepository
    private let clientSessionActionsFactory: () -> ClientSessionActionsProtocol

    init(
        repository: AdyenKlarnaRepository,
        clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() }
    ) {
        self.repository = repository
        self.clientSessionActionsFactory = clientSessionActionsFactory
    }

    func fetchPaymentOptions() async throws -> [AdyenKlarnaPaymentOption] {
        let paymentMethodType = PrimerPaymentMethodType.adyenKlarna.rawValue

        guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?
            .first(where: { $0.type == paymentMethodType })?.id
        else {
            let error = PrimerError.invalidValue(
                key: "paymentMethodConfigId",
                reason: "Payment method configuration not found for \(paymentMethodType)"
            )
            ErrorHandler.handle(error: error)
            throw error
        }

        let options = try await repository.fetchPaymentOptions(configId: configId)
        logger.debug(message: "[AdyenKlarna] Fetched \(options.count) payment options")
        return options
    }

    func execute(selectedOption: AdyenKlarnaPaymentOption) async throws -> PaymentResult {
        let paymentMethodType = PrimerPaymentMethodType.adyenKlarna.rawValue

        do {
            logger.debug(message: "[AdyenKlarna] Starting payment with option: \(selectedOption.name)")

            let clientSessionActions = clientSessionActionsFactory()
            try await clientSessionActions.selectPaymentMethodIfNeeded(paymentMethodType, cardNetwork: nil)

            try await handlePrimerWillCreatePaymentEvent(paymentMethodType: paymentMethodType)

            let sessionInfo = AdyenKlarnaSessionInfo(
                locale: PrimerSettings.current.localeData.localeCode,
                paymentMethodType: selectedOption.name
            )

            let (redirectUrl, statusUrl) = try await repository.tokenize(
                paymentMethodType: paymentMethodType,
                sessionInfo: sessionInfo
            )

            _ = try await repository.openWebAuthentication(
                paymentMethodType: paymentMethodType,
                url: redirectUrl
            )

            let resumeToken = try await repository.pollForCompletion(statusUrl: statusUrl)

            let result = try await repository.resumePayment(
                paymentMethodType: paymentMethodType,
                resumeToken: resumeToken
            )

            logger.debug(message: "[AdyenKlarna] Payment completed: \(result.status)")
            return result
        } catch {
            throw handled(error: error)
        }
    }

    private func handlePrimerWillCreatePaymentEvent(paymentMethodType: String) async throws {
        guard PrimerInternal.shared.intent != .vault else { return }

        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodType)
        let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

        let decision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)

        switch decision.type {
        case let .abort(errorMessage):
            throw PrimerError.merchantError(message: errorMessage ?? "")
        case .continue:
            return
        }
    }
}
