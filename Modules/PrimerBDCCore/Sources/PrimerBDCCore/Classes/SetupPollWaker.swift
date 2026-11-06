//
//  SetupPollWaker.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@MainActor
final class SetupPollWaker {
    private var continuation: CheckedContinuation<Void, Error>?
    private var timer: Task<Void, Never>?
    private var pending: Result<Void, Error>?

    func wait(milliseconds: Int) async throws {
        if let pending {
            self.pending = nil
            return try pending.get()
        }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                timer = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(max(0, milliseconds)) * 1_000_000)
                    guard !Task.isCancelled else { return }
                    self?.resume(.success(()))
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.resume(.failure(CancellationError())) }
        }
    }

    func wake() {
        finish(.success(()))
    }

    func fail(_ error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<Void, Error>) {
        guard continuation != nil else {
            if case .failure = pending { return }
            return pending = result
        }
        resume(result)
    }

    private func resume(_ result: Result<Void, Error>) {
        timer?.cancel()
        timer = nil
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(with: result)
    }
}
