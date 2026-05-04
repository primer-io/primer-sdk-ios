//
//  AdyenKlarnaScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AdyenKlarnaScreen: View {

    private enum Constants {
        static let logoHeight: CGFloat = 60
        static let optionItemHeight: CGFloat = 56
        static let optionItemSpacing: CGFloat = 8
        static let klarnaLogoWrapperWidth: CGFloat = 56
        static let klarnaLogoWrapperHeight: CGFloat = 40
        static let klarnaLogoImageHeight: CGFloat = 10
        static let klarnaPink = Color(red: 1.0, green: 0.702, blue: 0.78)
    }

    let scope: any PrimerAdyenKlarnaScope

    @Environment(\.designTokens) private var tokens
    @State private var adyenKlarnaState = PrimerAdyenKlarnaState()

    var body: some View {
        VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
            makeHeaderSection()
            makeContentSection()
            Spacer()
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .frame(maxWidth: UIScreen.main.bounds.width)
        .navigationBarHidden(true)
        .background(CheckoutColors.background(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.AdyenKlarna.container)
        .task {
            for await state in scope.state {
                adyenKlarnaState = state
            }
        }
    }

    // MARK: - Header

    private func makeHeaderSection() -> some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            HStack {
                if scope.presentationContext.shouldShowBackButton {
                    Button(action: scope.onBack) {
                        HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                            Image(systemName: RTLIcon.backChevron)
                                .font(PrimerFont.bodyMedium(tokens: tokens))
                            Text(CheckoutComponentsStrings.backButton)
                        }
                        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    }
                    .accessibility(config: AccessibilityConfiguration(
                        identifier: AccessibilityIdentifiers.AdyenKlarna.backButton,
                        label: CheckoutComponentsStrings.a11yBack,
                        traits: [.isButton]
                    ))
                }

                Spacer()

                if scope.dismissalMechanism.contains(.closeButton) {
                    Button(CheckoutComponentsStrings.cancelButton, action: scope.cancel)
                        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                        .accessibility(config: AccessibilityConfiguration(
                            identifier: AccessibilityIdentifiers.AdyenKlarna.cancelButton,
                            label: CheckoutComponentsStrings.a11yCancel,
                            traits: [.isButton]
                        ))
                }
            }

            Text(CheckoutComponentsStrings.adyenKlarnaTitle)
                .font(PrimerFont.titleXLarge(tokens: tokens))
                .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(AccessibilityIdentifiers.AdyenKlarna.title)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func makeContentSection() -> some View {
        switch adyenKlarnaState.status {
        case .optionSelection:
            makeOptionSelectionContent()
        case .loading:
            makeLoadingContent()
        case .submitting, .redirecting, .polling:
            makeRedirectingContent()
        default:
            EmptyView()
        }
    }

    // MARK: - Option Selection

    private func makeOptionSelectionContent() -> some View {
        VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
            Text(CheckoutComponentsStrings.adyenKlarnaSelectOption)
                .font(PrimerFont.body(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVStack(spacing: Constants.optionItemSpacing) {
                    ForEach(adyenKlarnaState.paymentOptions, id: \.id) { option in
                        makeOptionItem(option)
                    }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.AdyenKlarna.optionList)
            }
        }
    }

    private func makeOptionItem(_ option: AdyenKlarnaPaymentOption) -> some View {
        Button {
            scope.selectOption(option)
        } label: {
            HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                makeKlarnaLogoBadge()

                Text(CheckoutComponentsStrings.adyenKlarnaOptionDisplayName(for: option.name))
                    .font(PrimerFont.bodyLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

                Spacer()
            }
            .frame(height: Constants.optionItemHeight)
            .frame(maxWidth: .infinity)
            .background(CheckoutColors.background(tokens: tokens))
            .overlay(
                RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                    .stroke(CheckoutColors.borderDefault(tokens: tokens), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens)))
        }
        .buttonStyle(PaymentMethodButtonStyle())
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.AdyenKlarna.optionButton(option.id),
            label: CheckoutComponentsStrings.a11yAdyenKlarnaOptionButton(option.name),
            traits: [.isButton]
        ))
    }

    private func makeKlarnaLogoBadge() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                .fill(Constants.klarnaPink)

            if let klarnaLogo = UIImage(primerResource: "klarna-icon-colored") {
                Image(uiImage: klarnaLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Constants.klarnaLogoImageHeight)
            }
        }
        .frame(width: Constants.klarnaLogoWrapperWidth, height: Constants.klarnaLogoWrapperHeight)
        .padding(.leading, PrimerSpacing.small(tokens: tokens))
    }

    // MARK: - Loading & Redirecting

    private func makeLoadingContent() -> some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            Spacer()
            makePaymentMethodLogo()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.textSecondary(tokens: tokens)))
                .scaleEffect(PrimerScale.small)
            Spacer()
        }
    }

    private func makeRedirectingContent() -> some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            Spacer()
            makePaymentMethodLogo()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.textSecondary(tokens: tokens)))
                .scaleEffect(PrimerScale.small)
            Spacer()
        }
    }

    private func makePaymentMethodLogo() -> some View {
        Group {
            if let icon = adyenKlarnaState.paymentMethod?.icon {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Constants.logoHeight)
            } else if let klarnaLogo = UIImage(primerResource: "klarna-logo-colored") {
                Image(uiImage: klarnaLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Constants.logoHeight)
            }
        }
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.AdyenKlarna.logo,
            label: CheckoutComponentsStrings.adyenKlarnaTitle
        ))
    }
}
