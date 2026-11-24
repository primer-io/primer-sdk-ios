//
//  NetworkSelectionGate.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest

final class NetworkSelectionGate {

    private var heldSelections: [CheckedContinuation<Void, Never>] = []

    @MainActor var heldCount: Int { heldSelections.count }

    @MainActor
    func wait() async {
        await withCheckedContinuation { heldSelections.append($0) }
    }

    @MainActor
    func release() {
        heldSelections.forEach { $0.resume() }
        heldSelections = []
    }
}

extension XCTestCase {

    func waitForHeldSelections(_ count: Int, on gate: NetworkSelectionGate) async throws {
        try await withTimeout(2.0) {
            while await gate.heldCount < count { await Task.yield() }
        }
    }

    func releaseSelections(afterHolding count: Int, on gate: NetworkSelectionGate) async throws {
        try await waitForHeldSelections(count, on: gate)
        await gate.release()
    }
}
