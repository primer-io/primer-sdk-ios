//
//  PaymentMethodSelectionScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Data structure for grouping payment methods by surcharge status
private struct PaymentMethodGroup {
    let group: String
    let methods: [CheckoutPaymentMethod]
}

/// Default payment method selection screen for CheckoutComponents
@available(iOS 15.0, *)
struct PaymentMethodSelectionScreen: View {
    let scope: PrimerPaymentMethodSelectionScope

    @Environment(\.designTokens) private var tokens
    @Environment(\.bridgeController) private var bridgeController
    @State private var selectionState: PrimerPaymentMethodSelectionState = .init()

    var body: some View {
        mainContent
    }

    @MainActor
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            contentContainer
        }
        .onAppear {
            observeState()
        }
    }

    @MainActor
    private var headerSection: some View {
        VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            paymentAmountHeader
            titleSection
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.top, PrimerSpacing.large(tokens: tokens))
    }

    @MainActor
    private var paymentAmountHeader: some View {
        HStack {
            // Get payment amount from app state or default
            let amount = AppState.current.amount ?? 9900 // Default to $99.00 if not available
            let currency = AppState.current.currency ?? Currency(code: "USD", decimalDigits: 2)
            let formattedAmount = amount.toCurrencyString(currency: currency)

            Text(CheckoutComponentsStrings.paymentAmountTitle(formattedAmount))
                .font(PrimerFont.titleXLarge(tokens: tokens))
                .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

            Spacer()

            // Show close button based on dismissalMechanism setting
            if scope.dismissalMechanism.contains(.closeButton) {
                Button(CheckoutComponentsStrings.cancelButton, action: scope.onCancel)
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
        }
    }

    @MainActor
    private var contentContainer: some View {
        VStack(spacing: 0) {
            paymentMethodsList
        }
    }

    @MainActor
    private var titleSection: some View {
        return Text(CheckoutComponentsStrings.choosePaymentMethod)
            .font(PrimerFont.titleLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, PrimerSpacing.small(tokens: tokens))
    }

    @MainActor
    private var paymentMethodsList: some View {
        VStack(spacing: 0) {
            ScrollView {
                if selectionState.paymentMethods.isEmpty {
                    emptyStateView
                } else {
                    paymentMethodsContent
                }
            }

            errorSection
        }
        .background(CheckoutColors.background(tokens: tokens))
    }

    @MainActor
    @ViewBuilder
    private var emptyStateView: some View {
        if let customEmptyState = scope.emptyStateView {
            customEmptyState()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "creditcard.and.123")
                    .font(PrimerFont.largeIcon(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

                Text(CheckoutComponentsStrings.noPaymentMethodsAvailable)
                    .font(PrimerFont.body(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
    }

    @MainActor
    private var paymentMethodsContent: some View {
        LazyVStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            ForEach(groupedPaymentMethods, id: \.group) { group in
                paymentMethodGroup(group)
            }
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.bottom, PrimerSpacing.xlarge(tokens: tokens))
    }

    /// Groups payment methods by surcharge status for better UX
    private var groupedPaymentMethods: [PaymentMethodGroup] {
        var groups: [PaymentMethodGroup] = []
        let methods = selectionState.paymentMethods

        // Check if any meaningful surcharge-related configuration exists
        let hasSurchargeConfiguration = methods.contains { method in
            (method.surcharge != nil && method.surcharge! > 0) || method.hasUnknownSurcharge
        }

        // If no surcharge configuration exists, return all methods in a single group without labels
        guard hasSurchargeConfiguration else {
            return [PaymentMethodGroup(group: "", methods: methods)]
        }

        // Group 1: Methods with positive surcharges
        let surchargeMethods = methods.filter { method in
            if let surcharge = method.surcharge, surcharge > 0 {
                return true
            }
            return false
        }

        if !surchargeMethods.isEmpty {
            let highestSurcharge = surchargeMethods.compactMap { $0.surcharge }.max() ?? 0
            let currency = AppState.current.currency ?? Currency(code: "EUR", decimalDigits: 2)
            let formattedSurcharge = "+\(highestSurcharge.toCurrencyString(currency: currency))"

            groups.append(PaymentMethodGroup(
                group: formattedSurcharge,
                methods: surchargeMethods
            ))
        }

        // Group 2: Methods with no additional fees
        let noFeeMethods = methods.filter { method in
            // Include methods with:
            // - surcharge == 0 (explicit no fee)
            // - surcharge == nil AND hasUnknownSurcharge == false (no fee configured)
            if let surcharge = method.surcharge {
                return surcharge == 0
            } else {
                return !method.hasUnknownSurcharge
            }
        }

        if !noFeeMethods.isEmpty {
            groups.append(PaymentMethodGroup(
                group: CheckoutComponentsStrings.noAdditionalFee,
                methods: noFeeMethods
            ))
        }

        // Group 3: Methods with unknown surcharges
        let unknownFeeMethods = methods.filter { method in
            return method.hasUnknownSurcharge
        }

        if !unknownFeeMethods.isEmpty {
            groups.append(PaymentMethodGroup(
                group: CheckoutComponentsStrings.additionalFeeMayApply,
                methods: unknownFeeMethods
            ))
        }

        return groups
    }

    @MainActor
    @ViewBuilder
    private func paymentMethodGroup(_ group: PaymentMethodGroup) -> some View {
        VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            // Group header with surcharge info (only show if group name is not empty)
            if !group.group.isEmpty {
                if let customCategoryHeader = scope.categoryHeader {
                    customCategoryHeader(group.group)
                } else {
                    HStack {
                        Text(group.group)
                            .font(PrimerFont.bodyMedium(tokens: tokens))
                            .foregroundColor(dynamicGroupHeaderColor(for: group.group))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, PrimerSpacing.small(tokens: tokens))
                }
            }

            // Gray rounded container for payment methods group
            VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                ForEach(group.methods, id: \.id) { method in
                    modernPaymentMethodCard(method)
                        .frame(height: PrimerComponentHeight.paymentMethodCard)
                }
            }
            .padding(PrimerSpacing.medium(tokens: tokens)) // Padding inside gray container
            .background(
                RoundedRectangle(cornerRadius: PrimerRadius.large(tokens: tokens))
                    .fill(CheckoutColors.gray100(tokens: tokens))
            )
        }
    }

    /// Get appropriate color for group header using design tokens
    private func dynamicGroupHeaderColor(for groupName: String) -> Color {
        if groupName.hasPrefix("+") {
            // Positive surcharge - use positive color
            return CheckoutColors.iconPositive(tokens: tokens)
        } else if groupName == CheckoutComponentsStrings.additionalFeeMayApply {
            // Unknown surcharge - use warning color
            return CheckoutColors.textSecondary(tokens: tokens)
        } else {
            // No additional fee - use muted color
            return CheckoutColors.textPlaceholder(tokens: tokens)
        }
    }

    @MainActor
    @ViewBuilder
    private func modernPaymentMethodCard(_ method: CheckoutPaymentMethod) -> some View {
        if let customPaymentMethodItem = scope.paymentMethodItem {
            customPaymentMethodItem(method)
                .onTapGesture {
                    scope.onPaymentMethodSelected(paymentMethod: method)
                }
        } else {
            ModernPaymentMethodCardView(
                method: method,
                onTap: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scope.onPaymentMethodSelected(paymentMethod: method)
                    }
                }
            )
        }
    }

    @MainActor
    @ViewBuilder
    private var errorSection: some View {
        if let error = selectionState.error {
            Text(error)
                .font(PrimerFont.caption(tokens: tokens))
                .foregroundColor(CheckoutColors.borderError(tokens: tokens))
                .padding(PrimerSpacing.large(tokens: tokens))
        }
    }

    private func observeState() {
        Task {
            for await state in await scope.state {
                await MainActor.run {
                    self.selectionState = state

                    if !state.paymentMethods.isEmpty {
                        bridgeController?.invalidateContentSize()
                    }
                }
            }
        }
    }
}

/// Modern payment method card view matching Image #2 design
@available(iOS 15.0, *)
private struct ModernPaymentMethodCardView: View {
    let method: CheckoutPaymentMethod
    let onTap: () -> Void

    @Environment(\.designTokens) private var tokens

    var body: some View {
        Button(action: onTap) {
            contentView
        }
        .buttonStyle(ModernCardButtonStyle())
    }

    private var contentView: some View {
        HStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            paymentMethodLogo
            methodNameAndSurcharge
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .background(backgroundView)
    }

    @ViewBuilder
    private var paymentMethodLogo: some View {
        if let icon = method.icon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: PrimerComponentWidth.paymentMethodIcon, height: PrimerSize.large(tokens: tokens))
        } else {
            paymentMethodLogoPlaceholder
        }
    }

    private var paymentMethodLogoPlaceholder: some View {
        // Create logo based on payment method type using bundled assets (like DropIn UI)
        let paymentMethodType = PrimerPaymentMethodType(rawValue: method.type)
        let imageName = paymentMethodType?.defaultImageName ?? .genericCard
        let fallbackImage = imageName.image

        return Image(uiImage: fallbackImage ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: PrimerComponentWidth.paymentMethodIcon, height: PrimerSize.large(tokens: tokens))
    }

    private var methodNameAndSurcharge: some View {
        return Text(method.name)
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(textColorForPaymentMethod)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
            .fill(backgroundColorForPaymentMethod)
    }

    /// Dynamic background color from server or fallback to design tokens
    private var backgroundColorForPaymentMethod: Color {
        // Priority: Server-provided dynamic color > Design tokens fallback
        if let serverColor = method.backgroundColor {
            return Color(serverColor)
        }

        // Fallback to design tokens for consistent styling
        return CheckoutColors.background(tokens: tokens)
    }

    /// Dynamic text color using design tokens for consistent styling
    private var textColorForPaymentMethod: Color {
        // Use design tokens for consistent styling
        return CheckoutColors.textPrimary(tokens: tokens)
    }
}

/// Modern button style with subtle press animation
@available(iOS 15.0, *)
private struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
