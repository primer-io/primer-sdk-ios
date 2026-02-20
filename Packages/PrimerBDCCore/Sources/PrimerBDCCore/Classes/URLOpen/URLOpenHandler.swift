//
//  URLOpenHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

@MainActor
final class URLOpenHandler {
    
    private let harness: SFSafariViewControllerHarness
    
    private var onClose: (() async throws -> Void)?
    private var onComplete: (() async throws -> Void)?
    
    init() {
        self.harness = SFSafariViewControllerHarness()
        harness.delegate = self
    }
    
    func resolve(
        _ data: CodableValue,
        onClose: (() async throws -> Void)?,
        onComplete: (() async throws -> Void)?
    ) async throws -> CodableValue? {
        self.onClose = onClose
        self.onComplete = onComplete
        return try await harness.resolve(data)
    }
}

extension URLOpenHandler: SFSafariViewControllerHarnessDelegate {
    func safariViewControllerHarnessDidCancel() async throws { try await onClose?() }
    func safariViewControllerHarnessDidComplete() async throws { try await onComplete?() }
}
