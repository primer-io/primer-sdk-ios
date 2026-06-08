//
//  PrimerCheckout.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Pure SwiftUI implementation for CheckoutComponents SDK — the prebuilt, fully managed modal flow.
///
/// Example usage (minimal):
/// ```swift
/// PrimerCheckout(clientToken: "your_client_token")
/// ```
///
/// This modal renders the SDK's default screens; it does not expose the composable views or their
/// `@ViewBuilder` slots. To customize the UI, embed the composable views (e.g. ``PrimerCardForm``)
/// inline in your own layout and wire them up with `.primerCheckoutSession(_:)`, which injects the
/// session those views resolve from the environment:
/// ```swift
/// @StateObject private var session = PrimerCheckoutSession(clientToken: "your_client_token")
///
/// ScrollView {
///     PrimerCardForm(submitButton: { session in
///         MyPayButton(isLoading: session.state.isLoading) { session.scope.submit() }
///     })
/// }
/// .primerCheckoutSession(session) { state in handle(state) }
/// ```
@available(iOS 15.0, *)
@MainActor
public struct PrimerCheckout: View {

  private let clientToken: String
  private let settings: PrimerSettings
  private let theme: PrimerCheckoutTheme
  private let onCompletion: ((PrimerCheckoutState) -> Void)?
  @StateObject private var navigator: CheckoutNavigator
  private let presentationContext: PresentationContext
  private let integrationType: CheckoutComponentsIntegrationType

  /// Creates a PrimerCheckout view.
  /// - Parameters:
  ///   - clientToken: The client token obtained from your backend.
  ///   - primerSettings: Configuration settings including payment options and UI preferences. Default: `PrimerSettings()`
  ///   - primerTheme: Theme configuration for design tokens. Default: `PrimerCheckoutTheme()`
  ///   - onCompletion: Optional completion callback called when checkout completes with the final state (success, failure, or dismissed).
  public init(
    clientToken: String,
    primerSettings: PrimerSettings = PrimerSettings(),
    primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  ) {
    self.clientToken = clientToken
    settings = primerSettings
    theme = primerTheme
    self.onCompletion = onCompletion
    _navigator = StateObject(wrappedValue: CheckoutNavigator())
    presentationContext = .fromPaymentSelection
    integrationType = .swiftUI
  }

  init(
    clientToken: String,
    primerSettings: PrimerSettings,
    primerTheme: PrimerCheckoutTheme,
    navigator: CheckoutNavigator,
    presentationContext: PresentationContext,
    integrationType: CheckoutComponentsIntegrationType,
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  ) {
    self.clientToken = clientToken
    settings = primerSettings
    theme = primerTheme
    self.onCompletion = onCompletion
    _navigator = StateObject(wrappedValue: navigator)
    self.presentationContext = presentationContext
    self.integrationType = integrationType
  }

  public var body: some View {
    InternalCheckout(
      clientToken: clientToken,
      settings: settings,
      theme: theme,
      navigator: navigator,
      presentationContext: presentationContext,
      integrationType: integrationType,
      onCompletion: onCompletion
    )
  }
}

// MARK: - Internal Implementation

@available(iOS 15.0, *)
@MainActor
struct InternalCheckout: View, LogReporter {
  private let clientToken: String
  private let settings: PrimerSettings
  private let theme: PrimerCheckoutTheme
  private let navigator: CheckoutNavigator
  private let presentationContext: PresentationContext
  private let integrationType: CheckoutComponentsIntegrationType
  private let onCompletion: ((PrimerCheckoutState) -> Void)?

  @State private var checkoutScope: DefaultCheckoutScope?
  @State private var initializationState: InitializationState = .idle
  @Environment(\.colorScheme) private var colorScheme

  // Design tokens state for early theme application (splash screen)
  @StateObject private var designTokensManager = DesignTokensManager()

  private let sdkInitializer: CheckoutSDKInitializer

  enum InitializationState {
    case idle
    case initializing
    case retrying
    case initialized
    case failed(PrimerError)
  }

  init(
    clientToken: String,
    settings: PrimerSettings,
    theme: PrimerCheckoutTheme,
    navigator: CheckoutNavigator,
    presentationContext: PresentationContext,
    integrationType: CheckoutComponentsIntegrationType,
    onCompletion: ((PrimerCheckoutState) -> Void)?
  ) {
    self.clientToken = clientToken
    self.settings = settings
    self.theme = theme
    self.navigator = navigator
    self.presentationContext = presentationContext
    self.integrationType = integrationType
    self.onCompletion = onCompletion

    sdkInitializer = CheckoutSDKInitializer(
      clientToken: clientToken,
      primerSettings: settings,
      primerTheme: theme,
      navigator: navigator,
      presentationContext: presentationContext
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      switch initializationState {
      case .idle, .initializing:
        splashContent
      case .retrying:
        loadingContent
      case .initialized:
        if let checkoutScope {
          CheckoutScopeObserver(
            scope: checkoutScope,
            theme: theme,
            onCompletion: onCompletion
          )
        } else {
          splashContent
        }
      case let .failed(error):
        errorContent(error: error)
      }
    }
    .background(backgroundColor)
    .environment(\.designTokens, designTokensManager.tokens)
    .applyAppearanceMode(settings.uiOptions.appearanceMode)
    .environment(\.layoutDirection, RTLSupport.layoutDirection)
    .task {
      await LoggingSessionContext.shared.recordInitStartTime()
      await LoggingSessionContext.shared.initialize(
        clientToken: clientToken, integrationType: integrationType)
      await setupDesignTokens()
      await initializeSDK()
    }
    .onColorSchemeChange(of: colorScheme) { newColorScheme in
      Task {
        await loadDesignTokens(for: newColorScheme)
      }
    }
    .onDisappear {
      sdkInitializer.cleanup()
    }
  }

  // MARK: - Design Token Management

  /// Background color that uses theme override first, then loaded tokens, then system default.
  /// This ensures the background color is correct from the first render.
  private var backgroundColor: Color {
    // Priority 1: Theme override (available immediately)
    if let themeBackground = theme.colors?.primerColorBackground {
      return themeBackground
    }
    // Priority 2: Loaded design tokens (available after async load)
    if let tokens = designTokensManager.tokens {
      return CheckoutColors.background(tokens: tokens)
    }
    // Priority 3: System default based on color scheme
    return colorScheme == .dark ? Color(white: 0.11) : .white
  }

  private func setupDesignTokens() async {
    designTokensManager.applyTheme(theme)
    await loadDesignTokens(for: colorScheme)
  }

  private func loadDesignTokens(for colorScheme: ColorScheme) async {
    do {
      try await designTokensManager.fetchTokens(for: colorScheme)
    } catch {
      logger.error(message: "[InternalCheckout] Failed to load design tokens: \(error)")
    }
  }

  // MARK: - Content Builders

  private var splashContent: some View {
    SplashScreen()
  }

  private var loadingContent: some View {
    DefaultLoadingScreen()
  }

  private func errorContent(error: PrimerError) -> some View {
    SDKInitializationErrorView(error: error) {
      Task {
        await initializeSDK(isRetry: true)
      }
    }
  }

  // MARK: - Private Methods

  private func initializeSDK(isRetry: Bool = false) async {
    switch initializationState {
    case .idle, .failed: break
    default: return
    }

    initializationState = isRetry ? .retrying : .initializing

    do {
      let result = try await sdkInitializer.initialize()
      checkoutScope = result.checkoutScope

      initializationState = .initialized
    } catch {
      let primerError = error as? PrimerError ?? PrimerError.underlyingErrors(errors: [error])
      initializationState = .failed(primerError)
    }
  }
}

// MARK: - Appearance Mode Support

@available(iOS 15.0, *)
extension View {
  @ViewBuilder
  fileprivate func applyAppearanceMode(_ mode: PrimerAppearanceMode) -> some View {
    switch mode {
    case .system:
      self
    case .light:
      preferredColorScheme(.light)
    case .dark:
      preferredColorScheme(.dark)
    }
  }

  /// Reacts to color-scheme changes, using the two-parameter `onChange` on iOS 17+ to avoid the
  /// single-parameter form deprecated there, and falling back to the original form on earlier OS.
  @ViewBuilder
  fileprivate func onColorSchemeChange(
    of colorScheme: ColorScheme,
    _ action: @escaping (ColorScheme) -> Void
  ) -> some View {
    if #available(iOS 17.0, *) {
      onChange(of: colorScheme) { _, newColorScheme in action(newColorScheme) }
    } else {
      onChange(of: colorScheme) { newColorScheme in action(newColorScheme) }
    }
  }
}
