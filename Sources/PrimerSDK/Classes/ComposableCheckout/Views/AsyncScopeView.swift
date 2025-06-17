//
//  AsyncScopeView.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI

/// A view that asynchronously resolves scopes from the DI container and provides them to the content
@available(iOS 15.0, *)
internal struct AsyncScopeView<Content: View>: View, LogReporter {
    
    // MARK: - Properties
    
    private let content: (
        _ checkoutScope: any PrimerCheckoutScope,
        _ cardFormScope: any CardFormScope,
        _ paymentSelectionScope: any PaymentMethodSelectionScope
    ) -> Content
    
    // MARK: - State
    
    @Environment(\.diContainer) private var diContainer
    @State private var scopes: ResolvedScopes?
    @State private var error: Error?
    @State private var isLoading = true
    
    // MARK: - Initialization
    
    init(
        @ViewBuilder content: @escaping (
            _ checkoutScope: any PrimerCheckoutScope,
            _ cardFormScope: any CardFormScope,
            _ paymentSelectionScope: any PaymentMethodSelectionScope
        ) -> Content
    ) {
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(error: error)
            } else if let scopes = scopes {
                content(
                    scopes.checkoutScope,
                    scopes.cardFormScope,
                    scopes.paymentSelectionScope
                )
            } else {
                ErrorView(error: AsyncScopeError.unexpectedState)
            }
        }
        .task {
            await resolveScopes()
        }
    }
    
    // MARK: - Private Methods
    
    private func resolveScopes() async {
        logger.debug(message: "🔄 [AsyncScopeView] Starting scope resolution")
        
        do {
            guard let container = diContainer else {
                throw AsyncScopeError.containerUnavailable
            }
            
            // Resolve all required scopes concurrently
            async let checkoutScopeTask = container.resolve(CheckoutViewModel.self)
            async let cardFormScopeTask = container.resolve(CardFormViewModel.self)
            async let paymentSelectionScopeTask = container.resolve(PaymentMethodSelectionViewModel.self)
            
            let (checkoutScope, cardFormScope, paymentSelectionScope) = try await (
                checkoutScopeTask,
                cardFormScopeTask,
                paymentSelectionScopeTask
            )
            
            await MainActor.run {
                self.scopes = ResolvedScopes(
                    checkoutScope: checkoutScope,
                    cardFormScope: cardFormScope,
                    paymentSelectionScope: paymentSelectionScope
                )
                self.isLoading = false
                logger.info(message: "✅ [AsyncScopeView] All scopes resolved successfully")
            }
            
        } catch {
            await MainActor.run {
                logger.error(message: "❌ [AsyncScopeView] Failed to resolve scopes: \(error.localizedDescription)")
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Initializing Checkout...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private func ErrorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Failed to Initialize Checkout")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await MainActor.run {
                        isLoading = true
                        error = nil
                        scopes = nil
                    }
                    await resolveScopes()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Resolved Scopes Container
    
    private struct ResolvedScopes {
        let checkoutScope: any PrimerCheckoutScope
        let cardFormScope: any CardFormScope
        let paymentSelectionScope: any PaymentMethodSelectionScope
    }
}

// MARK: - Async Scope Errors

internal enum AsyncScopeError: Error, LocalizedError {
    case containerUnavailable
    case unexpectedState
    
    var errorDescription: String? {
        switch self {
        case .containerUnavailable:
            return "Dependency injection container is not available"
        case .unexpectedState:
            return "Unexpected state during scope resolution"
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct AsyncScopeView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncScopeView { checkoutScope, cardFormScope, paymentSelectionScope in
            VStack {
                Text("Scopes Resolved Successfully!")
                    .font(.headline)
                
                Text("Checkout: \(String(describing: type(of: checkoutScope)))")
                Text("Card Form: \(String(describing: type(of: cardFormScope)))")
                Text("Payment Selection: \(String(describing: type(of: paymentSelectionScope)))")
            }
            .padding()
        }
        .environment(\.diContainer, MockDIContainer())
    }
}

// MARK: - Mock DI Container for Preview

@available(iOS 15.0, *)
private class MockDIContainer: DIContainerProtocol {
    func resolve<T>(_ type: T.Type) async throws -> T {
        throw ContainerError.typeNotRegistered(String(describing: type))
    }
    
    func isRegistered<T>(_ type: T.Type) async -> Bool {
        false
    }
    
    func getDiagnostics() async -> ContainerDiagnostics {
        ContainerDiagnostics(
            registeredTypes: [],
            singletonCount: 0,
            weakReferenceCount: 0,
            transientResolutions: 0
        )
    }
    
    func performHealthCheck() async -> ContainerHealthReport {
        ContainerHealthReport(
            isHealthy: false,
            issues: ["Mock container for preview"],
            performanceMetrics: [:]
        )
    }
}