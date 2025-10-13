//
//  PaymentMethodSelectionScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Data structure for grouping payment methods by surcharge status
private struct PaymentMethodGroup {
    let group: String
    let methods: [PrimerComposablePaymentMethod]
}

/// Default payment method selection screen for CheckoutComponents
@available(iOS 15.0, *)
struct PaymentMethodSelectionScreen: View {
    let scope: PrimerPaymentMethodSelectionScope

    @Environment(\.designTokens) private var tokens
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
        VStack(spacing: tokens?.primerSpaceSmall ?? 8) {
            paymentAmountHeader
            titleSection
        }
        .padding(.horizontal, tokens?.primerSpaceLarge ?? 16)
        .padding(.top, tokens?.primerSpaceLarge ?? 16)
    }

    @MainActor
    private var paymentAmountHeader: some View {
        HStack {
            // Get payment amount from app state or default
            let amount = AppState.current.amount ?? 9900 // Default to $99.00 if not available
            let currency = AppState.current.currency ?? Currency(code: "USD", decimalDigits: 2)
            let formattedAmount = amount.toCurrencyString(currency: currency)

            // Break up complex font expression to avoid compiler timeout
            let fontSize = tokens?.primerTypographyTitleXlargeSize ?? 24
            let fontWeight: Font.Weight = .semibold  // Use design system semantic weight

            Text(CheckoutComponentsStrings.paymentAmountTitle(formattedAmount))
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            Spacer()

            Button(CheckoutComponentsStrings.cancelButton) {
                scope.onCancel()
            }
            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
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
        // Break up complex font expression to avoid compiler timeout
        let fontSize = tokens?.primerTypographyTitleLargeSize ?? 16
        let fontWeight: Font.Weight = .medium  // Use design system semantic weight

        return Text(CheckoutComponentsStrings.choosePaymentMethod)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, tokens?.primerSpaceSmall ?? 8)
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
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
    }

    @MainActor
    @ViewBuilder
    private var emptyStateView: some View {
        if let customEmptyState = scope.emptyStateView {
            customEmptyState()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 48))
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

                Text(CheckoutComponentsStrings.noPaymentMethodsAvailable)
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
    }

    @MainActor
    private var paymentMethodsContent: some View {
        LazyVStack(spacing: tokens?.primerSpaceLarge ?? 16) {
            ForEach(groupedPaymentMethods, id: \.group) { group in
                paymentMethodGroup(group)
            }
        }
        .padding(.horizontal, tokens?.primerSpaceLarge ?? 16)
        .padding(.bottom, tokens?.primerSpaceXlarge ?? 20)
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
                group: CheckoutComponentsStrings.feeMayApply,
                methods: unknownFeeMethods
            ))
        }

        return groups
    }

    @MainActor
    @ViewBuilder
    private func paymentMethodGroup(_ group: PaymentMethodGroup) -> some View {
        VStack(spacing: tokens?.primerSpaceSmall ?? 8) {
            // Group header with surcharge info (only show if group name is not empty)
            if !group.group.isEmpty {
                if let customCategoryHeader = scope.categoryHeader {
                    customCategoryHeader(group.group)
                } else {
                    HStack {
                        let headerFontSize = tokens?.primerTypographyBodyMediumSize ?? 14
                        let headerFontWeight: Font.Weight = .medium

                        Text(group.group)
                            .font(.system(size: headerFontSize, weight: headerFontWeight))
                            .foregroundColor(dynamicGroupHeaderColor(for: group.group))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, tokens?.primerSpaceSmall ?? 8)
                }
            }

            // Gray rounded container for payment methods group
            VStack(spacing: tokens?.primerSpaceSmall ?? 8) {
                ForEach(group.methods, id: \.id) { method in
                    modernPaymentMethodCard(method)
                        .frame(height: 44) // Figma spec: 44pt height
                }
            }
            .padding(tokens?.primerSpaceMedium ?? 12) // Padding inside gray container
            .background(
                RoundedRectangle(cornerRadius: tokens?.primerRadiusLarge ?? 12)
                    .fill(tokens?.primerColorGray100 ?? Color(.systemGray6))
            )
        }
    }

    /// Get appropriate color for group header using design tokens
    private func dynamicGroupHeaderColor(for groupName: String) -> Color {
        if groupName.hasPrefix("+") {
            // Positive surcharge - use positive color
            return tokens?.primerColorIconPositive ?? Color(.systemGreen)
        } else if groupName == CheckoutComponentsStrings.feeMayApply {
            // Unknown surcharge - use warning color
            return tokens?.primerColorTextSecondary ?? Color(.secondaryLabel)
        } else {
            // No additional fee - use muted color
            return tokens?.primerColorTextPlaceholder ?? Color(.tertiaryLabel)
        }
    }

    @MainActor
    @ViewBuilder
    private func modernPaymentMethodCard(_ method: PrimerComposablePaymentMethod) -> some View {
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
                .font(.caption)
                .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)
                .padding()
        }
    }

    private func observeState() {
        Task {
            for await state in await scope.state {
                await MainActor.run {
                    self.selectionState = state
                }
            }
        }
    }
}

/// Modern payment method card view matching Image #2 design
@available(iOS 15.0, *)
private struct ModernPaymentMethodCardView: View {
    let method: PrimerComposablePaymentMethod
    let onTap: () -> Void

    @Environment(\.designTokens) private var tokens

    var body: some View {
        Button(action: onTap) {
            contentView
        }
        .buttonStyle(ModernCardButtonStyle())
    }

    private var contentView: some View {
        HStack(spacing: tokens?.primerSpaceLarge ?? 16) {
            paymentMethodLogo
            methodNameAndSurcharge
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, tokens?.primerSpaceLarge ?? 16)
        .padding(.vertical, tokens?.primerSpaceMedium ?? 12)
        .background(backgroundView)
    }

    @ViewBuilder
    private var paymentMethodLogo: some View {
        if let icon = method.icon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 24)
        } else {
            paymentMethodLogoPlaceholder
        }
    }

    private var paymentMethodLogoPlaceholder: some View {
        // Create logo based on payment method type
        Group {
            switch method.type {
            case "APPLE_PAY":
                applePayLogo
            case "GOOGLE_PAY":
                googlePayLogo
            case "PAYPAL":
                paypalLogo
            case "PAYMENT_CARD":
                cardLogo
            case "KLARNA":
                klarnaLogo
            case "ADYEN_IDEAL":
                idealLogo
            default:
                genericLogo
            }
        }
        .frame(width: 32, height: 24)
    }

    private var applePayLogo: some View {
        HStack(spacing: 2) {
            Image(systemName: "applelogo")
                .font(.system(size: 12, weight: .medium))
            Text("Pay")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(tokens?.primerColorIconPrimary ?? .primary)
    }

    private var googlePayLogo: some View {
        HStack(spacing: 2) {
            Text("G")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tokens?.primerColorBrand ?? .blue)
            Text("Pay")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(tokens?.primerColorIconPrimary ?? .primary)
        }
    }

    private var paypalLogo: some View {
        Text("PayPal")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(tokens?.primerColorBlue500 ?? .blue)
    }

    private var cardLogo: some View {
        Image(systemName: "creditcard")
            .font(.system(size: 14))
            .foregroundColor(tokens?.primerColorIconPrimary ?? .secondary)
    }

    private var klarnaLogo: some View {
        Text("Klarna")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(tokens?.primerColorIconPrimary ?? .primary)
    }

    private var idealLogo: some View {
        Text("iDeal")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(tokens?.primerColorIconPrimary ?? .orange)
    }

    private var genericLogo: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(tokens?.primerColorGray200 ?? Color(.systemGray4))
            .overlay(
                Text(String(method.type.prefix(2)))
                    .font(.caption2)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            )
    }

    private var methodNameAndSurcharge: some View {
        // Break up complex font expression to avoid compiler timeout
        let methodNameFontSize = tokens?.primerTypographyBodyLargeSize ?? 16
        let methodNameFontWeight: Font.Weight = .medium  // Use design system semantic weight

        return Text(method.name)
            .font(.system(size: methodNameFontSize, weight: methodNameFontWeight))
            .foregroundColor(textColorForPaymentMethod)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: tokens?.primerRadiusMedium ?? 8)
            .fill(backgroundColorForPaymentMethod)
    }

    /// Dynamic background color from server or fallback to design tokens
    private var backgroundColorForPaymentMethod: Color {
        // Priority: Server-provided dynamic color > Design tokens fallback
        if let serverColor = method.backgroundColor {
            return Color(serverColor)
        }

        // Fallback to design tokens for consistent styling
        return tokens?.primerColorBackground ?? Color(.systemBackground)
    }

    /// Dynamic text color using design tokens for consistent styling
    private var textColorForPaymentMethod: Color {
        // Use design tokens for consistent styling
        return tokens?.primerColorTextPrimary ?? Color(.label)
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
