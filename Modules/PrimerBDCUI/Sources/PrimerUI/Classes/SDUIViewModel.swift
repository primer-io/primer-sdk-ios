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
    var initialScreenID: String!
    var updateUITree: ((AnyDict) -> Void)!
    
    init(registry: PrimerStepResolverRegistry = .shared) {
        Task { await registry.register(self, for: "ui.render") }
        updateUITree = { [weak self] in
            let tree = (try! JSONDecoder().decode(UIDefinition.self, from: $0.data()))
            self?.uiTree = tree
            switch tree.component {
            case let .navigation(screens, props): break /*self?.currentUITree = screens.first { $0.componentID == props.initialScreenId }*/
            default: break
            }
        }
    }
	
    //	func applyEvent(_ event: Event, screenID: String) {
//        Task {
//            try await callback(.left(ApplyEventCallback(event: event, screenId: screenID, state: state)))
//        }
//    }
	
    func resolve(_ step: CodableValue) async throws -> StepResolutionResult {
        guard let uiTree else { return StepResolutionResult(outcome: .error) }
        let step = try step.casted(to: NavigationStep.self)
        // Semir to return screen in params so this can be avoided
        let definition = switch uiTree.component {
        case let .navigation(screens, props): screens.first { $0.componentID == step.targetId }!
        default: fatalError()
        }
        await router.setStep(.detail(definition: definition, screenID: step.targetId))
        return StepResolutionResult(outcome: .success)
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
