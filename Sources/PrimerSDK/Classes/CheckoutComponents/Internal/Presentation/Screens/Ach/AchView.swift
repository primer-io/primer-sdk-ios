//
//  AchView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AchView: View, LogReporter {
  let scope: any PrimerAchScope

  @Environment(\.designTokens) private var tokens
  @State private var achState: AchState = .init()

  var body: some View {
    VStack(spacing: 0) {
      makeHeaderSection()
        .padding(.bottom, PrimerSpacing.xlarge(tokens: tokens))

      ScrollView {
        makeContentSection()
      }
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.container)
    .task {
      for await state in scope.state {
        achState = state
      }
    }
  }

  // MARK: - Header Section

  @MainActor
  private func makeHeaderSection() -> some View {
    HStack {
      if scope.presentationContext.shouldShowBackButton {
        Button(
          action: scope.onBack,
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

      Text(CheckoutComponentsStrings.achTitle)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Spacer()

      if scope.dismissalMechanism.contains(.closeButton) {
        Button(
          CheckoutComponentsStrings.cancelButton,
          action: scope.onCancel
        )
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.closeButton,
            label: CheckoutComponentsStrings.a11yCancel,
            traits: [.isButton]
          ))
      } else {
        Text(CheckoutComponentsStrings.cancelButton)
          .hidden()
      }
    }
  }

  // MARK: - Content Section

  @MainActor
  @ViewBuilder
  private func makeContentSection() -> some View {
    switch achState.step {
    case .loading:
      makeLoadingContent()
    case .userDetailsCollection:
      if let customScreen = scope.userDetailsScreen {
        AnyView(customScreen(scope))
      } else {
        AchUserDetailsView(scope: scope, achState: achState)
      }
    case .bankAccountCollection:
      makeBankCollectorContent()
    case .mandateAcceptance:
      if let customScreen = scope.mandateScreen {
        AnyView(customScreen(scope))
      } else {
        AchMandateView(scope: scope, achState: achState)
      }
    case .processing:
      makeLoadingContent()
    }
  }

  // MARK: - Loading Content

  @MainActor
  private func makeLoadingContent() -> some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      Spacer()
        .frame(height: PrimerSpacing.xxlarge(tokens: tokens) * 2)

      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.blue(tokens: tokens)))
        .scaleEffect(PrimerScale.large)
        .frame(width: Layout.spinnerSize, height: Layout.spinnerSize)
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.loadingIndicator)

      Spacer()
        .frame(height: PrimerSpacing.small(tokens: tokens))

      Text(CheckoutComponentsStrings.loading)
        .font(PrimerFont.bodyLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Spacer()
        .frame(height: PrimerSpacing.xxlarge(tokens: tokens) * 2)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, PrimerSpacing.xlarge(tokens: tokens))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(CheckoutComponentsStrings.a11yLoading)
  }

  // MARK: - Bank Collector Content

  @MainActor
  @ViewBuilder
  private func makeBankCollectorContent() -> some View {
    if let bankCollectorVC = scope.bankCollectorViewController {
      StripeBankCollectorRepresentable(viewController: bankCollectorVC)
        .frame(minHeight: Layout.bankCollectorMinHeight)
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.bankCollectorContainer)
    } else {
      makeLoadingContent()
    }
  }

  // MARK: - Layout Constants

  private enum Layout {
    static let spinnerSize: CGFloat = 56
    static let bankCollectorMinHeight: CGFloat = 400
  }
}

// MARK: - Preview

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("ACH - Loading") {
    AchView(scope: MockAchScope(step: .loading))
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("ACH - User Details") {
    AchView(scope: MockAchScope(step: .userDetailsCollection))
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  @MainActor
  private final class MockAchScope: PrimerAchScope, ObservableObject {
    var presentationContext: PresentationContext = .fromPaymentSelection
    var dismissalMechanism: [DismissalMechanism] = [.closeButton]
    var bankCollectorViewController: UIViewController?
    var screen: AchScreenComponent?
    var userDetailsScreen: AchScreenComponent?
    var mandateScreen: AchScreenComponent?
    var submitButton: AchButtonComponent?

    @Published private var mockState: AchState

    var state: AsyncStream<AchState> {
      AsyncStream { continuation in
        continuation.yield(mockState)
      }
    }

    init(step: AchState.Step = .userDetailsCollection) {
      let userDetails = AchState.UserDetails(
        firstName: "John",
        lastName: "Doe",
        emailAddress: "john.doe@example.com"
      )
      self.mockState = AchState(
        step: step,
        userDetails: userDetails,
        isSubmitEnabled: true
      )
    }

    func start() {}
    func submit() {}
    func cancel() {}
    func updateFirstName(_ value: String) {}
    func updateLastName(_ value: String) {}
    func updateEmailAddress(_ value: String) {}
    func submitUserDetails() {}
    func acceptMandate() {}
    func declineMandate() {}
    func onBack() {}
    func onCancel() {}
  }
#endif
