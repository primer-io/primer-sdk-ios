//
//  PrimerCheckout.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// The main entry point to Primer's component-based SDK for implementing checkout functionality.
@available(iOS 15.0, *)
public struct PrimerCheckout: View {
    private let clientToken: String
    private let successContent: (() -> AnyView)?
    private let failureContent: ((ComponentsPrimerError) -> AnyView)?
    private let content: ((PrimerCheckoutScope) -> AnyView)?

    @State private var viewModel: PrimerCheckoutViewModel?
    @StateObject private var tokensManager = DesignTokensManager()
    @Environment(\.colorScheme) private var colorScheme
    @State private var diContainer: (any ContainerProtocol)?

    /// Creates a new PrimerCheckout instance with default UI.
    ///
    /// - Parameter clientToken: The client token required for API authorization.
    public init(clientToken: String) {
        self.clientToken = clientToken
        self.successContent = nil
        self.failureContent = nil
        self.content = nil
    }

    /// Creates a new PrimerCheckout instance with customization options.
    ///
    /// - Parameters:
    ///   - clientToken: The client token required for API authorization.
    ///   - successContent: An optional view that displays when checkout completes successfully.
    ///   - failureContent: An optional view that displays when checkout fails.
    ///   - content: An optional view that completely overrides the default checkout flow.
    public init(
        clientToken: String,
        successContent: (() -> AnyView)? = nil,
        failureContent: ((ComponentsPrimerError) -> AnyView)? = nil,
        content: ((PrimerCheckoutScope) -> AnyView)? = nil
    ) {
        self.clientToken = clientToken
        self.successContent = successContent
        self.failureContent = failureContent
        self.content = content
    }

    private func setupContainer() {
        Task {
            await CompositionRoot.configure()
            diContainer = await DIContainer.current

            // Resolve viewModel from DI container
            if let container = diContainer {
                do {
                    let resolvedViewModel = try await container.resolve(PrimerCheckoutViewModel.self)
                    await MainActor.run {
                        viewModel = resolvedViewModel
                    }
                } catch {
                    await MainActor.run {
                        // Create fallback viewModel with default dependencies
                        let taskManager = TaskManager()
                        let paymentMethodsProvider = DefaultPaymentMethodsProvider(container: container)
                        viewModel = PrimerCheckoutViewModel(
                            taskManager: taskManager,
                            paymentMethodsProvider: paymentMethodsProvider
                        )
                    }
                }
            }
        }
    }

    public var body: some View {
        ZStack {
            if diContainer == nil || viewModel == nil {
                ProgressView("Initializing...")
                    .onAppear {
                        setupContainer()
                    }
            } else if let vm = viewModel {
                if !vm.isClientTokenProcessed {
                    ProgressView("Processing client token...")
                        .onAppear {
                            Task {
                                await vm.processClientToken(clientToken)
                            }
                        }
                } else if let error = vm.error {
                    failureView(error: error)
                } else if vm.isCheckoutComplete {
                    successView()
                } else {
                    checkoutContent(viewModel: vm)
                }
            }
        }
        .environment(\.diContainer, diContainer)
        .environment(\.designTokens, tokensManager.tokens)
        .task {
            if let vm = viewModel {
                do {
                    try await tokensManager.fetchTokens(for: colorScheme)
                } catch {
                    vm.setError(ComponentsPrimerError.designTokensError(error))
                }
            }
        }
    }

    @ViewBuilder
    private func checkoutContent(viewModel: PrimerCheckoutViewModel) -> some View {
        if let content = content {
            content(viewModel)
        } else {
            PrimerCheckoutSheet(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func successView() -> some View {
        if let successContent = successContent {
            successContent()
        } else {
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.green)
                Text("Payment Completed")
                    .font(.title)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func failureView(error: ComponentsPrimerError) -> some View {
        if let failureContent = failureContent {
            failureContent(error)
        } else {
            VStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.red)
                Text("Payment Failed")
                    .font(.title)
                    .padding()
                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}
