//
//  URLOpenHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

@MainActor
final class URLOpenHandler {
    
    var onClose: (() async throws -> Void)?
    var onComplete: (() async throws -> Void)?
    
    private let harness: SFSafariViewControllerHarness
    
    init() {
        self.harness = SFSafariViewControllerHarness()
        harness.delegate = self
    }
    
    func resolve(_ data: CodableValue) async throws -> CodableValue? {
        try await harness.resolve(data)
    }
}

extension URLOpenHandler: SFSafariViewControllerHarnessDelegate {
    func safariViewControllerHarnessDidCancel() async throws { try await onClose?() }
    func safariViewControllerHarnessDidComplete() async throws { try await onComplete?() }
}
