//
//  BackendDrivenCheckoutViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
import Foundation
@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerBDCUI
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
@_spi(PrimerInternal) import PrimerStepResolver
import SwiftUI
import UIKit

final class BackendDrivenCheckoutViewModel: PaymentMethodTokenizationViewModel {

    typealias OrchestratorFactory = (SDKContext) async throws -> BackendDrivenCheckoutOrchestrator
    typealias InstructionProviderFactory = (PrimerPaymentMethod) -> ClientInstructionProvider

    private let makeOrchestrator: OrchestratorFactory
    private let makeInstructionProvider: InstructionProviderFactory
    private var orchestrator: BackendDrivenCheckoutOrchestrator?
    private var checkoutTask: Task<Void, Never>?
    private var sduiController: UIViewController?

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
        checkoutTask = Task { @MainActor in
            defer { config.tokenizationViewModel = nil }
            do {
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                
                try await checkWillCreatePaymentDecision()
                
                try await setupOrchestrator()
                logBDCStarted()

                let instructionProvider = makeInstructionProvider(config)
                await PrimerStepResolverRegistry.shared.register(HTTPRequestResolver(), for: .httpRequest)
                
                let pciUrl = PrimerAPIConfigurationModule.apiConfiguration?.pciUrl
                let coreUrl = PrimerAPIConfigurationModule.apiConfiguration?.coreUrl
                let result: CheckoutResult?

                if config.entry.requiresSetup {
                    #if canImport(PrimerKlarnaSDK)
                    KlarnaWidgetComponent.register()
                    #endif
                    await presentSDUI()
                    let token = try await orchestrator?.runSetup(
                        pciUrl: pciUrl,
                        coreUrl: coreUrl,
                        instructionProvider: instructionProvider
                    )
                    await dismissSDUI()
                    guard let token, PrimerSettings.current.paymentHandling == .auto else { return }
                    result = try await orchestrator?.pay(
                        paymentInstrumentTokenId: token,
                        pciUrl: pciUrl,
                        coreUrl: coreUrl,
                        instructionProvider: instructionProvider
                    )
                } else {
                    result = try await orchestrator?.run(
                        pciUrl: pciUrl,
                        coreUrl: coreUrl,
                        instructionProvider: instructionProvider
                    )
                }
                
                switch result {
                case let .success(payment): await handleSuccess(payment)
                case let .failure(payment): await handleFailure(payment, diagnosticsId: .uuid)
                case .none: await handleError(PrimerError.unknown())
                }
                
            } catch {
                await dismissSDUI()
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
        let context = SDKContext.generate(payment: SDKPayment(paymentMethodType: config.type))
        let orchestrator = try await makeOrchestrator(context)
        self.orchestrator = orchestrator
        orchestrator.onURLOpened = { [weak self] in
            guard let self else { return }
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: paymentMethodType)
        }
    }
    
    @MainActor
    private func presentSDUI() async {
        guard #available(iOS 16.0, *), let orchestrator, sduiController == nil,
              let root = PrimerUIManager.primerRootViewController else { return }
        let controller = UIHostingController(rootView: SDUIView(
            onEvent: orchestrator.applyEvent,
            onClose: { [weak self] in self?.checkoutTask?.cancel() },
            titleImage: config.logo
        ))
        controller.modalPresentationStyle = .pageSheet
        sduiController = controller
        await withCheckedContinuation { continuation in
            root.present(controller, animated: true) { continuation.resume() }
        }
    }

    @MainActor
    private func dismissSDUI() async {
        guard let controller = sduiController else { return }
        sduiController = nil
        await withCheckedContinuation { continuation in
            controller.dismiss(animated: true) { continuation.resume() }
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
        if error is BackendDrivenCheckoutCancellation || error is CancellationError {
            return await handleError(PrimerError.cancelled(paymentMethodType: config.type))
        }
        let primerError: PrimerErrorProtocol = (error as? PrimerErrorProtocol) ?? PrimerError.unknown(
            message: error.localizedDescription,
            diagnosticsId: error.diagnosticId
        )
        reportFailure(error, as: primerError)
        let decision = await PrimerDelegateProxy.primerDidFailWithError(primerError, data: paymentCheckoutData)
        switch decision.type {
        case let .fail(message): handleFailureFlow(errorMessage: message)
        }
    }
    
    private func logBDCStarted() {
        let context: [String: Any] = [
            "paymentMethodType": config.type,
            "trustedKeyFingerprints": ManifestValidator.trustedPublicKeys.map(\.fingerprint)
        ]
        BackendDrivenCheckoutLogger.log(
            "BDC flow started.",
            type: .backendDrivenCheckoutStarted,
            severity: .info,
            context: context
        )
    }

    private func reportFailure(_ error: Swift.Error, as primerError: PrimerErrorProtocol) {
        if case .cancelled? = primerError as? PrimerError { return }
        BackendDrivenCheckoutLogger.log(
            "BDC Failed: \(error)",
            type: .backendDrivenCheckoutFailed,
            severity: .error,
            diagnosticsId: primerError.diagnosticsId,
            context: ["paymentMethodType": config.type, "errorId": primerError.errorId]
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
        let provider = NetworkSignedManifestProvider(token: PrimerAPIConfigurationModule.decodedJWTToken)
        let engine = try await BDCEngineProvider.shared.engine(manifestProvider: provider)
        self.init(engine: engine, context: context)
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
