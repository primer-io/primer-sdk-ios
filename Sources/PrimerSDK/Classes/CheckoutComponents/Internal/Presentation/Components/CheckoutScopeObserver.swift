//
//  CheckoutScopeObserver.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Checkout Scope Observer

/// Wrapper view that properly observes the DefaultCheckoutScope as an ObservableObject
@available(iOS 15.0, *)
struct CheckoutScopeObserver: View, LogReporter {
    @ObservedObject private var scope: DefaultCheckoutScope
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let scopeCustomization: ((PrimerCheckoutScope) -> Void)?
    private let onCompletion: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.bridgeController) private var bridgeController

    // Design tokens state
    @StateObject private var designTokensManager = DesignTokensManager()

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
        Group {
            if bridgeController != nil {
                contentView
            } else {
                NavigationView { contentView }
                    .navigationViewStyle(.stack)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .background(CheckoutColors.background(tokens: designTokensManager.tokens))
    }

    private var contentView: some View {
        VStack(spacing: 0) {
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
                if let customContent {
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
                        if let previousNavigationState {
                            scope.updateNavigationState(previousNavigationState, syncToNavigator: false)
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environmentObject(scope)
        .environment(\.diContainer, DIContainer.currentSync)
        .environment(\.designTokens, designTokensManager.tokens)
        .onAppear {
            // Apply any scope customizations (only after SDK is initialized)
            scopeCustomization?(scope)

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
                if let previousNavigationState {
                    switch previousNavigationState {
                    case let .paymentMethod(paymentMethodType):
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

    private func getCurrentView() -> AnyView {
        switch scope.navigationState {
        case .loading:
            // Check if init screen is enabled in settings (UI Options integration)
            if scope.isInitScreenEnabled {
                if let customLoading = scope.loadingScreen {
                    return AnyView(customLoading())
                } else {
                    return AnyView(SplashScreen())
                }
            } else {
                // Skip loading screen, show empty view or proceed to next state
                logger.debug(message: "⏭️ [CheckoutComponents] Init screen disabled - skipping loading view")
                return AnyView(EmptyView())
            }

        case .paymentMethodSelection:
            // First check if the payment method selection scope itself has a custom screen
            if let customPaymentMethodSelectionScreen = scope.paymentMethodSelection.screen {
                return AnyView(customPaymentMethodSelectionScreen())
            }
            // Then check if the checkout scope has a custom payment selection screen
            else if let customPaymentSelection = scope.paymentMethodSelectionScreen {
                return AnyView(customPaymentSelection(scope.paymentMethodSelection))
            } else {
                return AnyView(PaymentMethodSelectionScreen(
                    scope: scope.paymentMethodSelection
                ))
            }

        case let .paymentMethod(paymentMethodType):
            // Handle all payment method types using truly unified dynamic approach
            return AnyView(PaymentMethodScreen(
                paymentMethodType: paymentMethodType,
                checkoutScope: scope
            ))

        case .selectCountry:
            // Country selection is now handled via modal sheet, return the previous view
            if let previousNavigationState {
                switch previousNavigationState {
                case let .paymentMethod(paymentMethodType):
                    return AnyView(PaymentMethodScreen(
                        paymentMethodType: paymentMethodType,
                        checkoutScope: scope
                    ))
                case .paymentMethodSelection:
                    return AnyView(PaymentMethodSelectionScreen(
                        scope: scope.paymentMethodSelection
                    ))
                case .loading:
                    return AnyView(SplashScreen())
                default:
                    return AnyView(SplashScreen())
                }
            } else {
                // Fallback to loading if we can't determine the previous state
                return AnyView(SplashScreen())
            }

        case let .success(result):
            // Check if success screen is enabled in settings (UI Options integration)
            if scope.isSuccessScreenEnabled {
                if let customSuccess = scope.successScreen {
                    return AnyView(customSuccess(result))
                } else {
                    return AnyView(SuccessScreen(result: result) {
                        logger.info(message: "Success screen auto-dismiss, calling completion callback")
                        onCompletion?()
                    })
                }
            } else {
                // Skip success screen, immediately call completion (UI Options integration)
                logger.debug(message: "⏭️ [CheckoutComponents] Success screen disabled - auto-dismissing")
                return AnyView(EmptyView().onAppear {
                    DispatchQueue.main.async {
                        onCompletion?()
                    }
                })
            }

        case let .failure(error):
            // Check if error screen is enabled in settings (UI Options integration)
            if scope.isErrorScreenEnabled {
                if let customError = scope.errorScreen {
                    return AnyView(customError(error.localizedDescription))
                } else {
                    return AnyView(ErrorScreen(error: error) {
                        logger.info(message: "Error screen auto-dismiss, calling completion callback")
                        onCompletion?()
                    })
                }
            } else {
                // Skip error screen, immediately call completion (UI Options integration)
                logger.debug(message: "⏭️ [CheckoutComponents] Error screen disabled - auto-dismissing")
                return AnyView(EmptyView().onAppear {
                    DispatchQueue.main.async {
                        onCompletion?()
                    }
                })
            }

        case .dismissed:
            // Handle dismissal - call completion callback to properly dismiss SwiftUI sheets
            return AnyView(VStack {
                Text(CheckoutComponentsStrings.dismissingMessage)
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
        await loadDesignTokens(for: colorScheme)
    }

    private func loadDesignTokens(for colorScheme: ColorScheme) async {
        logger.info(message: "Loading design tokens for color scheme: \(colorScheme == .dark ? "dark" : "light")")
        do {
            try await designTokensManager.fetchTokens(for: colorScheme)
            logger.info(message: "Design tokens loaded successfully")
        } catch {
            logger.error(message: "Failed to load design tokens: \(error)")
        }
    }
}
