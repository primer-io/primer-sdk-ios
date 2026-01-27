//
//  KlarnaView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default Klarna payment screen for CheckoutComponents.
/// Shows payment category selection, embedded Klarna SDK view, and authorize/finalize buttons.
@available(iOS 15.0, *)
struct KlarnaView: View, LogReporter {
    let scope: any PrimerKlarnaScope

    @Environment(\.designTokens) private var tokens
    @State private var klarnaState: KlarnaState = .init()

    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.bottom, PrimerSpacing.xlarge(tokens: tokens))

            ScrollView {
                contentSection
            }
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .frame(maxWidth: UIScreen.main.bounds.width)
        .navigationBarHidden(true)
        .background(CheckoutColors.background(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.container)
        .onAppear {
            observeState()
        }
    }

    // MARK: - Header Section

    @MainActor
    private var headerSection: some View {
        HStack {
            if scope.presentationContext.shouldShowBackButton {
                Button(action: {
                    scope.onBack()
                }, label: {
                    HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                        Image(systemName: RTLIcon.backChevron)
                            .font(PrimerFont.bodyMedium(tokens: tokens))
                        Text(CheckoutComponentsStrings.backButton)
                    }
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                })
                .accessibility(config: AccessibilityConfiguration(
                    identifier: AccessibilityIdentifiers.Common.backButton,
                    label: CheckoutComponentsStrings.a11yBack,
                    traits: [.isButton]
                ))
            }

            Spacer()

            // Klarna logo
            klarnaLogo

            Spacer()

            if scope.dismissalMechanism.contains(.closeButton) {
                Button(CheckoutComponentsStrings.cancelButton, action: {
                    scope.onCancel()
                })
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .accessibility(config: AccessibilityConfiguration(
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
    private var klarnaLogo: some View {
        Group {
            if let logoImage = UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil) {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 24)
            } else {
                Text(CheckoutComponentsStrings.klarnaBrandName)
                    .font(PrimerFont.titleLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            }
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Klarna.logo,
            label: CheckoutComponentsStrings.klarnaBrandName
        ))
    }

    // MARK: - Content Section

    @MainActor
    @ViewBuilder
    private var contentSection: some View {
        switch klarnaState.step {
        case .loading:
            loadingContent
        case .categorySelection, .viewReady:
            categorySelectionContent
        case .authorizationStarted:
            loadingContent
        case .awaitingFinalization:
            finalizationContent
        }
    }

    // MARK: - Loading Content

    @MainActor
    private var loadingContent: some View {
        VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            Spacer()
                .frame(height: PrimerSpacing.xxlarge(tokens: tokens) * 2)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.blue(tokens: tokens)))
                .scaleEffect(PrimerScale.large)
                .frame(width: 56, height: 56)
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
    private var categorySelectionContent: some View {
        VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            // Category cards
            VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                ForEach(klarnaState.categories, id: \.id) { category in
                    categoryCard(for: category)
                }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.categoriesContainer)

            // Authorize button (visible when a category is selected and view is ready)
            if klarnaState.step == .viewReady {
                authorizeButtonSection
                    .padding(.top, PrimerSpacing.large(tokens: tokens))
            }
        }
    }

    @MainActor
    private func categoryCard(for category: KlarnaPaymentCategory) -> some View {
        let isSelected = klarnaState.selectedCategoryId == category.id

        return VStack(alignment: .leading, spacing: isSelected ? PrimerSpacing.medium(tokens: tokens) : 0) {
            // Category header
            Button(action: {
                scope.selectPaymentCategory(category.id)
            }) {
                HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
                    // Category badge image
                    categoryBadge(for: category)

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
                    .frame(minHeight: 200)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.paymentViewContainer)
                    .accessibilityLabel(CheckoutComponentsStrings.a11yKlarnaPaymentView)
            } else if isSelected, scope.paymentView == nil, klarnaState.step != .viewReady {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.blue(tokens: tokens)))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .accessibilityLabel(CheckoutComponentsStrings.a11yLoading)
            }
        }
        .padding(PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.background(tokens: tokens))
        .overlay(
            RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                .stroke(
                    isSelected ? CheckoutColors.blue(tokens: tokens) : CheckoutColors.borderDefault(tokens: tokens),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens)))
    }

    @MainActor
    private func categoryBadge(for category: KlarnaPaymentCategory) -> some View {
        AsyncImage(url: URL(string: category.standardAssetUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.pink.opacity(0.8))
                .overlay(
                    Text("K")
                        .font(PrimerFont.bodyLarge(tokens: tokens))
                        .foregroundColor(.white)
                )
        }
        .frame(width: 56, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    // MARK: - Authorize Button

    @MainActor
    @ViewBuilder
    private var authorizeButtonSection: some View {
        if let customButton = scope.authorizeButton {
            AnyView(customButton(scope))
        } else {
            Button(action: {
                scope.authorizePayment()
            }) {
                Text(CheckoutComponentsStrings.klarnaAuthorizeButton)
                    .font(PrimerFont.body(tokens: tokens))
                    .foregroundColor(CheckoutColors.white(tokens: tokens))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
                    .background(CheckoutColors.textPrimary(tokens: tokens))
                    .cornerRadius(PrimerRadius.small(tokens: tokens))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.authorizeButton)
            .accessibilityLabel(CheckoutComponentsStrings.klarnaAuthorizeButton)
            .accessibilityHint(CheckoutComponentsStrings.a11yKlarnaAuthorizeHint)
        }
    }

    // MARK: - Finalization Content

    @MainActor
    private var finalizationContent: some View {
        VStack(spacing: PrimerSpacing.xlarge(tokens: tokens)) {
            Text(CheckoutComponentsStrings.klarnaSelectCategoryDescription)
                .font(PrimerFont.bodyMedium(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .multilineTextAlignment(.center)

            if let customButton = scope.finalizeButton {
                AnyView(customButton(scope))
            } else {
                Button(action: {
                    scope.finalizePayment()
                }) {
                    Text(CheckoutComponentsStrings.klarnaFinalizeButton)
                        .font(PrimerFont.body(tokens: tokens))
                        .foregroundColor(CheckoutColors.white(tokens: tokens))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
                        .background(CheckoutColors.textPrimary(tokens: tokens))
                        .cornerRadius(PrimerRadius.small(tokens: tokens))
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Klarna.finalizeButton)
                .accessibilityLabel(CheckoutComponentsStrings.klarnaFinalizeButton)
                .accessibilityHint(CheckoutComponentsStrings.a11yKlarnaFinalizeHint)
            }
        }
        .padding(.top, PrimerSpacing.xlarge(tokens: tokens))
    }

    // MARK: - State Observation

    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    klarnaState = state
                }
            }
        }
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
    var categoryItem: KlarnaCategoryItemComponent?

    @Published private var mockState: KlarnaState

    var state: AsyncStream<KlarnaState> {
        AsyncStream { continuation in
            continuation.yield(mockState)
        }
    }

    init(step: KlarnaState.Step = .categorySelection) {
        let categories = [
            KlarnaPaymentCategory(response: Response.Body.Klarna.SessionCategory(
                identifier: "pay_now", name: "Pay now",
                descriptiveAssetUrl: "", standardAssetUrl: ""
            )),
            KlarnaPaymentCategory(response: Response.Body.Klarna.SessionCategory(
                identifier: "pay_later", name: "Pay in 30 days",
                descriptiveAssetUrl: "", standardAssetUrl: ""
            ))
        ]
        self.mockState = KlarnaState(step: step, categories: categories)
    }

    func start() {}
    func submit() {}
    func cancel() {}
    func selectPaymentCategory(_ categoryId: String) {
        mockState.selectedCategoryId = categoryId
    }
    func authorizePayment() {}
    func finalizePayment() {}
    func onBack() {}
    func onCancel() {}
}
#endif
