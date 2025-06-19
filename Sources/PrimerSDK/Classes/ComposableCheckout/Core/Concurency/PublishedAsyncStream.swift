//
//  PublishedAsyncStream.swift
//
//
//  Created on 19.06.2025.
//

import SwiftUI
import Combine

/// Utility to convert @Published properties to AsyncStream
/// This enables bridging between Combine (internal) and AsyncStream (public API)
@available(iOS 15.0, *)
internal struct PublishedAsyncStream {
    
    /// Converts a @Published property to an AsyncStream
    /// - Parameter publisher: The published property's publisher
    /// - Returns: An AsyncStream that emits the same values as the publisher
    static func create<T>(from publisher: Published<T>.Publisher) -> AsyncStream<T> {
        AsyncStream { continuation in
            let cancellable = publisher
                .sink { value in
                    continuation.yield(value)
                }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    /// Converts an AnyPublisher to an AsyncStream
    /// - Parameter publisher: Any publisher that emits values
    /// - Returns: An AsyncStream that emits the same values as the publisher
    static func create<T>(from publisher: AnyPublisher<T, Never>) -> AsyncStream<T> {
        AsyncStream { continuation in
            let cancellable = publisher
                .sink { value in
                    continuation.yield(value)
                }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    /// Creates an AsyncStream from a @Published property with proper lifecycle management
    /// - Parameters:
    ///   - object: The object containing the @Published property
    ///   - keyPath: KeyPath to the @Published property
    /// - Returns: An AsyncStream that emits values from the @Published property
    static func create<Object: ObservableObject, T>(
        from object: Object,
        keyPath: KeyPath<Object, T>
    ) -> AsyncStream<T> where Object.ObjectWillChangePublisher == ObservableObjectPublisher {
        AsyncStream { continuation in
            // Yield initial value
            continuation.yield(object[keyPath: keyPath])
            
            // Subscribe to changes
            let cancellable = object.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    continuation.yield(object[keyPath: keyPath])
                }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

/// Extension for easier usage with ViewModels
@available(iOS 15.0, *)
internal extension ObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher {
    
    /// Creates an AsyncStream from a keyPath to a property
    /// - Parameter keyPath: KeyPath to the property to observe
    /// - Returns: AsyncStream that emits values when the property changes
    func asyncStream<T>(for keyPath: KeyPath<Self, T>) -> AsyncStream<T> {
        PublishedAsyncStream.create(from: self, keyPath: keyPath)
    }
}