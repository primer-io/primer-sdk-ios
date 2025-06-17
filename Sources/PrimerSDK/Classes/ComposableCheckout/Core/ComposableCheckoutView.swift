//
//  ComposableCheckoutView.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Internal view that implements the ComposableCheckout functionality.
/// This view manages the navigation between different checkout screens
/// and provides the appropriate scopes to each screen.
@available(iOS 15.0, *)
internal struct ComposableCheckoutView<Container: View>: View, LogReporter {
    
    // MARK: - Properties
    
    /// Custom container for the entire checkout flow
    let container: ((AnyView) -> Container)?
    
    /// Custom screen implementations
    let splashScreen: ((PrimerCheckoutScope) -> AnyView)?
    let loadingScreen: ((PrimerCheckoutScope) -> AnyView)?
    let paymentSelectionScreen: ((PaymentMethodSelectionScope) -> AnyView)?
    let cardFormScreen: ((CardFormScope) -> AnyView)?
    let successScreen: ((PrimerCheckoutScope) -> AnyView)?
    let errorScreen: ((PrimerCheckoutScope, String) -> AnyView)?
    
    // MARK: - State Management
    
    @State private var currentScreen: CheckoutScreen = .splash
    @State private var errorMessage: String = ""
    @State private var isContainerReady = false
    
    // MARK: - View Body
    
    var body: some View {
        Group {
            if isContainerReady {
                checkoutContent
            } else {
                loadingView
            }
        }
        .task {
            await initializeContainer()
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var checkoutContent: some View {
        let content = AnyView(actualCheckoutContent)
        
        if let container = container {
            container(content)
        } else {
            defaultContainer(content)
        }
    }
    
    @ViewBuilder
    private var actualCheckoutContent: some View {
        switch currentScreen {
        case .splash:
            splashScreenView
        case .loading:
            loadingScreenView
        case .paymentSelection:
            paymentSelectionScreenView
        case .cardForm:
            cardFormScreenView
        case .success:
            successScreenView
        case .error:
            errorScreenView
        }
    }
    
    @ViewBuilder
    private var splashScreenView: some View {
        if let splashScreen = splashScreen {
            AsyncScopeView { container in
                let scope = try await container.resolve(CheckoutViewModel.self)
                return splashScreen(scope)
            }
        } else {
            DefaultSplashScreen()
        }
    }
    
    @ViewBuilder
    private var loadingScreenView: some View {
        if let loadingScreen = loadingScreen {
            AsyncScopeView { container in
                let scope = try await container.resolve(CheckoutViewModel.self)
                return loadingScreen(scope)
            }
        } else {
            DefaultLoadingScreen()
        }
    }
    
    @ViewBuilder
    private var paymentSelectionScreenView: some View {
        if let paymentSelectionScreen = paymentSelectionScreen {
            AsyncScopeView { container in
                let scope = try await container.resolve(PaymentMethodSelectionViewModel.self)
                return paymentSelectionScreen(scope)
            }
        } else {
            DefaultPaymentSelectionScreen()
        }
    }
    
    @ViewBuilder
    private var cardFormScreenView: some View {
        if let cardFormScreen = cardFormScreen {
            AsyncScopeView { container in
                let scope = try await container.resolve(CardFormViewModel.self)
                return cardFormScreen(scope)
            }
        } else {
            DefaultCardFormScreen()
        }
    }
    
    @ViewBuilder
    private var successScreenView: some View {
        if let successScreen = successScreen {
            AsyncScopeView { container in
                let scope = try await container.resolve(CheckoutViewModel.self)
                return successScreen(scope)
            }
        } else {
            DefaultSuccessScreen()
        }
    }
    
    @ViewBuilder
    private var errorScreenView: some View {
        if let errorScreen = errorScreen {
            AsyncScopeView { container in
                let scope = try await container.resolve(CheckoutViewModel.self)
                return errorScreen(scope, errorMessage)
            }
        } else {
            DefaultErrorScreen(message: errorMessage)
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Initializing Checkout...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    @ViewBuilder
    private func defaultContainer(_ content: AnyView) -> some View {
        // Default presentation as a sheet
        content
            .presentationDragIndicator(.visible)
    }
    
    // MARK: - Private Methods
    
    /// Initialize the DI container and prepare for checkout
    private func initializeContainer() async {
        logger.debug(message: "🚀 [ComposableCheckoutView] Initializing container")
        
        do {
            // Ensure configuration exists
            guard let config = Primer.configuration else {
                logger.error(message: "❌ [ComposableCheckoutView] No configuration found - call Primer.configure() first")
                errorMessage = "Configuration missing. Please call Primer.configure() first."
                currentScreen = .error
                isContainerReady = true
                return
            }
            
            // Initialize existing DI container with our new components
            await CompositionRoot.configure()
            
            // TODO: Initialize with client token from config
            logger.debug(message: "🔧 [ComposableCheckoutView] Processing client token: \(config.clientToken.prefix(8))...")
            
            await MainActor.run {
                currentScreen = .loading
                isContainerReady = true
            }
            
            // Simulate initialization process
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                currentScreen = .paymentSelection
            }
            
            logger.info(message: "✅ [ComposableCheckoutView] Initialization completed")
            
        } catch {
            logger.error(message: "❌ [ComposableCheckoutView] Initialization failed: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                currentScreen = .error
                isContainerReady = true
            }
        }
    }
}

// MARK: - Helper Views

/// Helper view for asynchronously resolving scopes from DI container
@available(iOS 15.0, *)
internal struct AsyncScopeView<Content: View>: View, LogReporter {
    private let scopeProvider: (Container) async throws -> Content
    
    @State private var content: Content?
    @State private var isLoading = true
    @State private var error: Error?
    
    init(@ViewBuilder scopeProvider: @escaping (Container) async throws -> Content) {
        self.scopeProvider = scopeProvider
    }
    
    var body: some View {
        Group {
            if let content = content {
                content
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Failed to load scope: \(error.localizedDescription)")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if isLoading {
                ProgressView("Loading scope...")
                    .font(.caption)
            }
        }
        .task {
            await loadScope()
        }
    }
    
    private func loadScope() async {
        do {
            guard let container = await DIContainer.current else {
                throw ContainerError.containerUnavailable
            }
            
            let resolvedContent = try await scopeProvider(container)
            
            await MainActor.run {
                self.content = resolvedContent
                self.isLoading = false
            }
            
        } catch {
            logger.error(message: "❌ [AsyncScopeView] Failed to resolve scope: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

// MARK: - Screen Navigation

/// Enum representing different checkout screens
internal enum CheckoutScreen {
    case splash
    case loading
    case paymentSelection
    case cardForm
    case success
    case error
}

// MARK: - Default Screen Implementations

/// Default splash screen implementation
@available(iOS 15.0, *)
internal struct DefaultSplashScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Primer Checkout")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

/// Default loading screen implementation
@available(iOS 15.0, *)
internal struct DefaultLoadingScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading Payment Methods...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// Default payment selection screen implementation
@available(iOS 15.0, *)
internal struct DefaultPaymentSelectionScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Payment Method")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PaymentMethodButton(
                    title: "Credit Card",
                    icon: "creditcard.fill",
                    action: {
                        // TODO: Navigate to card form
                    }
                )
                
                PaymentMethodButton(
                    title: "Apple Pay",
                    icon: "applelogo",
                    action: {
                        // TODO: Handle Apple Pay
                    }
                )
            }
        }
        .padding()
    }
}

/// Default card form screen implementation
@available(iOS 15.0, *)
internal struct DefaultCardFormScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Card Details")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Card form will use existing CardNumberInputField, CVVInputField, etc.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // TODO: Use existing card input components through wrappers
        }
        .padding()
    }
}

/// Default success screen implementation
@available(iOS 15.0, *)
internal struct DefaultSuccessScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Payment Successful")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your payment has been processed successfully.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// Default error screen implementation
@available(iOS 15.0, *)
internal struct DefaultErrorScreen: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Payment Failed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// Simple payment method button
@available(iOS 15.0, *)
internal struct PaymentMethodButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}