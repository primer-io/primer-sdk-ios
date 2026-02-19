//
//  PayPalView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default PayPal payment screen for CheckoutComponents.
/// Shows PayPal branding and a button to initiate the PayPal redirect flow.
@available(iOS 15.0, *)
struct PayPalView: View, LogReporter {
  let scope: any PrimerPayPalScope

  @Environment(\.designTokens) private var tokens
  @State private var payPalState: PrimerPayPalState = .init()

  var body: some View {
    VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
      headerSection
      contentSection
      Spacer()
      submitButtonSection
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    .frame(maxWidth: UIScreen.main.bounds.width)
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .onAppear {
      observeState()
    }
  }

  // MARK: - Header Section

  @MainActor
  private var headerSection: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      HStack {
        if scope.presentationContext.shouldShowBackButton {
          Button(
            action: {
              scope.onBack()
            },
            label: {
              HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                Image(systemName: RTLIcon.backChevron)
                  .font(PrimerFont.bodyMedium(tokens: tokens))
                Text(CheckoutComponentsStrings.backButton)
              }
              .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            }
          )
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.backButton,
              label: CheckoutComponentsStrings.a11yBack,
              traits: [.isButton]
            ))
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          Button(
            CheckoutComponentsStrings.cancelButton,
            action: {
              scope.onCancel()
            }
          )
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.closeButton,
              label: CheckoutComponentsStrings.a11yCancel,
              traits: [.isButton]
            ))
        }
      }

      titleSection
    }
  }

  @MainActor
  private var titleSection: some View {
    Text(CheckoutComponentsStrings.payPalTitle)
      .font(PrimerFont.titleXLarge(tokens: tokens))
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }

  // MARK: - Content Section

  @MainActor
  private var contentSection: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      // PayPal logo
      payPalLogo

      // Redirect description
      Text(CheckoutComponentsStrings.payPalRedirectDescription)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
    .padding(.vertical, PrimerSpacing.xlarge(tokens: tokens))
  }

  @MainActor
  private var payPalLogo: some View {
    Group {
      if let logoImage = UIImage(named: "paypal", in: Bundle.primerResources, compatibleWith: nil) {
        Image(uiImage: logoImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 60)
      } else {
        // Fallback text if image not found
        Text("PayPal")
          .font(PrimerFont.titleXLarge(tokens: tokens))
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      }
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.PayPal.logo,
        label: CheckoutComponentsStrings.a11yPayPalLogo
      ))
  }

  // MARK: - Submit Button Section

  @MainActor
  @ViewBuilder
  private var submitButtonSection: some View {
    // Check for custom button
    if let customButton = scope.payButton {
      AnyView(customButton(scope))
    } else {
      Button(action: submitAction) {
        submitButtonContent
      }
      .disabled(isButtonDisabled)
    }
  }

  private var submitButtonContent: some View {
    let isLoading = payPalState.status == .loading || payPalState.status == .redirecting

    return HStack {
      if isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.white(tokens: tokens)))
          .scaleEffect(PrimerScale.small)
      } else {
        Text(submitButtonText)
      }
    }
    .font(PrimerFont.body(tokens: tokens))
    .foregroundColor(CheckoutColors.white(tokens: tokens))
    .frame(maxWidth: .infinity)
    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    .background(submitButtonBackground)
    .cornerRadius(PrimerRadius.small(tokens: tokens))
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.PayPal.submitButton,
        label: submitButtonAccessibilityLabel,
        hint: isButtonDisabled
          ? CheckoutComponentsStrings.a11ySubmitButtonDisabled
          : CheckoutComponentsStrings.a11ySubmitButtonHint,
        traits: [.isButton]
      ))
  }

  private var submitButtonText: String {
    scope.submitButtonText ?? CheckoutComponentsStrings.payPalContinueButton
  }

  private var submitButtonAccessibilityLabel: String {
    let isLoading = payPalState.status == .loading || payPalState.status == .redirecting
    if isLoading {
      return CheckoutComponentsStrings.a11ySubmitButtonLoading
    }
    return submitButtonText
  }

  private var submitButtonBackground: Color {
    isButtonDisabled
      ? CheckoutColors.gray300(tokens: tokens)
      : CheckoutColors.textPrimary(tokens: tokens)
  }

  private var isButtonDisabled: Bool {
    payPalState.status == .loading || payPalState.status == .redirecting
  }

  private func submitAction() {
    scope.submit()
  }

  // MARK: - State Observation

  private func observeState() {
    Task {
      for await state in scope.state {
        await MainActor.run {
          payPalState = state
        }
      }
    }
  }
}

// MARK: - Preview

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("PayPal - Light") {
    PayPalView(scope: MockPayPalScope())
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("PayPal - Dark") {
    PayPalView(scope: MockPayPalScope())
      .environment(\.designTokens, MockDesignTokens.dark)
      .preferredColorScheme(.dark)
  }

  @available(iOS 15.0, *)
  #Preview("PayPal - Loading") {
    PayPalView(scope: MockPayPalScope(status: .loading))
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  @MainActor
  private final class MockPayPalScope: PrimerPayPalScope, ObservableObject {
    var presentationContext: PresentationContext = .fromPaymentSelection
    var dismissalMechanism: [DismissalMechanism] = [.closeButton]
    var screen: PayPalScreenComponent?
    var payButton: PayPalButtonComponent?
    var submitButtonText: String?

    @Published private var mockState: PrimerPayPalState

    var state: AsyncStream<PrimerPayPalState> {
      AsyncStream { continuation in
        continuation.yield(mockState)
      }
    }

    init(status: PrimerPayPalState.Status = .idle) {
      self.mockState = PrimerPayPalState(status: status)
    }

    func start() {}
    func submit() {
      mockState.status = .loading
    }

    func cancel() {}
    func onBack() {}
    func onCancel() {}
  }
#endif
