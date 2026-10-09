//
//  KlarnaView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerResources
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct KlarnaView: View, LogReporter {
  let scope: any PrimerKlarnaScope

  @Environment(\.designTokens) private var tokens
  @Environment(\.bridgeController) private var bridgeController
  @State private var klarnaState: PrimerKlarnaState = .init()

  // MARK: - Layout Constants

  private enum Layout {
    static let logoWidth: CGFloat = 56
    static let logoHeight: CGFloat = 24
    static let spinnerSize: CGFloat = 56
    static let badgeSlotHeight: CGFloat = 40
  }

  private enum SheetContent: Equatable {
    case loading
    case categories(expandedHeight: CGFloat)
    case finalization
  }

  private var sheetContent: SheetContent {
    switch klarnaState.step {
    case .categorySelection, .viewReady: .categories(expandedHeight: klarnaState.paymentViewHeight)
    case .awaitingFinalization: .finalization
    default: .loading
    }
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
    // Without a container element the identifier propagates to every child and hides theirs.
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.container)
    .task {
      for await state in scope.state {
        klarnaState = state
      }
    }
    .onChange(of: sheetContent) { _ in
      bridgeController?.invalidateContentSize()
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
                .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
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
        CheckoutHeaderButton(config: .closeButton(action: scope.cancel))
      } else {
        // Invisible spacer to keep logo centered
        CheckoutHeaderButton(config: .closeButton(action: {}))
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
          .primerTypography(.titleLarge, tokens: tokens)
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
        .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.loader(tokens: tokens)))
        .scaleEffect(PrimerScale.large)
        .frame(width: Layout.spinnerSize, height: Layout.spinnerSize)
        .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.loadingIndicator)

      Spacer()
        .frame(height: PrimerSpacing.small(tokens: tokens))

      Text(CheckoutComponentsStrings.klarnaLoadingTitle)
        .primerTypography(.bodyLarge, tokens: tokens)
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Text(CheckoutComponentsStrings.klarnaLoadingSubtitle)
        .primerTypography(.bodyMedium, tokens: tokens)
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
      // Without a container element the identifier propagates to every child and hides theirs.
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.categoriesContainer)

      makeAuthorizeButtonSection()
        .padding(.top, PrimerSpacing.large(tokens: tokens))
    }
  }

  @MainActor
  private func makeCategoryCard(for category: KlarnaPaymentCategory) -> some View {
    let isSelected = klarnaState.selectedCategoryId == category.id
    // Shown at zero height first: Klarna measures it only once it is laid out.
    let showsPaymentView = isSelected && klarnaState.step == .viewReady
    let isExpanded = showsPaymentView && klarnaState.paymentViewHeight > 0

    return VStack(
      alignment: .leading, spacing: isExpanded ? PrimerSpacing.medium(tokens: tokens) : 0
    ) {
      Button(action: {
        scope.selectPaymentCategory(category.id)
      }) {
        HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
          makeCategoryBadge()

          Text(category.name)
            .primerTypography(.bodyLarge, tokens: tokens)
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

          Spacer()

          if isSelected {
            makeSelectionIndicator()
          }
        }
      }
      .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.categoryButton(category.id))
      .accessibilityLabel(
        isSelected
          ? CheckoutComponentsStrings.a11yKlarnaCategorySelected(category.name)
          : CheckoutComponentsStrings.a11yKlarnaCategory(category.name)
      )

      if showsPaymentView, let paymentView = scope.paymentView {
        KlarnaPaymentViewRepresentable(paymentView: paymentView)
          .id(category.id)
          .frame(height: klarnaState.paymentViewHeight)
          .accessibilityHidden(!isExpanded)
          .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.paymentViewContainer)
          .accessibilityLabel(CheckoutComponentsStrings.a11yKlarnaPaymentView)
      }
    }
    .padding(PrimerSpacing.medium(tokens: tokens))
    .background(CheckoutColors.background(tokens: tokens))
    .overlay(
      RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
        .stroke(
          isSelected
            ? CheckoutColors.borderSelected(tokens: tokens) : CheckoutColors.borderDefault(tokens: tokens),
          lineWidth: isSelected
            ? PrimerBorderWidth.selected(tokens: tokens) : PrimerBorderWidth.standard(tokens: tokens)
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens)))
  }

  @MainActor
  private func makeCategoryBadge() -> some View {
    Image(uiImage: UIImage.klarnaBadgeColored ?? UIImage())
      .frame(height: Layout.badgeSlotHeight)
  }

  @MainActor
  private func makeSelectionIndicator() -> some View {
    Group {
      if klarnaState.isSelectedOptionReady {
        Image(systemName: "checkmark")
          .foregroundColor(CheckoutColors.borderSelected(tokens: tokens))
          .font(PrimerFont.bodyMedium(tokens: tokens))
      } else {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.loader(tokens: tokens)))
          .accessibilityLabel(CheckoutComponentsStrings.a11yLoading)
      }
    }
    .frame(width: PrimerSize.medium(tokens: tokens), height: PrimerSize.medium(tokens: tokens))
  }

  // MARK: - Authorize Button

  @MainActor
  @ViewBuilder
  private func makeAuthorizeButtonSection() -> some View {
    if let customButton = scope.authorizeButton {
      AnyView(customButton(scope))
    } else {
      PrimerCheckoutButton(
        CheckoutComponentsStrings.klarnaAuthorizeButton,
        isEnabled: klarnaState.isSelectedOptionReady,
        action: scope.authorizePayment
      )
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
        .primerTypography(.bodyMedium, tokens: tokens)
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)

      if let customButton = scope.finalizeButton {
        AnyView(customButton(scope))
      } else {
        PrimerCheckoutButton(CheckoutComponentsStrings.klarnaFinalizeButton, action: scope.finalizePayment)
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

    @Published private var mockState: PrimerKlarnaState

    var state: AsyncStream<PrimerKlarnaState> {
      AsyncStream { continuation in
        continuation.yield(mockState)
      }
    }

    init(step: PrimerKlarnaState.Step = .categorySelection) {
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
          ))
      ]
      mockState = PrimerKlarnaState(step: step, categories: categories)
    }

    func start() {}
    func submit() {}
    func cancel() {}
    func selectPaymentCategory(_ categoryId: String) {
      mockState = PrimerKlarnaState(
        step: mockState.step,
        categories: mockState.categories,
        selectedCategoryId: categoryId
      )
    }
    func authorizePayment() {}
    func finalizePayment() {}
    func onBack() {}
  }
#endif
