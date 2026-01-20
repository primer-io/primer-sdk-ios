//
//  CancellableTask.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public actor CancellableTask<Success: Sendable> {
    private var continuation: CheckedContinuation<Success, Error>?
    private var finished = false
    private var task: Task<Void, Never>?
    private var cancellationError: Error?
    private let onCancel: (@Sendable () -> Void)?
    private let operation: @Sendable () async throws -> Success

    public init(
        onCancel: (@Sendable () -> Void)? = nil,
        operation: @Sendable @escaping () async throws -> Success
    ) {
        self.onCancel = onCancel
        self.operation = operation
    }

    deinit {
        task?.cancel()
    }

    public func wait() async throws -> Success {
        if let cancellationError {
            throw cancellationError
        }

        assert(continuation == nil && !finished, "wait() called more than once")

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            if let cancellationError {
                tryResume(.failure(cancellationError))
                return
            }

            guard task == nil else {
                return
            }

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    let value = try await self.operation()
                    await self.tryResume(.success(value))
                } catch {
                    await self.tryResume(.failure(self.cancellationError ?? error))
                }
            }
        }
    }

    public func cancel(with error: Error) {
        cancellationError = error
        tryResume(.failure(error))
        task?.cancel()
        onCancel?()
    }

    private func tryResume(_ result: Result<Success, Error>) {
        guard !finished, let continuation else { return }
        finished = true
        continuation.resume(with: result)
        self.continuation = nil
    }
}
