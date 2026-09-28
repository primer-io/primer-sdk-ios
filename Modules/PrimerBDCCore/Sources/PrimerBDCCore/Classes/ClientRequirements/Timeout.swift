//
//  Timeout.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal)
public struct TimeoutError: Error, Equatable {
    public let nanoseconds: UInt64
}

/// The operation's value, or `TimeoutError` once the time is up, without waiting for the operation to stop.
/// Whichever comes second is cancelled.
@MainActor @_spi(PrimerInternal)
public func withTimeout<T>(
    nanoseconds: UInt64,
    _ operation: @escaping @MainActor () async throws -> T
) async throws -> T {
    let race = Race<T>()
    return try await withCheckedThrowingContinuation { continuation in
        race.continuation = continuation
        race.work = Task { @MainActor in
            do {
                race.finish(.success(try await operation()))
            } catch {
                race.finish(.failure(error))
            }
        }
        race.timer = Task { @MainActor in
            try await Task.sleep(nanoseconds: nanoseconds)
            race.finish(.failure(TimeoutError(nanoseconds: nanoseconds)))
        }
    }
}

@MainActor
private final class Race<T> {
    var continuation: CheckedContinuation<T, Error>?
    var work: Task<Void, Never>?
    var timer: Task<Void, Error>?

    func finish(_ result: Result<T, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        work?.cancel()
        timer?.cancel()
        continuation.resume(with: result)
    }
}
