//
//  PrimerCheckoutSheet.swift
//
//
//  Created by Boris on 17.3.25..
//

import SwiftUI

/// Helper view for handling async view creation with error handling
@available(iOS 15.0, *)
private struct AsyncViewBuilder<Content: View>: View {
    @State private var content: Content?
    @State private var isLoading = true
    @State private var error: Error?
    private let asyncContent: () async throws -> Content

    init(@ViewBuilder asyncContent: @escaping () async throws -> Content) {
        self.asyncContent = asyncContent
    }

    var body: some View {
        Group {
            if let content = content {
                content
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Failed to load view")
                        .font(.caption)
                    Text(error.localizedDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if isLoading {
                ProgressView("Loading...")
            }
        }
        .task {
            do {
                content = try await asyncContent()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}

/// Default sheet UI for the Primer checkout experience with state-driven navigation.
@available(iOS 15.0, *)
struct PrimerCheckoutSheet: View, LogReporter {
    @ObservedObject var viewModel: PrimerCheckoutViewModel
    @StateObject private var coordinator: CheckoutCoordinator

    @Environment(\.designTokens) private var tokens
    @Environment(\.diContainer) private var container
    
    // Animation configuration
    private let animationConfig: NavigationAnimationConfiguration

    init(viewModel: PrimerCheckoutViewModel, coordinator: CheckoutCoordinator, animationConfig: NavigationAnimationConfiguration = .default) {
        self.viewModel = viewModel
        self._coordinator = StateObject(wrappedValue: coordinator)
        self.animationConfig = animationConfig
    }

    var body: some View {
        VStack(spacing: 0) {
            currentScreen
        }
        .background(tokens?.primerColorBackground ?? .white)
        .cornerRadius(12)
        .environmentObject(coordinator)
        .navigationScreenTransition(currentRoute: coordinator.currentRoute, config: animationConfig)
        .onAppear {
            logger.debug(message: "🎨 [PrimerCheckoutSheet] View appeared")
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        if let container = container {
            switch coordinator.currentRoute {
            case .splash:
                AsyncViewBuilder {
                    try await SplashView.create(container: container)
                }
                .transition(animationConfig.transition(from: .splash, to: coordinator.currentRoute))
                .navigationEntrance(delay: 0, config: animationConfig)
            case .paymentMethodsList:
                AsyncViewBuilder {
                    try await PaymentMethodsListScreen.create(container: container)
                }
                .transition(animationConfig.transition(from: getPreviousRoute(), to: coordinator.currentRoute))
                .navigationEntrance(delay: 0.1, config: animationConfig)
            case .paymentMethod(let method):
                AsyncViewBuilder {
                    try await PaymentMethodScreen.create(paymentMethod: method, container: container)
                }
                .transition(animationConfig.transition(from: getPreviousRoute(), to: coordinator.currentRoute))
                .navigationEntrance(delay: 0.05, config: animationConfig)
            case .success(let result):
                AsyncViewBuilder {
                    try await ResultScreen.create(result: .success(result), container: container)
                }
                .transition(animationConfig.transition(from: getPreviousRoute(), to: coordinator.currentRoute))
                .navigationEntrance(delay: 0.2, config: animationConfig)
                .navigationResultBounce(isSuccess: true, config: animationConfig)
            case .failure(let error):
                AsyncViewBuilder {
                    try await ResultScreen.create(result: .failure(error), container: container)
                }
                .transition(animationConfig.transition(from: getPreviousRoute(), to: coordinator.currentRoute))
                .navigationEntrance(delay: 0.2, config: animationConfig)
                .navigationResultBounce(isSuccess: false, config: animationConfig)
            }
        } else {
            VStack {
                ProgressView("Loading container...")
                    .navigationLoading(isLoading: true, config: animationConfig)
                Text("Initializing dependencies")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .transition(.opacity)
            .navigationEntrance(delay: 0, config: animationConfig)
        }
    }

    /// Helper method to determine the previous route for transition direction
    private func getPreviousRoute() -> CheckoutRoute {
        guard coordinator.navigationStack.count > 1 else {
            return .splash
        }
        return coordinator.navigationStack[coordinator.navigationStack.count - 2]
    }
    
    static func create(viewModel: PrimerCheckoutViewModel, container: ContainerProtocol, animationConfig: NavigationAnimationConfiguration = .default) async throws -> PrimerCheckoutSheet {
        let coordinator = try await container.resolve(CheckoutCoordinator.self)
        return PrimerCheckoutSheet(viewModel: viewModel, coordinator: coordinator, animationConfig: animationConfig)
    }
}
