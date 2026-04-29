//
//  AsyncUtils.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public func awaitResult<T: Sendable>(_ body: (@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        body { result in
            switch result {
            case let .success(value): continuation.resume(returning: value)
            case let .failure(error): continuation.resume(throwing: error)
            }
        }
    }
}

public func awaitResult<T: Sendable>(_ body: (@escaping (T?, Error?) -> Void) -> Void) async throws -> T? {
    try await withCheckedThrowingContinuation { continuation in
        body { value, error in
            if let error {
                return continuation.resume(throwing: error)
            }
            continuation.resume(returning: value)
        }
    }
}

public func awaitResult<T: Sendable>(_ body: (@escaping (Result<T, Error>, [String: String]?) -> Void) -> Void) async throws -> (T, [String: String]?) {
    try await withCheckedThrowingContinuation { continuation in
        body { result, headers in
            switch result {
            case let .success(value): continuation.resume(returning: (value, headers))
            case let .failure(error): continuation.resume(throwing: error)
            }
        }
    }
}
