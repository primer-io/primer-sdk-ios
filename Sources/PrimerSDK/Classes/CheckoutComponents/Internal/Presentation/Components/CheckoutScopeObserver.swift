//
//  CheckoutScopeObserver.swift
//  PrimerSDK
//
//  Created by Boris on 15.7.25.
//

import SwiftUI

// MARK: - Checkout Scope Observer

/// Wrapper view that properly observes the DefaultCheckoutScope as an ObservableObject
@available(iOS 15.0, *)
internal struct CheckoutScopeObserver: View, LogReporter {
    @ObservedObject private var scope: DefaultCheckoutScope
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let scopeCustomization: ((PrimerCheckoutScope) -> Void)?
    private let onCompletion: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Design tokens state
    @State private var designTokens: DesignTokens?
    @State private var designTokensManager: DesignTokensManager?

    init(scope: DefaultCheckoutScope, customContent: ((PrimerCheckoutScope) -> AnyView)?, scopeCustomization: ((PrimerCheckoutScope) -> Void)?, onCompletion: (() -> Void)?) {
        self.scope = scope
        self.customContent = customContent
        self.scopeCustomization = scopeCustomization
        self.onCompletion = onCompletion
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation state driven UI (now properly observing @Published navigationState)
                ZStack {
                    switch scope.navigationState {
                    case .loading:
                        if let customLoading = scope.loadingScreen {
                            AnyView(customLoading())
                        } else {
                            AnyView(LoadingScreen())
                        }

                    case .paymentMethodSelection:
                        if let customPaymentSelection = scope.paymentMethodSelectionScreen {
                            AnyView(customPaymentSelection(scope.paymentMethodSelection))
                        } else {
                            AnyView(PaymentMethodSelectionScreen(
                                scope: scope.paymentMethodSelection
                            ))
                        }

                    case .paymentMethod(let paymentMethodType):
                        // Handle all payment method types using truly unified dynamic approach
                        PaymentMethodScreen(
                            paymentMethodType: paymentMethodType,
                            checkoutScope: scope
                        )

                    case .success(let result):
                        if let customSuccess = scope.successScreen {
                            AnyView(customSuccess(result))
                        } else {
                            AnyView(SuccessScreen(result: result) {
                                // Handle auto-dismiss with completion callback
                                logger.info(message: "Success screen auto-dismiss, calling completion callback")
                                onCompletion?()
                            })
                        }

                    case .failure(let error):
                        if let customError = scope.errorScreen {
                            AnyView(customError(error.localizedDescription))
                        } else {
                            AnyView(ErrorScreen(error: error) {
                                // Handle auto-dismiss with completion callback
                                logger.info(message: "Error screen auto-dismiss, calling completion callback")
                                onCompletion?()
                            })
                        }

                    case .dismissed:
                        // Handle dismissal - call completion callback to properly dismiss SwiftUI sheets
                        AnyView(VStack {
                            Text("Dismissing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .onAppear {
                            logger.info(message: "Checkout dismissed, calling completion callback")
                            DispatchQueue.main.async {
                                onCompletion?()
                            }
                        })
                    }

                    // Custom content overlay if provided
                    if let customContent = customContent {
                        customContent(scope)
                    }
                }
            }
            .environmentObject(scope)
            .environment(\.diContainer, DIContainer.currentSync)
            .environment(\.designTokens, designTokens)
        }
        .onAppear {
            // Apply any scope customizations (only after SDK is initialized)
            scopeCustomization?(scope)

            // Set up design tokens
            Task {
                await setupDesignTokens()
            }
        }
        .onChange(of: colorScheme) { newColorScheme in
            // Reload design tokens when color scheme changes
            Task {
                await loadDesignTokens(for: newColorScheme)
            }
        }
    }

    // MARK: - Design Token Management

    private func setupDesignTokens() async {
        logger.info(message: "🎨 [DesignTokens] Setting up design tokens...")
        do {
            guard let container = await DIContainer.current else {
                logger.warn(message: "🎨 [DesignTokens] DI Container not available for design tokens")
                return
            }

            designTokensManager = try await container.resolve(DesignTokensManager.self)
            logger.info(message: "🎨 [DesignTokens] DesignTokensManager resolved successfully")
            await loadDesignTokens(for: colorScheme)
        } catch {
            logger.error(message: "🎨 [DesignTokens] Failed to setup design tokens: \(error)")
        }
    }

    private func loadDesignTokens(for colorScheme: ColorScheme) async {
        guard let manager = designTokensManager else {
            logger.warn(message: "🎨 [DesignTokens] DesignTokensManager not available")
            return
        }

        logger.info(message: "🎨 [DesignTokens] Loading design tokens for color scheme: \(colorScheme == .dark ? "dark" : "light")")
        do {
            try await manager.fetchTokens(for: colorScheme)
            await MainActor.run {
                designTokens = manager.tokens
                logger.info(message: "🎨 [DesignTokens] Design tokens loaded successfully")

                // Log the specific focus border color for debugging
                if let focusColor = designTokens?.primerColorBorderOutlinedFocus {
                    logger.info(message: "🎨 [DesignTokens] Focus border color: \(focusColor)")
                } else {
                    logger.warn(message: "🎨 [DesignTokens] Focus border color not found in design tokens!")
                }

                // Log the brand color for comparison
                if let brandColor = designTokens?.primerColorBrand {
                    logger.info(message: "🎨 [DesignTokens] Brand color: \(brandColor)")
                } else {
                    logger.warn(message: "🎨 [DesignTokens] Brand color not found in design tokens!")
                }
            }
        } catch {
            logger.error(message: "🎨 [DesignTokens] Failed to load design tokens: \(error)")
        }
    }
}
