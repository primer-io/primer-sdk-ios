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

    @StateObject private var viewModel = PrimerCheckoutViewModel()
    @StateObject private var tokensManager = DesignTokensManager()
    @Environment(\.colorScheme) private var colorScheme

    /// Creates a new PrimerCheckout instance with default UI.
    ///
    /// - Parameter clientToken: The client token required for API authorization.
    public init(clientToken: String) {
        self.clientToken = clientToken
        self.successContent = nil
        self.failureContent = nil
        self.content = nil
        self.setupContainer()
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
        self.setupContainer()
    }

    private func setupContainer() {
        Task {
            await DIContainer.setupMainContainer()
        }
    }

    public var body: some View {
        ZStack {
            if !viewModel.isClientTokenProcessed {
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
                checkoutContent()
            }
        }
        .task {
            do {
                try await tokensManager.fetchTokens(for: colorScheme)
            } catch {
                viewModel.setError(ComponentsPrimerError.designTokensError(error))
            }
        }
        .environment(\.designTokens, tokensManager.tokens)
    }

    @ViewBuilder
    private func checkoutContent() -> some View {
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
