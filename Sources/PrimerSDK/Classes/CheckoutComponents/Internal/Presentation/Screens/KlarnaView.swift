//
//  KlarnaView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct KlarnaView: View, LogReporter {
  let scope: any PrimerKlarnaScope

  @Environment(\.designTokens) private var tokens
  @State private var klarnaState: KlarnaState = .init()

  // MARK: - Layout Constants

  private enum Layout {
    static let logoWidth: CGFloat = 56
    static let logoHeight: CGFloat = 24
    static let spinnerSize: CGFloat = 56
    static let badgeWidth: CGFloat = 56
    static let badgeHeight: CGFloat = 40
    static let paymentViewMinHeight: CGFloat = 200
    static let inlineLoadingMinHeight: CGFloat = 100
    static let selectedBorderWidth: CGFloat = 2
    static let defaultBorderWidth: CGFloat = 1
    static let badgeCornerRadius: CGFloat = 2
    static let placeholderOpacity: Double = 0.8
  }

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
    .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.container)
    .task {
      for await state in scope.state {
        klarnaState = state
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

      // Klarna logo
      makeKlarnaLogo()

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
        // Invisible spacer to keep logo centered
        Text(CheckoutComponentsStrings.cancelButton)
          .hidden()
      }
    }
  }

  @MainActor
  private func makeKlarnaLogo() -> some View {
    Group {
      if let logoImage = UIImage(named: "klarna", in: .primerResources, compatibleWith: nil) {
        Image(uiImage: logoImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: Layout.logoWidth, height: Layout.logoHeight)
      } else {
        Text(CheckoutComponentsStrings.klarnaBrandName)
          .font(PrimerFont.titleLarge(tokens: tokens))
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      }
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Klarna.logo,
        label: CheckoutComponentsStrings.klarnaBrandName
      ))
  }

  // MARK: - Content Section

  @MainActor
  @ViewBuilder
  private func makeContentSection() -> some View {
    switch klarnaState.step {
    case .loading:
      makeLoadingContent()
    case .categorySelection, .viewReady:
      makeCategorySelectionContent()
    case .authorizationStarted:
      makeLoadingContent()
    case .awaitingFinalization:
      makeFinalizationContent()
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
        .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.loadingIndicator)

      Spacer()
        .frame(height: PrimerSpacing.small(tokens: tokens))

      Text(CheckoutComponentsStrings.klarnaLoadingTitle)
        .font(PrimerFont.bodyLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Text(CheckoutComponentsStrings.klarnaLoadingSubtitle)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

      Spacer()
        .frame(height: PrimerSpacing.xxlarge(tokens: tokens) * 2)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, PrimerSpacing.xlarge(tokens: tokens))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(CheckoutComponentsStrings.a11yLoading)
  }

  // MARK: - Category Selection Content

  @MainActor
  private func makeCategorySelectionContent() -> some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      // Category cards
      VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        ForEach(klarnaState.categories, id: \.id) { category in
          makeCategoryCard(for: category)
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.categoriesContainer)

      // Authorize button (visible when a category is selected and view is ready)
      if klarnaState.step == .viewReady {
        makeAuthorizeButtonSection()
          .padding(.top, PrimerSpacing.large(tokens: tokens))
      }
    }
  }

  @MainActor
  private func makeCategoryCard(for category: KlarnaPaymentCategory) -> some View {
    let isSelected = klarnaState.selectedCategoryId == category.id

    return VStack(
      alignment: .leading, spacing: isSelected ? PrimerSpacing.medium(tokens: tokens) : 0
    ) {
      // Category header
      Button(action: {
        scope.selectPaymentCategory(category.id)
      }) {
        HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
          // Category badge image
          makeCategoryBadge(for: category)

          // Category name
          Text(category.name)
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

          Spacer()

          // Checkmark for selected
          if isSelected {
            Image(systemName: "checkmark")
              .foregroundColor(CheckoutColors.blue(tokens: tokens))
              .font(PrimerFont.bodyMedium(tokens: tokens))
          }
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.categoryButton(category.id))
      .accessibilityLabel(
        isSelected
          ? CheckoutComponentsStrings.a11yKlarnaCategorySelected(category.name)
          : CheckoutComponentsStrings.a11yKlarnaCategory(category.name)
      )

      // Expanded Klarna SDK view or inline loading indicator
      if isSelected, let paymentView = scope.paymentView {
        KlarnaPaymentViewRepresentable(paymentView: paymentView)
          .id(category.id)
          .frame(minHeight: Layout.paymentViewMinHeight)
          .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.paymentViewContainer)
          .accessibilityLabel(CheckoutComponentsStrings.a11yKlarnaPaymentView)
      } else if isSelected, scope.paymentView == nil, klarnaState.step != .viewReady {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.blue(tokens: tokens)))
          .frame(maxWidth: .infinity, minHeight: Layout.inlineLoadingMinHeight)
          .accessibilityLabel(CheckoutComponentsStrings.a11yLoading)
      }
    }
    .padding(PrimerSpacing.medium(tokens: tokens))
    .background(CheckoutColors.background(tokens: tokens))
    .overlay(
      RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
        .stroke(
          isSelected
            ? CheckoutColors.blue(tokens: tokens) : CheckoutColors.borderDefault(tokens: tokens),
          lineWidth: isSelected ? Layout.selectedBorderWidth : Layout.defaultBorderWidth
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens)))
  }

  @MainActor
  private func makeCategoryBadge(for category: KlarnaPaymentCategory) -> some View {
    AsyncImage(url: URL(string: category.standardAssetUrl)) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
    } placeholder: {
      RoundedRectangle(cornerRadius: Layout.badgeCornerRadius)
        .fill(Color.pink.opacity(Layout.placeholderOpacity))
        .overlay(
          Text("K")
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(.white)
        )
    }
    .frame(width: Layout.badgeWidth, height: Layout.badgeHeight)
    .clipShape(RoundedRectangle(cornerRadius: Layout.badgeCornerRadius))
  }

  // MARK: - Shared Button Builder

  @MainActor
  private func makePrimaryButton(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.white(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .background(CheckoutColors.textPrimary(tokens: tokens))
        .cornerRadius(PrimerRadius.small(tokens: tokens))
    }
  }

  // MARK: - Authorize Button

  @MainActor
  @ViewBuilder
  private func makeAuthorizeButtonSection() -> some View {
    if let customButton = scope.authorizeButton {
      AnyView(customButton(scope))
    } else {
      makePrimaryButton(title: CheckoutComponentsStrings.klarnaAuthorizeButton, action: scope.authorizePayment)
        .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.authorizeButton)
        .accessibilityLabel(CheckoutComponentsStrings.klarnaAuthorizeButton)
        .accessibilityHint(CheckoutComponentsStrings.a11yKlarnaAuthorizeHint)
    }
  }

  // MARK: - Finalization Content

  @MainActor
  private func makeFinalizationContent() -> some View {
    VStack(spacing: PrimerSpacing.xlarge(tokens: tokens)) {
      Text(CheckoutComponentsStrings.klarnaSelectCategoryDescription)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)

      if let customButton = scope.finalizeButton {
        AnyView(customButton(scope))
      } else {
        makePrimaryButton(title: CheckoutComponentsStrings.klarnaFinalizeButton, action: scope.finalizePayment)
          .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.finalizeButton)
          .accessibilityLabel(CheckoutComponentsStrings.klarnaFinalizeButton)
          .accessibilityHint(CheckoutComponentsStrings.a11yKlarnaFinalizeHint)
      }
    }
    .padding(.top, PrimerSpacing.xlarge(tokens: tokens))
  }

}

// MARK: - Preview

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("Klarna - Category Selection") {
    KlarnaView(scope: MockKlarnaScope())
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("Klarna - Loading") {
    KlarnaView(scope: MockKlarnaScope(step: .loading))
      .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  @MainActor
  private final class MockKlarnaScope: PrimerKlarnaScope, ObservableObject {
    var presentationContext: PresentationContext = .fromPaymentSelection
    var dismissalMechanism: [DismissalMechanism] = [.closeButton]
    var paymentView: UIView?
    var screen: KlarnaScreenComponent?
    var authorizeButton: KlarnaButtonComponent?
    var finalizeButton: KlarnaButtonComponent?

    @Published private var mockState: KlarnaState

    var state: AsyncStream<KlarnaState> {
      AsyncStream { continuation in
        continuation.yield(mockState)
      }
    }

    init(step: KlarnaState.Step = .categorySelection) {
      let categories = [
        KlarnaPaymentCategory(
          response: Response.Body.Klarna.SessionCategory(
            identifier: "pay_now", name: "Pay now",
            descriptiveAssetUrl: "", standardAssetUrl: ""
          )),
        KlarnaPaymentCategory(
          response: Response.Body.Klarna.SessionCategory(
            identifier: "pay_later", name: "Pay in 30 days",
            descriptiveAssetUrl: "", standardAssetUrl: ""
          )),
      ]
      self.mockState = KlarnaState(step: step, categories: categories)
    }

    func start() {}
    func submit() {}
    func cancel() {}
    func selectPaymentCategory(_ categoryId: String) {
      mockState = KlarnaState(
        step: mockState.step,
        categories: mockState.categories,
        selectedCategoryId: categoryId
      )
    }
    func authorizePayment() {}
    func finalizePayment() {}
    func onBack() {}
    func onCancel() {}
  }
#endif
