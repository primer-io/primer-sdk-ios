//
//  WebRedirectScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct WebRedirectScreen: View {

    private enum Constants {
        static let logoHeight: CGFloat = 60
    }

    let scope: any PrimerWebRedirectScope

    @Environment(\.designTokens) private var tokens
    @State private var webRedirectState: WebRedirectState = .init()

    var body: some View {
        VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
            makeHeaderSection()
            makeContentSection()
            Spacer()
            makeSubmitButtonSection()
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .frame(maxWidth: UIScreen.main.bounds.width)
        .navigationBarHidden(true)
        .background(CheckoutColors.background(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.WebRedirect.container)
        .task {
            for await state in scope.state {
                webRedirectState = state
            }
        }
    }

    // MARK: - Header Section

    @MainActor
    private func makeHeaderSection() -> some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
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
                        identifier: AccessibilityIdentifiers.WebRedirect.backButton,
                        label: CheckoutComponentsStrings.a11yBack,
                        traits: [.isButton]
                    ))
                }

                Spacer()

                if scope.dismissalMechanism.contains(.closeButton) {
                    Button(CheckoutComponentsStrings.cancelButton, action: {
                        scope.onCancel()
                    })
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .accessibility(config: AccessibilityConfiguration(
                        identifier: AccessibilityIdentifiers.WebRedirect.cancelButton,
                        label: CheckoutComponentsStrings.a11yCancel,
                        traits: [.isButton]
                    ))
                }
            }

            makeTitleSection()
        }
    }

    @MainActor
    private func makeTitleSection() -> some View {
        Text(paymentMethodDisplayName)
            .font(PrimerFont.titleXLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(AccessibilityIdentifiers.WebRedirect.title)
    }

    // MARK: - Content Section

    @MainActor
    private func makeContentSection() -> some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            // Payment method logo
            makePaymentMethodLogo()

            // Redirect description
            Text(CheckoutComponentsStrings.webRedirectDescription)
                .font(PrimerFont.body(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(AccessibilityIdentifiers.WebRedirect.description)

            // Surcharge info if applicable
            if let surcharge = webRedirectState.surchargeAmount {
                Text(surcharge)
                    .font(PrimerFont.bodySmall(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .accessibilityIdentifier(AccessibilityIdentifiers.WebRedirect.surcharge)
            }
        }
        .padding(.vertical, PrimerSpacing.xlarge(tokens: tokens))
    }

    @MainActor
    private func makePaymentMethodLogo() -> some View {
        Group {
            if let icon = webRedirectState.paymentMethod?.icon {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Constants.logoHeight)
            } else {
                makeFallbackLogo()
            }
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.WebRedirect.logo,
            label: paymentMethodDisplayName
        ))
    }

    @MainActor
    private func makeFallbackLogo() -> some View {
        Text(paymentMethodDisplayName)
            .font(PrimerFont.titleXLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
    }

    // MARK: - Submit Button Section

    @MainActor
    @ViewBuilder
    private func makeSubmitButtonSection() -> some View {
        // Check for custom button
        if let customButton = scope.payButton {
            AnyView(customButton(scope))
        } else {
            Button(action: submitAction) {
                makeSubmitButtonContent()
            }
            .disabled(isButtonDisabled)
        }
    }

    private func makeSubmitButtonContent() -> some View {
        let isLoading = [.loading, .redirecting, .polling].contains(webRedirectState.status)

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
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.WebRedirect.submitButton,
            label: submitButtonAccessibilityLabel,
            hint: isButtonDisabled ? CheckoutComponentsStrings.a11ySubmitButtonDisabled : CheckoutComponentsStrings.a11ySubmitButtonHint,
            traits: [.isButton]
        ))
    }

    private var submitButtonText: String {
        scope.submitButtonText ?? CheckoutComponentsStrings.webRedirectButtonContinue(paymentMethodDisplayName)
    }

    private var submitButtonAccessibilityLabel: String {
        let isLoading = [.loading, .redirecting, .polling].contains(webRedirectState.status)
        return isLoading
            ? CheckoutComponentsStrings.a11ySubmitButtonLoading
            : CheckoutComponentsStrings.a11yWebRedirectSubmitButton(paymentMethodDisplayName)
    }

    private var submitButtonBackground: Color {
        isButtonDisabled
            ? CheckoutColors.gray300(tokens: tokens)
            : CheckoutColors.textPrimary(tokens: tokens)
    }

    private var isButtonDisabled: Bool {
        [.loading, .redirecting, .polling].contains(webRedirectState.status)
    }

    private var paymentMethodDisplayName: String {
        webRedirectState.paymentMethod?.name ?? scope.paymentMethodType
    }

    private func submitAction() {
        scope.submit()
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
#Preview("WebRedirect - Light") {
    WebRedirectScreen(scope: MockWebRedirectScope())
        .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
#Preview("WebRedirect - Dark") {
    WebRedirectScreen(scope: MockWebRedirectScope())
        .environment(\.designTokens, MockDesignTokens.dark)
        .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("WebRedirect - Loading") {
    WebRedirectScreen(scope: MockWebRedirectScope(status: .loading))
        .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
#Preview("WebRedirect - Redirecting") {
    WebRedirectScreen(scope: MockWebRedirectScope(status: .redirecting))
        .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
@MainActor
private final class MockWebRedirectScope: PrimerWebRedirectScope, ObservableObject {

    // MARK: - Protocol Properties

    let paymentMethodType: String = "ADYEN_SOFORT"
    var presentationContext: PresentationContext = .fromPaymentSelection
    var dismissalMechanism: [DismissalMechanism] = [.closeButton]

    var state: AsyncStream<WebRedirectState> {
        AsyncStream { continuation in
            continuation.yield(mockState)
        }
    }

    // MARK: - UI Customization Properties

    var screen: WebRedirectScreenComponent?
    var payButton: WebRedirectButtonComponent?
    var submitButtonText: String?

    // MARK: - Private Properties

    @Published private var mockState: WebRedirectState

    // MARK: - Initialization

    init(status: WebRedirectState.Status = .idle) {
        let mockPaymentMethod = CheckoutPaymentMethod(
            id: "mock-sofort",
            type: "ADYEN_SOFORT",
            name: "Sofort"
        )
        self.mockState = WebRedirectState(
            status: status,
            paymentMethod: mockPaymentMethod,
            surchargeAmount: "+ €0.50"
        )
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
