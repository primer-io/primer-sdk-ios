//
//  DefaultBackendDrivenScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

enum BackendDrivenState: Equatable {
    case idle
    case loading
    case showingSchema
}

@available(iOS 16.0, *)
@MainActor
final class DefaultBackendDrivenScope: PrimerPaymentMethodScope, ObservableObject, LogReporter {

    typealias FlowFactory = (PrimerPaymentMethod) -> BackendDrivenCheckoutFlow

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

    @Published private(set) var internalState: BackendDrivenState = .idle

    private weak var checkoutScope: DefaultCheckoutScope?
    private let makeFlow: FlowFactory
    private var flow: BackendDrivenCheckoutFlow?
    private var flowTask: Task<Void, Never>?
    private var hasStarted = false
    private var schemaWaiter: CheckedContinuation<Void, Never>?

    private var config: PrimerPaymentMethod? {
        PrimerAPIConfiguration.paymentMethodConfigs?.first { $0.type == paymentMethodType }
    }

    init(
        paymentMethodType: String,
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        makeFlow: @escaping FlowFactory = { BackendDrivenCheckoutFlow(config: $0) }
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.makeFlow = makeFlow
    }

    func start() {
        start(paymentInstrumentTokenId: nil)
    }

    func start(paymentInstrumentTokenId: String?) {
        guard !hasStarted, flowTask == nil else { return }
        hasStarted = true
        run(paymentInstrumentTokenId: paymentInstrumentTokenId)
    }

    func prepareForReentry() {
        hasStarted = false
    }

    func submit() {
        run(paymentInstrumentTokenId: nil)
    }

    func cancel() {
        guard let flowTask else { return returnToSelection() }
        Task {
            guard await flow?.leave() ?? true else { return }
            flowTask.cancel()
            resumeSchemaWaiter()
        }
    }

    func applyEvent(_ event: CodableValue) async throws {
        try await flow?.applyEvent(event)
    }

    func schemaDidAppear() {
        resumeSchemaWaiter()
    }

    private func run(paymentInstrumentTokenId: String?) {
        guard flowTask == nil else { return }
        flowTask = Task {
            await runFlow(paymentInstrumentTokenId: paymentInstrumentTokenId)
            flowTask = nil
        }
    }

    private func runFlow(paymentInstrumentTokenId: String?) async {
        guard let checkoutScope else { return }
        guard let config else {
            return checkoutScope.handlePaymentError(PrimerError.invalidValue(key: "paymentMethodType", value: paymentMethodType))
        }
        let flow = makeFlow(config)
        self.flow = flow
        internalState = .loading
        defer {
            internalState = .idle
            self.flow = nil
        }

        let host = BackendDrivenCheckoutFlow.Host(
            willCreatePayment: { [paymentMethodType] in
                try await checkoutScope.invokeBeforePaymentCreate(paymentMethodType: paymentMethodType)
            },
            presentUI: { [weak self] in await self?.presentSchema() ?? false },
            dismissUI: { [weak self] in self?.internalState = .loading }
        )

        switch await flow.run(paymentInstrumentTokenId: paymentInstrumentTokenId, host: host) {
        case let .paid(payment):
            checkoutScope.handlePaymentSuccess(PaymentResult(
                paymentId: payment?.id ?? "",
                status: .success,
                paymentMethodType: paymentMethodType
            ))
        case let .failed(error):
            if case .cancelled = error as? PrimerError { return returnToSelection() }
            checkoutScope.handlePaymentError(error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription))
        }
    }

    private func presentSchema() async -> Bool {
        guard internalState != .showingSchema else { return false }
        internalState = .showingSchema
        await withCheckedContinuation { schemaWaiter = $0 }
        return true
    }

    private func resumeSchemaWaiter() {
        schemaWaiter?.resume()
        schemaWaiter = nil
    }

    private func returnToSelection() {
        checkoutScope?.cancelActivePaymentMethod(returnToSelection: presentationContext.shouldShowBackButton)
    }
}
