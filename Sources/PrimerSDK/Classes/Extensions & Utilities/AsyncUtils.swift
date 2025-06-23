extension Promise {
    func async() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
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
            case .success(let value): continuation.resume(returning: value)
            case .failure(let error): continuation.resume(throwing: error)
            }
        }
    }
}

func awaitResult<T>(_ body: (@escaping (T?, Error?) -> Void) -> Void) async throws -> T? {
    try await withCheckedThrowingContinuation { continuation in
        body { value, error in
            if let error {
                return continuation.resume(throwing: error)
            }
            continuation.resume(returning: value)
        }
    }
}

func awaitResult<T>(_ body: (@escaping (Result<T, Error>, [String: String]?) -> Void) -> Void) async throws -> (T, [String: String]?) {
    try await withCheckedThrowingContinuation { continuation in
        body { result, headers in
            switch result {
            case .success(let value): continuation.resume(returning: (value, headers))
            case .failure(let error): continuation.resume(throwing: error)
            }
        }
    }
}
