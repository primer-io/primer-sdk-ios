//
//  AsyncStream+Extension.swift
//
//
//  Created by Boris on 17.3.25..
//


extension AsyncStream {
    /// Creates an AsyncStream that emits the current value and then terminates.
    /// Useful for one-time values that don't need continuous observation.
    static func just(_ value: Element) -> AsyncStream<Element> {
        return AsyncStream { continuation in
            continuation.yield(value)
            continuation.finish()
        }
    }
    
    /// Creates an AsyncStream that immediately completes with an error.
    static func failure<E: Error>(_ error: E) -> AsyncStream<Element> where Element == Result<Any, E> {
        return AsyncStream { continuation in
            continuation.yield(.failure(error))
            continuation.finish()
        }
    }
}

extension AsyncStream where Element: Equatable {
    /// Creates an AsyncStream that distinctly emits values when they change.
    /// Similar to the distinctUntilChanged operator in Combine.
    static func distinctUntilChanged(
        _ source: AsyncStream<Element>
    ) -> AsyncStream<Element> {
        return AsyncStream { continuation in
            Task {
                var lastValue: Element?
                for await value in source {
                    if lastValue == nil || lastValue != value {
                        continuation.yield(value)
                        lastValue = value
                    }
                }
                continuation.finish()
            }
        }
    }
}
