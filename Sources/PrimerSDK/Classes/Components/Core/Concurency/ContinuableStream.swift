//
//  ContinuableStream.swift
//
//
//  Created by Boris on 31.3.25..
//

import Foundation

/// A wrapper around AsyncStream that provides direct access to the continuation
/// for easily yielding values to the stream outside of its initialization.
struct ContinuableStream<Element> {
    /// The AsyncStream that consumers can subscribe to
    let stream: AsyncStream<Element>

    /// Function to yield values to the stream
    let yield: (Element) -> Void

    /// Function to finish the stream
    let finish: () -> Void

    /// Creates a new ContinuableStream with the given buffering policy and build closure
    /// - Parameters:
    ///   - bufferingPolicy: Policy determining how values are buffered (defaults to unbounded)
    ///   - build: A closure that receives the AsyncStream continuation
    init(
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
        build: @escaping (AsyncStream<Element>.Continuation) -> Void
    ) {
        var localContinuation: AsyncStream<Element>.Continuation?
        self.stream = AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            localContinuation = continuation
            build(continuation)
        }
        self.yield = { element in
            localContinuation?.yield(element)
        }
        self.finish = {
            localContinuation?.finish()
        }
    }
}
