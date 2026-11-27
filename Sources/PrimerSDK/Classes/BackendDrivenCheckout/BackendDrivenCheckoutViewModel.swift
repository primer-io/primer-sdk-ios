//
//  BackendDrivenCheckoutViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCUI
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking
import SwiftUI
import UIKit

final class BackendDrivenCheckoutViewModel: PaymentMethodTokenizationViewModel {

    typealias OrchestratorFactory = BackendDrivenCheckoutFlow.OrchestratorFactory
    typealias InstructionProviderFactory = BackendDrivenCheckoutFlow.InstructionProviderFactory

    private let flow: BackendDrivenCheckoutFlow
    private var checkoutTask: Task<Void, Never>?
    private var sduiController: UIViewController?
    private var vaultedPaymentInstrumentTokenId: String?

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
        flow = BackendDrivenCheckoutFlow(
            config: config,
            makeOrchestrator: makeOrchestrator,
            makeInstructionProvider: makeInstructionProvider
        )
        super.init(
            config: config,
            uiManager: uiManager,
            tokenizationService: tokenizationService,
            createResumePaymentService: paymentService
        )
    }
    
    func start(paymentInstrumentTokenId: String) async {
        vaultedPaymentInstrumentTokenId = paymentInstrumentTokenId
        start()
        await checkoutTask?.value
    }

    override func start() {
        checkoutTask = Task { @MainActor in
            defer { config.tokenizationViewModel = nil }
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

            let host = BackendDrivenCheckoutFlow.Host(
                willCreatePayment: { [weak self] in try await self?.checkWillCreatePaymentDecision() },
                presentUI: { [weak self] in await self?.presentSDUI() ?? false },
                dismissUI: { [weak self] in await self?.dismissSDUI() },
                onURLOpened: { [weak self] in
                    guard let self else { return }
                    PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: paymentMethodType)
                }
            )

            switch await flow.run(paymentInstrumentTokenId: vaultedPaymentInstrumentTokenId, host: host) {
            case let .paid(payment): await handleSuccess(payment)
            case let .failed(error): await handleFailure(error)
            }
        }
    }
    
    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            throw handled(primerError: .invalidClientToken())
        }
    }
    
    @discardableResult
    @MainActor
    private func presentSDUI() async -> Bool {
        guard #available(iOS 16.0, *), sduiController == nil,
              let root = PrimerUIManager.primerRootViewController else { return false }
        let controller = UIHostingController(rootView: SDUIView(
            onEvent: { [flow] in try await flow.applyEvent($0) },
            onClose: { [weak self] in self?.leave() },
            titleImage: config.logo
        ).modifier(SDUIDesignTokens()))
        controller.modalPresentationStyle = .pageSheet
        sduiController = controller
        await withCheckedContinuation { continuation in
            root.present(controller, animated: true) { continuation.resume() }
        }
        return true
    }

    private func leave() {
        Task { @MainActor [weak self, flow] in
            guard await flow.leave() else { return }
            self?.checkoutTask?.cancel()
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
        let checkoutData = PrimerCheckoutData(payment: payment?.toPrimerPayment())
        await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
        let categories = config.paymentMethodManagerCategories ?? []
        uiManager.dismissOrShowResultScreen(type: .success, paymentMethodManagerCategories: categories, withMessage: nil)
    }
    
    @MainActor
    private func handleFailure(_ error: PrimerErrorProtocol) async {
        let decision = await PrimerDelegateProxy.primerDidFailWithError(error, data: paymentCheckoutData)
        switch decision.type {
        case let .fail(message): handleFailureFlow(errorMessage: message)
        }
    }
}

private extension PaymentInfo {
    func toPrimerPayment() -> PrimerCheckoutDataPayment {
        PrimerCheckoutDataPayment(id: id, orderId: orderId, paymentFailureReason: nil, status: status)
    }
}
