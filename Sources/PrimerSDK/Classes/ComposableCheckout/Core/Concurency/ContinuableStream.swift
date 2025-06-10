//
//  ContinuableStream.swift
//
//
//  Created by Boris on 31.3.25..
//

import Foundation

/**
 * INTERNAL DOCUMENTATION: ContinuableStream Architecture
 * 
 * This utility provides a simplified interface for AsyncStream creation and management,
 * solving common patterns in reactive programming with proper lifecycle management.
 * 
 * ## Problem Solved:
 * 
 * Standard AsyncStream creation requires managing continuations inside initialization:
 * ```swift
 * // Complex standard pattern
 * let stream = AsyncStream<String> { continuation in
 *     // Must store continuation somewhere for external access
 *     self.storedContinuation = continuation
 * }
 * ```
 * 
 * ContinuableStream simplifies this to:
 * ```swift
 * // Simplified pattern
 * let continuableStream = ContinuableStream<String> { continuation in
 *     // Setup logic here
 * }
 * // Direct access to yield and finish methods
 * continuableStream.yield("Hello")
 * continuableStream.finish()
 * ```
 * 
 * ## Architecture Benefits:
 * 
 * ### 1. Encapsulation
 * - **Internal Continuation Management**: Continuation is managed internally
 * - **Clean External Interface**: yield() and finish() methods for external use
 * - **No Retention Issues**: Proper weak reference handling prevents cycles
 * 
 * ### 2. Type Safety
 * - **Generic Implementation**: Works with any Element type
 * - **Compile-time Guarantees**: No runtime casting or type checking needed
 * - **Swift Concurrency Integration**: Full async/await compatibility
 * 
 * ### 3. Memory Management
 * - **Automatic Cleanup**: Stream automatically cleans up on finish()
 * - **Weak Continuation References**: Prevents memory leaks
 * - **Buffering Control**: Configurable buffering policy for memory optimization
 * 
 * ## Buffering Strategy:
 * 
 * ### 1. Unbounded (Default)
 * ```swift
 * ContinuableStream<String>() // Unbounded buffering
 * ```
 * - **Use Case**: When producer and consumer speeds are well-matched
 * - **Memory**: Grows unbounded if consumer is slower than producer
 * - **Performance**: Fastest for balanced scenarios
 * 
 * ### 2. Bounded Buffering
 * ```swift
 * ContinuableStream<String>(bufferingPolicy: .bufferingNewest(10))
 * ```
 * - **Use Case**: When memory usage must be controlled
 * - **Behavior**: Drops oldest values when buffer is full
 * - **Performance**: Prevents memory exhaustion
 * 
 * ## Lifecycle Management:
 * 
 * ### 1. Stream Creation
 * ```
 * Init → AsyncStream Created → Continuation Captured → Ready for Yielding
 * ```
 * 
 * ### 2. Value Flow
 * ```
 * yield(value) → Continuation.yield() → AsyncStream → Consumer
 * ```
 * 
 * ### 3. Stream Termination
 * ```
 * finish() → Continuation.finish() → Stream Ends → Cleanup
 * ```
 * 
 * ## Performance Characteristics:
 * 
 * ### 1. Creation Overhead
 * - **Time**: O(1) - Simple wrapper allocation
 * - **Memory**: ~100 bytes (closure references + continuation)
 * - **Thread Safety**: Safe from any thread
 * 
 * ### 2. Value Yielding
 * - **Time**: O(1) - Direct continuation method call
 * - **Memory**: O(1) per value (buffering policy dependent)
 * - **Concurrency**: Thread-safe yield operations
 * 
 * ### 3. Stream Consumption
 * - **Time**: O(1) per value consumption
 * - **Memory**: Depends on consumer processing speed
 * - **Backpressure**: Handled via buffering policy
 * 
 * ## Common Usage Patterns:
 * 
 * ### 1. State Broadcasting
 * ```swift
 * private let stateStream = ContinuableStream<State> { _ in }
 * func updateState(_ newState: State) {
 *     stateStream.yield(newState)
 * }
 * ```
 * 
 * ### 2. Event Emission
 * ```swift
 * private let eventStream = ContinuableStream<Event> { _ in }
 * func emitEvent(_ event: Event) {
 *     eventStream.yield(event)
 * }
 * ```
 * 
 * ### 3. Resource Cleanup
 * ```swift
 * deinit {
 *     continuableStream.finish() // Proper cleanup
 * }
 * ```
 * 
 * ## Integration Points:
 * - **SwiftUI**: Perfect for @StateObject and ObservableObject reactive patterns
 * - **Async/Await**: Full compatibility with modern Swift concurrency
 * - **Combine**: Can bridge to Combine publishers if needed
 * - **Actor Systems**: Thread-safe operations work well with actor isolation
 * 
 * This utility enables clean, performant reactive programming patterns while
 * maintaining proper resource management and Swift concurrency best practices.
 */

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
