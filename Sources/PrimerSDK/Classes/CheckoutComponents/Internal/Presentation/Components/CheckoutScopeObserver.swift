//
//  CheckoutScopeObserver.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerUI

// MARK: - Checkout Scope Observer

/// Wrapper view that properly observes the DefaultCheckoutScope as an ObservableObject
@available(iOS 15.0, *)
struct CheckoutScopeObserver: View, LogReporter {
    @ObservedObject private var scope: DefaultCheckoutScope
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let scopeCustomization: ((PrimerCheckoutScope) -> Void)?
    private let onCompletion: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    // Design tokens state
    @State private var designTokens: DesignTokens?
    @State private var designTokensManager: DesignTokensManager?

    // Country selection modal state
    @State private var showingCountrySelection = false
    @State private var previousNavigationState: DefaultCheckoutScope.NavigationState?

    init(scope: DefaultCheckoutScope,
         customContent: ((PrimerCheckoutScope) -> AnyView)?,
         scopeCustomization: ((PrimerCheckoutScope) -> Void)?,
         onCompletion: (() -> Void)?) {
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
                    // MARK: - Navigation Content
                    // Simple fade transition between screens
                    // TODO: Future improvements could include:
                    // - Respect UIAccessibility.isReduceMotionEnabled for users with motion sensitivity
                    // - Add directional transitions (slide left/right) based on navigation direction
                    // - Implement custom per-route transitions (e.g., scale for success screen)
                    // - Add interactive gesture-based navigation
                    getCurrentView()
                        .animation(.easeInOut(duration: 0.3), value: scope.navigationState)

                    // Custom content overlay if provided
                    if let customContent = customContent {
                        customContent(scope)
                    }
                }
                .sheet(isPresented: $showingCountrySelection) {
                    // Present country selection as a modal sheet
                    let cardFormScope = scope.getPaymentMethodScope(DefaultCardFormScope.self)
                    let countryScope = DefaultSelectCountryScope(cardFormScope: cardFormScope, checkoutScope: scope)
                    SelectCountryScreen(
                        scope: countryScope,
                        onDismiss: {
                            showingCountrySelection = false
                            // Restore previous navigation state after dismissal
                            if let previousState = previousNavigationState {
                                scope.updateNavigationState(previousState, syncToNavigator: false)
                            }
                        }
                    )
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
        .onChange(of: scope.navigationState) { newNavigationState in
            // Handle modal presentation for country selection
            if case .selectCountry = newNavigationState {
                // Store the previous state if it's not already country selection
                let isAlreadyCountrySelection: Bool
                if let prev = previousNavigationState {
                    if case .selectCountry = prev {
                        isAlreadyCountrySelection = true
                    } else {
                        isAlreadyCountrySelection = false
                    }
                } else {
                    isAlreadyCountrySelection = false
                }

                if !isAlreadyCountrySelection {
                    previousNavigationState = findPreviousNonCountryState()
                }
                showingCountrySelection = true
            } else {
                // Update previous state for tracking (don't track selectCountry)
                if case .selectCountry = newNavigationState {
                    // Don't track selectCountry as previous state
                } else {
                    previousNavigationState = newNavigationState
                }
            }
        }
        .onChange(of: showingCountrySelection) { isShowing in
            if !isShowing {
                // When modal is dismissed, reset the navigation state in the navigator
                if let previousState = previousNavigationState {
                    switch previousState {
                    case let .paymentMethod(paymentMethodType):
                        // Update the navigator to reflect we're back at the payment method
                        scope.checkoutNavigator.navigateToPaymentMethod(paymentMethodType, context: scope.presentationContext)
                    case .paymentMethodSelection:
                        scope.checkoutNavigator.navigateToPaymentSelection()
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func findPreviousNonCountryState() -> DefaultCheckoutScope.NavigationState? {
        // Check if we have a stored previous state that's not selectCountry
        if let prev = previousNavigationState {
            if case .selectCountry = prev {
                // Previous state is selectCountry, skip it
            } else {
                return prev
            }
        }

        // Fallback: try to infer from available payment methods
        if !scope.availablePaymentMethods.isEmpty {
            if scope.availablePaymentMethods.count == 1,
               let singleMethod = scope.availablePaymentMethods.first {
                return .paymentMethod(singleMethod.type)
            } else {
                return .paymentMethodSelection
            }
        }

        return .loading
    }

    // MARK: - View Builder

    @ViewBuilder
    private func getCurrentView() -> some View {
        switch scope.navigationState {
        case let .serverDrivenUI(schema):
            fatalError()
        case .loading:
            // Check if init screen is enabled in settings (UI Options integration)
            if scope.isInitScreenEnabled {
                if let customLoading = scope.loadingScreen {
                    AnyView(customLoading())
                } else {
                    AnyView(LoadingScreen())
                }
            } else {
                // Skip loading screen, show empty view or proceed to next state
//                logger.debug(message: "⏭️ [CheckoutComponents] Init screen disabled - skipping loading view")
                AnyView(EmptyView())
            }

        case .paymentMethodSelection:
            // First check if the payment method selection scope itself has a custom screen
            if let customScreen = scope.paymentMethodSelection.screen {
                AnyView(customScreen())
            }
            // Then check if the checkout scope has a custom payment selection screen
            else if let customPaymentSelection = scope.paymentMethodSelectionScreen {
                AnyView(customPaymentSelection(scope.paymentMethodSelection))
            } else {
                AnyView(PaymentMethodSelectionScreen(
                    scope: scope.paymentMethodSelection
                ))
            }

        case let .paymentMethod(paymentMethodType):
            // Handle all payment method types using truly unified dynamic approach
            AnyView(PaymentMethodScreen(
                paymentMethodType: paymentMethodType,
                checkoutScope: scope
            ))

        case .selectCountry:
            // Country selection is now handled via modal sheet, return the previous view
            if let previousState = previousNavigationState {
                switch previousState {
                case let .paymentMethod(paymentMethodType):
                    AnyView(PaymentMethodScreen(
                        paymentMethodType: paymentMethodType,
                        checkoutScope: scope
                    ))
                case .paymentMethodSelection:
                    AnyView(PaymentMethodSelectionScreen(
                        scope: scope.paymentMethodSelection
                    ))
                case .loading:
                    AnyView(LoadingScreen())
                default:
                    AnyView(LoadingScreen())
                }
            } else {
                // Fallback to loading if we can't determine the previous state
                AnyView(LoadingScreen())
            }

        case let .success(result):
            // Check if success screen is enabled in settings (UI Options integration)
            if scope.isSuccessScreenEnabled {
                if let customSuccess = scope.successScreen {
                    AnyView(customSuccess(result))
                } else {
                    AnyView(SuccessScreen(result: result) {
                        // Handle auto-dismiss with completion callback
                        logger.info(message: "Success screen auto-dismiss, calling completion callback")
                        onCompletion?()
                    })
                }
            } else {
                // Skip success screen, immediately call completion (UI Options integration)
//                logger.debug(message: "⏭️ [CheckoutComponents] Success screen disabled - auto-dismissing")
                AnyView(EmptyView().onAppear {
                    DispatchQueue.main.async {
                        onCompletion?()
                    }
                })
            }

        case let .failure(error):
            // Check if error screen is enabled in settings (UI Options integration)
            if scope.isErrorScreenEnabled {
                if let customError = scope.errorScreen {
                    AnyView(customError(error.localizedDescription))
                } else {
                    AnyView(ErrorScreen(error: error) {
                        // Handle auto-dismiss with completion callback
                        logger.info(message: "Error screen auto-dismiss, calling completion callback")
                        onCompletion?()
                    })
                }
            } else {
                // Skip error screen, immediately call completion (UI Options integration)
//                logger.debug(message: "⏭️ [CheckoutComponents] Error screen disabled - auto-dismissing")
                AnyView(EmptyView().onAppear {
                    DispatchQueue.main.async {
                        onCompletion?()
                    }
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
    }

    // MARK: - Design Token Management

    private func setupDesignTokens() async {
        logger.info(message: "Setting up design tokens...")
        do {
            guard let container = await DIContainer.current else {
                logger.warn(message: "DI Container not available for design tokens")
                return
            }

            designTokensManager = try await container.resolve(DesignTokensManager.self)
            logger.info(message: "DesignTokensManager resolved successfully")
            await loadDesignTokens(for: colorScheme)
        } catch {
            logger.error(message: "Failed to setup design tokens: \(error)")
        }
    }

    private func loadDesignTokens(for colorScheme: ColorScheme) async {
        guard let manager = designTokensManager else {
            logger.warn(message: "DesignTokensManager not available")
            return
        }

        logger.info(message: "Loading design tokens for color scheme: \(colorScheme == .dark ? "dark" : "light")")
        do {
            try await manager.fetchTokens(for: colorScheme)
            await MainActor.run {
                designTokens = manager.tokens
                logger.info(message: "Design tokens loaded successfully")

                // Log the specific focus border color for debugging
                if let focusColor = designTokens?.primerColorBorderOutlinedFocus {
                    logger.info(message: "Focus border color: \(focusColor)")
                } else {
                    logger.warn(message: "Focus border color not found in design tokens!")
                }

                // Log the brand color for comparison
                if let brandColor = designTokens?.primerColorBrand {
                    logger.info(message: "Brand color: \(brandColor)")
                } else {
                    logger.warn(message: "Brand color not found in design tokens!")
                }
            }
        } catch {
            logger.error(message: "Failed to load design tokens: \(error)")
        }
    }
}
