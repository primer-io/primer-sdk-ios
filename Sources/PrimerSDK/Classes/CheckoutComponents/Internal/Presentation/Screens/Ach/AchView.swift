//
//  AchView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - State Observer

@available(iOS 15.0, *)
@MainActor
final class AchStateObserver: ObservableObject {
  @Published var achState: AchState = .init()
  @Published var showBankCollector: Bool = false

  private var stripeFlowCompleted: Bool = false
  private let scope: any PrimerAchScope
  private var observationTask: Task<Void, Never>?

  init(scope: any PrimerAchScope) {
    self.scope = scope
  }

  func startObserving() {
    guard observationTask == nil else { return }

    observationTask = Task { @MainActor [weak self] in
      guard let self = self else { return }

      for await state in self.scope.state {
        if Task.isCancelled { break }

        self.achState = state

        if state.step == .bankAccountCollection, self.scope.bankCollectorViewController != nil, !self.stripeFlowCompleted {
          self.showBankCollector = true
        } else if state.step == .mandateAcceptance {
          if !self.stripeFlowCompleted {
            self.stripeFlowCompleted = true
          }
        } else if state.step != .bankAccountCollection, state.step != .processing {
          self.showBankCollector = false
        }
      }
    }
  }

  func stopObserving() {
    observationTask?.cancel()
    observationTask = nil
  }

  deinit {
    observationTask?.cancel()
  }
}

// MARK: - AchView

@available(iOS 15.0, *)
struct AchView: View, LogReporter {
  let scope: any PrimerAchScope

  @StateObject private var observer: AchStateObserver

  @Environment(\.designTokens) private var tokens

  init(scope: any PrimerAchScope) {
    self.scope = scope
    // Create the observer with the scope
    self._observer = StateObject(wrappedValue: AchStateObserver(scope: scope))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
        makeHeaderSection()
        makeContentSection()
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, PrimerSpacing.large(tokens: tokens))
      .frame(maxWidth: UIScreen.main.bounds.width)
    }
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.container)
    .onAppear {
      observer.startObserving()
    }
    .fullScreenCover(isPresented: $observer.showBankCollector) {
      if let bankCollectorVC = scope.bankCollectorViewController {
        StripeBankCollectorRepresentable(viewController: bankCollectorVC)
          .ignoresSafeArea()
          .accessibilityIdentifier(AccessibilityIdentifiers.Ach.bankCollectorContainer)
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

      Text(CheckoutComponentsStrings.achPayWithTitle)
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
    switch observer.achState.step {
    case .loading:
      makeLoadingContent()
    case .userDetailsCollection:
      if let customScreen = scope.userDetailsScreen {
        AnyView(customScreen(scope))
      } else {
        AchUserDetailsView(scope: scope, achState: observer.achState)
      }
    case .bankAccountCollection:
      // Bank collector is shown as fullScreenCover, show loading while it's presented
      makeLoadingContent()
    case .mandateAcceptance:
      if let customScreen = scope.mandateScreen {
        AnyView(customScreen(scope))
      } else {
        AchMandateView(scope: scope, achState: observer.achState)
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

  // MARK: - Layout Constants

  private enum Layout {
    static let spinnerSize: CGFloat = 56
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
