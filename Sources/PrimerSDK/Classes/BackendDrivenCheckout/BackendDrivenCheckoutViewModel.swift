//
//  BackendDrivenCheckoutViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerBDCCore
import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
@_spi(PrimerInternal) import PrimerStepResolver
import UIKit

final class BackendDrivenCheckoutViewModel: PaymentMethodTokenizationViewModel {

    typealias OrchestratorFactory = (SDKContext) async throws -> BackendDrivenCheckoutOrchestrator
    typealias InstructionProviderFactory = (PrimerPaymentMethod) -> ClientInstructionProvider

    private let makeOrchestrator: OrchestratorFactory
    private let makeInstructionProvider: InstructionProviderFactory
    private var orchestrator: BackendDrivenCheckoutOrchestrator?

    convenience init(
        config: PrimerPaymentMethod,
        apiClient: PrimerAPIClientProtocol = PrimerAPIClient()
    ) {
        self.init(
            config: config,
            uiManager: PrimerUIManager.shared,
            tokenizationService: TokenizationService(apiClient: apiClient),
            paymentService: CreateResumePaymentService(paymentMethodType: config.type, apiClient: apiClient)
        )
    }
    
    init(
        config: PrimerPaymentMethod,
        uiManager: PrimerUIManaging,
        tokenizationService: TokenizationServiceProtocol,
        paymentService: CreateResumePaymentServiceProtocol,
        makeOrchestrator: @escaping OrchestratorFactory = BackendDrivenCheckoutOrchestrator.init,
        makeInstructionProvider: @escaping InstructionProviderFactory = NetworkClientInstructionProvider.init
    ) {
        self.makeOrchestrator = makeOrchestrator
        self.makeInstructionProvider = makeInstructionProvider
        super.init(
            config: config,
            uiManager: uiManager,
            tokenizationService: tokenizationService,
            createResumePaymentService: paymentService
        )
    }
    
    override func start() {
        Task { @MainActor in
            defer { config.tokenizationViewModel = nil }
            do {
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                
                try await checkWillCreatePaymentDecision()
                
                try await setupOrchestrator()
                logBDCStarted()

                let instructionProvider = makeInstructionProvider(config)
                await PrimerStepResolverRegistry.shared.register(HTTPRequestResolver(), for: "http.request")
                
                let result = try await orchestrator?.run(
                    pciUrl: PrimerAPIConfigurationModule.apiConfiguration?.pciUrl,
                    coreUrl: PrimerAPIConfigurationModule.apiConfiguration?.coreUrl,
                    instructionProvider: instructionProvider
                )
                
                switch result {
                case let .success(payment): await handleSuccess(payment)
                case let .failure(payment): await handleFailure(payment, diagnosticsId: .uuid)
                case .none: await handleError(PrimerError.unknown())
                }
                
            } catch {
                await handleError(error)
            }
        }
    }
    
    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            throw handled(primerError: .invalidClientToken())
        }
    }
    
    @MainActor
    private func setupOrchestrator() async throws {
        let context = generateContext()
        let orchestrator = try await makeOrchestrator(context)
        self.orchestrator = orchestrator
        orchestrator.onURLOpened = { [weak self] in
            guard let self else { return }
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: paymentMethodType)
        }
    }
    
    private func checkWillCreatePaymentDecision() async throws {
        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodType)
        let data = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
        let decision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(data)
        
        switch decision.type {
        case let .abort(message): throw PrimerError.merchantError(message: message ?? "")
        case .continue: return
        }
        
    }
    
    @MainActor
    private func handleSuccess(_ payment: PaymentInfo?) async {
        if PrimerSettings.current.paymentHandling == .auto {
            let checkoutData = PrimerCheckoutData(payment: payment?.toPrimerPayment())
            await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
        }
        let categories = config.paymentMethodManagerCategories ?? []
        uiManager.dismissOrShowResultScreen(type: .success, paymentMethodManagerCategories: categories, withMessage: nil)
    }
    
    private func handleFailure(_ payment: PaymentInfo?, diagnosticsId: String) async {
        guard let payment, let paymentId = payment.id else {
            return await handleError(PrimerError.unknown(message: "Payment or paymentId was nil"))
        }
        await handleError(PrimerError.paymentFailed(
            paymentMethodType: config.type,
            paymentId: paymentId,
            orderId: payment.orderId,
            status: payment.status,
            diagnosticsId: diagnosticsId
        ))
    }
    
    @MainActor
    private func handleError(_ error: Swift.Error) async {
        if error is BackendDrivenCheckoutCancellation {
            return await handleError(PrimerError.cancelled(paymentMethodType: config.type))
        }
        Analytics.Service.fire(event: .message(message: "BDC Failed: \(error)", messageType: .error, severity: .error))
        let primerError: PrimerErrorProtocol = (error as? PrimerErrorProtocol) ?? PrimerError.unknown(
            message: error.localizedDescription,
            diagnosticsId: error.diagnosticId
        )
        let decision = await PrimerDelegateProxy.primerDidFailWithError(primerError, data: paymentCheckoutData)
        switch decision.type {
        case let .fail(message): handleFailureFlow(errorMessage: message)
        }
    }
    
    private func logBDCStarted() {
        let event = Analytics.Event.message(
            message: "BDC flow started.",
            messageType: .backendDrivenCheckoutStarted,
            severity: .info,
            context: ["trustedKeyFingerprints": ManifestValidator.trustedPublicKeys.map(\.fingerprint)]
        )
        Analytics.Service.fire(event: event)
    }
    
    private func generateContext() -> SDKContext {
        let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration
        let analyticsUrl = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2
        let checkoutSessionId = PrimerInternal.shared.checkoutSessionId
        
        return SDKContext(
            sdk: SDK(),
            device: SDKDevice(),
            app: SDKApp(identifier: Bundle.primerFrameworkIdentifier),
            session: SDKSession(configuration: apiConfiguration, sessionId: checkoutSessionId),
            payment: SDKPayment(paymentMethodType: config.type),
            merchant: SDKMerchant(primerAccountId: apiConfiguration?.primerAccountId),
            analytics: SDKAnalytics(url: analyticsUrl)
        )
    }
}

private extension PaymentInfo {
    func toPrimerPayment() -> PrimerCheckoutDataPayment {
        PrimerCheckoutDataPayment(id: id, orderId: orderId, paymentFailureReason: nil, status: status)
    }
}

private extension Error {
    var diagnosticId: String { (self as? StateProcessorError)?.diagnosticsId ?? .uuid }
}

private extension BackendDrivenCheckoutOrchestrator {
    convenience init(context: SDKContext) async throws {
        try await self.init(manifestProvider: NetworkSignedManifestProvider(), context: context)
    }
}

private extension String {
    var fingerprint: String? {
        guard let keyBytes = Data(base64Encoded: self) else { return nil }
        return SHA256.hash(data: keyBytes)
            .map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
}
