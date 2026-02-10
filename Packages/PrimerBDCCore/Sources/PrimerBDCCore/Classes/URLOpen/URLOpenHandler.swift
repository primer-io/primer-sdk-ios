//
//  URLOpenHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

@MainActor
final class URLOpenHandler {
    weak var delegate: URLOpenDelegate?
    
    private let registry: PrimerStepResolverRegistry
    private let harness: SFSafariViewControllerHarness
    
    init(registry: PrimerStepResolverRegistry) {
        self.registry = registry
        self.harness = SFSafariViewControllerHarness()
        Task { await registry.register(harness, forStepType: .urlOpen) }
        harness.delegate = self
    }
    
    func resolve(_ data: CodableValue) async throws -> CodableValue? {
        let resolver = try await registry.resolver(for: .urlOpen)
        return try await resolver.resolve(data)
    }
}

extension URLOpenHandler: @MainActor SFSafariViewControllerHarnessDelegate {
    func safariViewControllerHarnessDidCancel() {
        delegate?.urlOpenDidCancel()
    }
    
    func safariViewControllerHarnessDidComplete() {
        delegate?.urlOpenDidComplete()
    }
}

protocol URLOpenDelegate: AnyObject {
    func urlOpenDidComplete()
    func urlOpenDidFail(with error: Error)
    func urlOpenDidCancel()
}
