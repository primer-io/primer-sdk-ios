//
//  BackendDrivenCheckoutOrchestrator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCEngine
import PrimerFoundation

@MainActor
public final class BackendDrivenCheckoutOrchestrator {
        
    public var onURLOpened: (() -> Void)? {
        get { stepOrchestrator.onURLOpen }
        set { stepOrchestrator.onURLOpen = newValue }
    }

    public var onCancelled: (() -> Void)? {
        get { stepOrchestrator.onCancelled }
        set { stepOrchestrator.onCancelled = newValue }
    }
    
    private let stepOrchestrator: any StepOrchestrating

    public init(manifestProvider: SignedManifestProvider, context: SDKContext) async throws {
        let manifest = try await ManifestRepository(provider: manifestProvider).fetchManifest()
        let engine = try await PrimerBDCEngine(manifest: manifest)
        stepOrchestrator = PrimerStepOrchestrator(engine: engine, context: context)
    }

    init(stepOrchestrator: any StepOrchestrating) {
        self.stepOrchestrator = stepOrchestrator
    }

    public func run(instructionProvider: ClientInstructionProvider) async throws -> CheckoutResult {
        var instruction = try await instructionProvider.fetchPayInstruction()
        while true {
            try Task.checkCancellation()
            switch instruction {
            case let .wait(delay):
                try await Task.sleep(nanoseconds: UInt64(max(0, delay)) * 1_000_000)
                instruction = try await instructionProvider.fetchNextInstruction()
            case let .execute(delay, schema, parameters):
                try await Task.sleep(nanoseconds: UInt64(max(0, delay)) * 1_000_000)
                try await stepOrchestrator.start(rawSchema: schema.jsonString, initialState: parameters)
                instruction = try await instructionProvider.fetchNextInstruction()
            case let .end(outcome, payment):
                return try resolveOutcome(outcome, payment: payment)
            }
        }
    }

    private func resolveOutcome(_ outcome: CheckoutOutcome?, payment: PaymentInfo?) throws -> CheckoutResult {
        switch outcome {
        case .complete: return .success(payment: payment)
        case .failure: return .failure(payment: payment)
        case .none: throw Error.missingCheckoutOutcome
        case .determineFromPaymentStatus: throw Error.unexpectedOutcome
        }
    }
}

private extension BackendDrivenCheckoutOrchestrator {
    enum Error: Swift.Error {
        case missingCheckoutOutcome
        case unexpectedOutcome
    }
}
