//
//  PrimerCheckoutScope.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Main checkout scope that provides access to overall checkout state and lifecycle.
/// This matches Android's PrimerCheckoutScope interface.
@available(iOS 15.0, *)
public protocol PrimerCheckoutScope: ObservableObject {
    
    /// Reactive state stream for the checkout process
    var state: AnyPublisher<CheckoutState, Never> { get }
    
    /// Initialize the checkout process
    func initialize()
    
    /// Cleanup resources when checkout is dismissed
    func cleanup()
}

// MARK: - Extension Functions (matches Android's companion object approach)

@available(iOS 15.0, *)
public extension PrimerCheckoutScope {
    
    /// Default loading screen component
    @ViewBuilder
    func PrimerLoadingScreen() -> some View {
        DefaultLoadingScreen()
    }
    
    /// Default error screen component
    @ViewBuilder
    func PrimerErrorScreen() -> some View {
        DefaultErrorScreen(message: "An error occurred")
    }
    
    /// Default success screen component
    @ViewBuilder
    func PrimerSuccessScreen() -> some View {
        DefaultSuccessScreen()
    }
}

// MARK: - State Model

/// Internal state model for scope implementation
internal enum ScopeCheckoutState {
    case notInitialized
    case initializing
    case ready
    case error(Error)
}

// MARK: - Default Implementation (Temporary)

/// Temporary default implementation for testing
@available(iOS 15.0, *)
internal class DefaultPrimerCheckoutScope: PrimerCheckoutScope, LogReporter {
    
    @Published private var _internalState: ScopeCheckoutState = .notInitialized
    
    public var state: AnyPublisher<CheckoutState, Never> {
        $_internalState
            .map { internalState in
                switch internalState {
                case .notInitialized:
                    return CheckoutState.notInitialized
                case .initializing:
                    return CheckoutState.initializing
                case .ready:
                    return CheckoutState.ready
                case .error(let error):
                    return CheckoutState.error(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    public func initialize() {
        logger.debug(message: "🚀 [DefaultPrimerCheckoutScope] Initializing checkout")
        _internalState = .initializing
        
        // Simulate initialization
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                _internalState = .ready
            }
        }
    }
    
    public func cleanup() {
        logger.debug(message: "🧹 [DefaultPrimerCheckoutScope] Cleaning up checkout")
        _internalState = .notInitialized
    }
}