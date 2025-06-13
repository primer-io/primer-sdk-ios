//
//  PrimerCheckout.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// Helper view for handling async view creation
@available(iOS 15.0, *)
private struct AsyncView<Content: View>: View {
    @State private var content: Content?
    @State private var isLoading = true
    private let asyncContent: () async -> Content

    init(@ViewBuilder asyncContent: @escaping () async -> Content) {
        self.asyncContent = asyncContent
    }

    var body: some View {
        Group {
            if let content = content {
                content
            } else if isLoading {
                ProgressView("Loading...")
            }
        }
        .task {
            content = await asyncContent()
            isLoading = false
        }
    }
}

@available(iOS 15.0, *)
private struct CheckoutContentView: View, LogReporter {
    @ObservedObject var viewModel: PrimerCheckoutViewModel
    let clientToken: String
    let successContent: (() -> AnyView)?
    let failureContent: ((ComponentsPrimerError) -> AnyView)?
    let content: ((PrimerCheckoutScope) -> AnyView)?

    var body: some View {
        if !viewModel.isClientTokenProcessed && viewModel.error == nil {
            ProgressView("Processing client token...")
                .onAppear {
                    Task {
                        await viewModel.processClientToken(clientToken)
                    }
                }
        } else if let error = viewModel.error {
            failureView(error: error)
        } else if viewModel.isCheckoutComplete {
            successView()
        } else {
            checkoutContent(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func checkoutContent(viewModel: PrimerCheckoutViewModel) -> some View {
        if let content = content {
            content(viewModel)
        } else {
            // Use the new async factory method to create sheet with navigation
            AsyncView {
                await createCheckoutSheet(viewModel: viewModel)
            }
        }
    }

    private func createCheckoutSheet(viewModel: PrimerCheckoutViewModel) async -> PrimerCheckoutSheet {
        do {
            // Get the DI container from environment
            guard let container = await DIContainer.current else {
                throw ContainerError.containerUnavailable
            }

            return try await PrimerCheckoutSheet.create(viewModel: viewModel, container: container, animationConfig: .default)
        } catch {
            // Fallback to creating coordinator manually if DI fails
            logger.warn(message: "⚠️ [PrimerCheckout] Failed to create checkout sheet with DI, using fallback: \(error.localizedDescription)")
            let fallbackContainer = DIContainer.createContainer()
            let coordinator = CheckoutCoordinator()
            return PrimerCheckoutSheet(viewModel: viewModel, coordinator: coordinator, animationConfig: .default)
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

/// The main entry point to Primer's component-based SDK for implementing checkout functionality.
@available(iOS 15.0, *)
public struct PrimerCheckout: View, LogReporter {
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
        logger.info(message: "🚀 [PrimerCheckout] Starting container setup")
        Task {
            logger.debug(message: "🔧 [PrimerCheckout] Configuring CompositionRoot")
            await CompositionRoot.configure()

            diContainer = await DIContainer.current
            logger.debug(message: "🔧 [PrimerCheckout] DI Container retrieved: \(diContainer != nil ? "✅ Available" : "❌ Nil")")

            // Resolve viewModel from DI container
            if let container = diContainer {
                do {
                    logger.debug(message: "🔍 [PrimerCheckout] Attempting to resolve PrimerCheckoutViewModel from DI")
                    let resolvedViewModel = try await container.resolve(PrimerCheckoutViewModel.self)
                    logger.info(message: "✅ [PrimerCheckout] Successfully resolved PrimerCheckoutViewModel from DI")
                    await MainActor.run {
                        viewModel = resolvedViewModel
                        logger.debug(message: "🎯 [PrimerCheckout] ViewModel assigned on MainActor")
                    }
                } catch {
                    logger.warn(message: "⚠️ [PrimerCheckout] Failed to resolve PrimerCheckoutViewModel from DI: \(error.localizedDescription)")
                    await MainActor.run {
                        // Create fallback viewModel with default dependencies
                        logger.debug(message: "🔄 [PrimerCheckout] Creating fallback ViewModel with default dependencies")
                        let taskManager = TaskManager()
                        let paymentMethodsProvider = DefaultPaymentMethodsProvider(container: container)
                        viewModel = PrimerCheckoutViewModel(
                            taskManager: taskManager,
                            paymentMethodsProvider: paymentMethodsProvider
                        )
                        logger.info(message: "✅ [PrimerCheckout] Fallback ViewModel created successfully")
                    }
                }
            } else {
                logger.error(message: "🚨 [PrimerCheckout] DI Container is nil - cannot create ViewModel")
            }
        }
    }

    public var body: some View {
        ZStack {
            if diContainer == nil || viewModel == nil {
                ProgressView("Initializing...")
                    .onAppear {
                        logger.info(message: "👁️ [PrimerCheckout] Initialization view appeared - starting setup")
                        setupContainer()
                    }
            } else if let viewModel = viewModel {
                CheckoutContentView(
                    viewModel: viewModel,
                    clientToken: clientToken,
                    successContent: successContent,
                    failureContent: failureContent,
                    content: content
                )
            }
        }
        .environment(\.diContainer, diContainer)
        .environment(\.designTokens, tokensManager.tokens)
        .task {
            if let viewModel = viewModel {
                do {
                    try await tokensManager.fetchTokens(for: colorScheme)
                } catch {
                    viewModel.setError(ComponentsPrimerError.designTokensError(error))
                }
            }
        }
    }

}
