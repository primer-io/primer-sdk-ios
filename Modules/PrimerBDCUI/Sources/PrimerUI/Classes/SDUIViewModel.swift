//
//  SDUIViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

struct NavigationStep: Decodable {
    let targetId: String
    let targetContainer: String
}

@available(iOS 16.0, *)
@MainActor
final class SDUIViewModel: ObservableObject, StepResolver {
    @Published var currentUITree: UIDefinition?
    @Published var state: CodableState = [:]
    @Published var focusedFieldID: String?
    @Published private(set) var router = Router()
    
    private var uiTree: UIDefinition?
    private var onEvent: (CodableValue) async throws -> Void
    private var onError: ((Error) async -> Void)?

    init(
        registry: PrimerStepResolverRegistry = .shared,
        onEvent: @escaping (CodableValue) async throws -> Void,
        onError: ((Error) async -> Void)? = nil
    ) {
        self.onEvent = onEvent
        self.onError = onError
        registry.register(self, for: "ui.render")
    }

    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let uiDefinition = try data.casted(to: UIDefinition.self)
        currentUITree = uiDefinition
        #if DEBUG
        print(uiDefinition.prettyTreeDescription())
        #endif
        return StepResolutionResult(outcome: .success)
    }

    func applyEvent(_ event: Event, screenID: String) {
        Task {
            do {
                try await onEvent(event())
            } catch {
                await onError?(error)
            }
        }
    }

    func errorMessage(for fieldID: ComponentID) -> String? {
        getValue(forKeys: ["errors", fieldID], in: state)?.string
    }
}

@available(iOS 16.0, *)
private extension SDUIViewModel {
    func getValue(forKeys keys: [String], in dict: CodableState) -> CodableValue? {
        guard let key = keys.first else { return nil }
        if keys.count == 1 {
            return dict[key]
        } else {
            guard case let .object(subDict)? = dict[key] else { return nil }
            return getValue(forKeys: Array(keys.dropFirst()), in: subDict)
        }
    }
}
