//
//  DefaultBackendDrivenScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
import SwiftUI

enum BackendDrivenState: Equatable {
    case idle
    case running
    case paying
}

@available(iOS 16.0, *)
@MainActor
final class DefaultBackendDrivenScope: PrimerPaymentMethodScope, ObservableObject, LogReporter {

    let paymentMethodType: String
    let presentationContext: PresentationContext

    var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    var state: AsyncStream<BackendDrivenState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await state in $internalState.values {
                    continuation.yield(state)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    var logo: UIImage? { config?.logo }

    private weak var checkoutScope: DefaultCheckoutScope?
    private var orchestrator: BackendDrivenCheckoutOrchestrator?
    private var flowTask: Task<Void, Never>?
    private var hasStarted = false
    private var isScreenVisible = false
    private var screenWaiter: CheckedContinuation<Void, Never>?

    @Published private(set) var internalState: BackendDrivenState = .idle

    private var config: PrimerPaymentMethod? {
        PrimerAPIConfiguration.paymentMethodConfigs?.first { $0.type == paymentMethodType }
    }

    init(
        paymentMethodType: String,
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
    }

    func start() {
        guard !hasStarted, flowTask == nil else { return }
        hasStarted = true
        submit()
    }

    func prepareForReentry() {
        hasStarted = false
    }

    func submit() {
        guard flowTask == nil else { return }
        flowTask = Task {
            await runFlow()
            flowTask = nil
        }
    }

    func cancel() {
        flowTask?.cancel()
        resumeScreenWaiter()
        guard flowTask == nil else { return }
        returnToSelection()
    }

    func applyEvent(_ event: CodableValue) async throws {
        try await orchestrator?.applyEvent(event)
    }

    func screenDidAppear() {
        isScreenVisible = true
        resumeScreenWaiter()
    }

    private func runFlow() async {
        guard let checkoutScope else { return }
        internalState = .running
        defer {
            internalState = .idle
            orchestrator = nil
            isScreenVisible = false
        }

        do {
            guard let config else {
                throw PrimerError.invalidValue(key: "paymentMethodType", value: paymentMethodType)
            }
            try await checkoutScope.invokeBeforePaymentCreate(paymentMethodType: paymentMethodType)

            let context = SDKContext.generate(payment: SDKPayment(paymentMethodType: paymentMethodType))
            let orchestrator = try await BackendDrivenCheckoutOrchestrator(context: context)
            self.orchestrator = orchestrator
            PrimerStepResolverRegistry.shared.register(HTTPRequestResolver(), for: .httpRequest)
            await waitForScreen()
            try Task.checkCancellation()

            let result = try await pay(with: orchestrator, config: config)
            switch result {
            case let .success(payment):
                checkoutScope.handlePaymentSuccess(PaymentResult(
                    paymentId: payment?.id ?? "",
                    status: .success,
                    paymentMethodType: paymentMethodType
                ))
            case let .failure(payment):
                checkoutScope.handlePaymentError(PrimerError.paymentFailed(
                    paymentMethodType: paymentMethodType,
                    paymentId: payment?.id ?? "",
                    orderId: payment?.orderId,
                    status: payment?.status ?? "",
                    diagnosticsId: .uuid
                ))
            case .none:
                returnToSelection()
            }
        } catch {
            handle(error, checkoutScope: checkoutScope)
        }
    }

    private func pay(
        with orchestrator: BackendDrivenCheckoutOrchestrator,
        config: PrimerPaymentMethod
    ) async throws -> CheckoutResult? {
        let instructionProvider = NetworkClientInstructionProvider(paymentMethod: config)
        let pciUrl = PrimerAPIConfigurationModule.apiConfiguration?.pciUrl
        let coreUrl = PrimerAPIConfigurationModule.apiConfiguration?.coreUrl

        guard config.entry.requiresSetup else {
            return try await orchestrator.run(pciUrl: pciUrl, coreUrl: coreUrl, instructionProvider: instructionProvider)
        }

        let token = try await orchestrator.runSetup(pciUrl: pciUrl, coreUrl: coreUrl, instructionProvider: instructionProvider)
        guard PrimerSettings.current.paymentHandling == .auto else {
            logger.warn(message: "[BackendDriven] \(paymentMethodType) setup ended without an automatic payment")
            return nil
        }
        internalState = .paying
        return try await orchestrator.pay(
            paymentInstrumentTokenId: token,
            pciUrl: pciUrl,
            coreUrl: coreUrl,
            instructionProvider: instructionProvider
        )
    }

    private func handle(_ error: Error, checkoutScope: DefaultCheckoutScope) {
        if error is BackendDrivenCheckoutCancellation || error is CancellationError {
            return returnToSelection()
        }
        if case .cancelled = error as? PrimerError {
            return returnToSelection()
        }
        if let ended = error as? SetupEnded {
            return checkoutScope.handlePaymentError(
                PrimerError.paymentMethodSetupEnded(paymentMethodType: paymentMethodType, reason: ended.reason.rawValue)
            )
        }
        checkoutScope.handlePaymentError(
            error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
        )
    }

    private func returnToSelection() {
        checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
    }

    private func waitForScreen() async {
        guard !isScreenVisible else { return }
        await withCheckedContinuation { screenWaiter = $0 }
    }

    private func resumeScreenWaiter() {
        screenWaiter?.resume()
        screenWaiter = nil
    }
}
