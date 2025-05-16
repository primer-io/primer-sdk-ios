//
//  AsyncUtils.swift
//  PrimerSDK
//
//  Created by Onur Var on 17.05.2025.
//

extension Promise {
    func async() async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.done { value in
                continuation.resume(returning: value)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }
}

func awaitResult<T>(_ body: (@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        body { result in
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}

func awaitResult<T>(_ body: (@escaping (T?, Error?) -> Void) -> Void) async throws -> T? {
    try await withCheckedThrowingContinuation { continuation in
        body { value, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            continuation.resume(returning: value)
        }
    }
}
