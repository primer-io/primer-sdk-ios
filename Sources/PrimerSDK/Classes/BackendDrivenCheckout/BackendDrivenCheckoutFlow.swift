//
//  BackendDrivenCheckoutFlow.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
import Foundation
@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

@MainActor
final class BackendDrivenCheckoutFlow {

    typealias OrchestratorFactory = (SDKContext) async throws -> BackendDrivenCheckoutOrchestrator
    typealias InstructionProviderFactory = (PrimerPaymentMethod) -> ClientInstructionProvider

    enum Outcome {
        case paid(PaymentInfo?)
        case setupOnly
        case failed(PrimerErrorProtocol)
    }

    struct Host {
        let willCreatePayment: @MainActor () async throws -> Void
        let presentUI: @MainActor () async -> Bool
        let dismissUI: @MainActor () async -> Void
        var onURLOpened: (() -> Void)?
    }

    private let config: PrimerPaymentMethod
    private let makeOrchestrator: OrchestratorFactory
    private let makeInstructionProvider: InstructionProviderFactory
    private var orchestrator: BackendDrivenCheckoutOrchestrator?
    private var presenter: SDUIPresentingResolver?
    private var flowStarted = false
    private var flowEnded = false

    nonisolated init(
        config: PrimerPaymentMethod,
        makeOrchestrator: @escaping OrchestratorFactory = BackendDrivenCheckoutOrchestrator.init,
        makeInstructionProvider: @escaping InstructionProviderFactory = NetworkClientInstructionProvider.init
    ) {
        self.config = config
        self.makeOrchestrator = makeOrchestrator
        self.makeInstructionProvider = makeInstructionProvider
    }

    func applyEvent(_ event: CodableValue) async throws {
        try await orchestrator?.applyEvent(event)
    }

    func run(paymentInstrumentTokenId: String? = nil, host: Host) async -> Outcome {
        do {
            try await host.willCreatePayment()

            let context = SDKContext.generate(payment: SDKPayment(paymentMethodType: config.type))
            let orchestrator = try await makeOrchestrator(context)
            self.orchestrator = orchestrator
            orchestrator.onURLOpened = host.onURLOpened
            logStarted()
            presenter = SDUIPresentingResolver(present: host.presentUI)

            let instructionProvider = makeInstructionProvider(config)
            PrimerStepResolverRegistry.shared.register(HTTPRequestResolver(), for: .httpRequest)

            let pciUrl = PrimerAPIConfigurationModule.apiConfiguration?.pciUrl
            let coreUrl = PrimerAPIConfigurationModule.apiConfiguration?.coreUrl
            let result: CheckoutResult

            if let paymentInstrumentTokenId {
                result = try await orchestrator.pay(
                    paymentInstrumentTokenId: paymentInstrumentTokenId,
                    pciUrl: pciUrl,
                    coreUrl: coreUrl,
                    instructionProvider: instructionProvider
                )
            } else if config.entry.requiresSetup {
                _ = await host.presentUI()
                let token = try await orchestrator.runSetup(
                    pciUrl: pciUrl,
                    coreUrl: coreUrl,
                    instructionProvider: instructionProvider
                )
                await host.dismissUI()
                guard PrimerSettings.current.paymentHandling == .auto else { return .setupOnly }
                result = try await orchestrator.pay(
                    paymentInstrumentTokenId: token,
                    pciUrl: pciUrl,
                    coreUrl: coreUrl,
                    instructionProvider: instructionProvider
                )
            } else {
                result = try await orchestrator.run(
                    pciUrl: pciUrl,
                    coreUrl: coreUrl,
                    instructionProvider: instructionProvider
                )
            }
            await host.dismissUI()

            switch result {
            case let .success(payment):
                logEnded(outcome: "success")
                return .paid(payment)
            case let .failure(payment):
                return .failed(fail(paymentFailure(payment)))
            }
        } catch {
            await host.dismissUI()
            return .failed(fail(error))
        }
    }

    private func paymentFailure(_ payment: PaymentInfo?) -> PrimerError {
        guard let payment, let paymentId = payment.id else {
            return PrimerError.unknown(message: "Payment or paymentId was nil")
        }
        return PrimerError.paymentFailed(
            paymentMethodType: config.type,
            paymentId: paymentId,
            orderId: payment.orderId,
            status: payment.status,
            diagnosticsId: .uuid
        )
    }

    private func fail(_ error: Swift.Error) -> PrimerErrorProtocol {
        if error is BackendDrivenCheckoutCancellation || error is CancellationError {
            return fail(PrimerError.cancelled(paymentMethodType: config.type))
        }
        if let ended = error as? SetupEnded {
            return fail(PrimerError.paymentMethodSetupEnded(paymentMethodType: config.type, reason: ended.reason.rawValue))
        }
        let primerError: PrimerErrorProtocol = (error as? PrimerErrorProtocol) ?? PrimerError.unknown(
            message: error.localizedDescription,
            diagnosticsId: error.diagnosticId
        )
        let cancelled: Bool = if case .cancelled = error as? PrimerError { true } else { false }
        logEnded(outcome: cancelled ? "cancelled" : "error", error: primerError)
        Analytics.Service.fire(event: .message(
            message: "BDC Failed: \(error)",
            messageType: .error,
            severity: .error,
            diagnosticsId: primerError.diagnosticsId,
            context: ["paymentMethodType": config.type, "errorId": primerError.errorId]
        ))
        return primerError
    }

    private func logStarted() {
        flowStarted = true
        let event = Analytics.Event.message(
            message: "BDC flow started.",
            messageType: .backendDrivenCheckoutStarted,
            severity: .info,
            context: [
                "paymentMethodType": config.type,
                "entry": config.entry.rawValue,
                "trustedKeyFingerprints": ManifestValidator.trustedPublicKeys.map(\.fingerprint)
            ]
        )
        Analytics.Service.fire(event: event)
    }

    private func logEnded(outcome: String, error: PrimerErrorProtocol? = nil) {
        guard flowStarted, !flowEnded else { return }
        flowEnded = true
        var context: [String: Any] = ["paymentMethodType": config.type, "entry": config.entry.rawValue, "outcome": outcome]
        if let error { context["errorId"] = error.errorId }
        let event = Analytics.Event.message(
            message: "BDC flow ended: \(outcome).",
            messageType: .backendDrivenCheckoutEnded,
            severity: outcome == "error" ? .error : .info,
            diagnosticsId: error?.diagnosticsId,
            context: context
        )
        Analytics.Service.fire(event: event)
    }
}

private extension Error {
    var diagnosticId: String { (self as? StateProcessorError)?.diagnosticsId ?? .uuid }
}

extension BackendDrivenCheckoutOrchestrator {
    convenience init(context: SDKContext) async throws {
        let provider = NetworkSignedManifestProvider(token: PrimerAPIConfigurationModule.decodedJWTToken)
        let engine: any BDCEngineProtocol
        do {
            engine = try await BDCEngineProvider.shared.engine(manifestProvider: provider)
        } catch {
            let message = "BDC engine failed to load: \(error)"
            Analytics.Service.fire(event: .message(message: message, messageType: .backendDrivenEngineLoadFailed, severity: .error))
            throw error
        }
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
