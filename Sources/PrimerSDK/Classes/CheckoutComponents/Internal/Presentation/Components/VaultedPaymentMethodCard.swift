//
//  VaultedPaymentMethodCard.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - VaultedPaymentMethodCard View

/// Card component displaying a vaulted payment method with brand icon, masked data, and selection state.
/// Uses `VaultedPaymentMethodDisplayData` for normalized rendering across payment types.
///
/// In edit mode, the card shows a delete button instead of a selection checkmark, and row taps are disabled.
@available(iOS 15.0, *)
struct VaultedPaymentMethodCard: View {
    let vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
    let isSelected: Bool
    let isEditMode: Bool
    let cvvInputContent: (() -> AnyView)?
    let onTap: (() -> Void)?
    let onDeleteTapped: (() -> Void)?

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod,
        isSelected: Bool = false,
        isEditMode: Bool = false,
        cvvInputContent: (() -> AnyView)? = nil,
        onTap: (() -> Void)? = nil,
        onDeleteTapped: (() -> Void)? = nil
    ) {
        self.vaultedPaymentMethod = vaultedPaymentMethod
        self.isSelected = isSelected
        self.isEditMode = isEditMode
        self.cvvInputContent = cvvInputContent
        self.onTap = onTap
        self.onDeleteTapped = onDeleteTapped
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            makeCardContent()
            if isEditMode {
                makeDeleteButton()
            }
        }
    }

    // MARK: - Card Content

    private func makeCardContent() -> some View {
        Button(action: { if !isEditMode { onTap?() } }) {
            VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
                makeMainCardRow()

                if let cvvInputContent {
                    cvvInputContent()
                }
            }
            .padding(PrimerSpacing.medium(tokens: tokens))
            .frame(height: cvvInputContent == nil ? PrimerComponentHeight.vaultedPaymentMethodCard : nil)
            .background(makeCardBackground())
            .overlay(makeCardBorder())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.PaymentSelection.vaultedPaymentMethodItem(vaultedPaymentMethod.id),
            label: vaultedPaymentMethod.displayData.accessibilityLabel,
            traits: isEditMode ? [] : (isSelected ? [.isButton, .isSelected] : [.isButton])
        ))
    }

    // MARK: - Main Card Row

    private func makeMainCardRow() -> some View {
        HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
            makeLeftContent()
            Spacer()
            makeRightContent()
            if isSelected, !isEditMode {
                makeCheckmark()
            }
        }
        .frame(height: PrimerComponentHeight.vaultedPaymentMethodCardContentRow)
    }

    // MARK: - Delete Button

    private func makeDeleteButton() -> some View {
        Button(action: { onDeleteTapped?() }) {
            HStack {
                Spacer()
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    .frame(width: 20, height: 20)
            }
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.PaymentSelection.deletePaymentMethodButton(vaultedPaymentMethod.id),
            label: CheckoutComponentsStrings.a11yDeletePaymentMethod,
            traits: [.isButton]
        ))
    }

    // MARK: - Display Data

    private var displayData: VaultedPaymentMethodDisplayData {
        vaultedPaymentMethod.displayData
    }

    // MARK: - Left Content

    private func makeLeftContent() -> some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            // Name row (hidden if nil)
            if let name = displayData.name {
                Text(name)
                    .font(PrimerFont.bodyLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    .lineLimit(1)
            }

            // Brand row
            HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                makeBrandBadge()
                Text(displayData.brandName)
                    .font(PrimerFont.bodySmall(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Brand Badge

    private func makeBrandBadge() -> some View {
        Group {
            if let icon = displayData.brandIcon {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: PrimerCardNetworkSelector.badgeWidth,
                        height: PrimerCardNetworkSelector.badgeHeight
                    )
                    .clipped()
                    .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
            } else {
                // Fallback: 2-letter abbreviation
                Text(displayData.brandName.prefix(2).uppercased())
                    .font(PrimerFont.smallBadge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .frame(
                        width: PrimerCardNetworkSelector.badgeWidth,
                        height: PrimerCardNetworkSelector.badgeHeight
                    )
                    .background(CheckoutColors.gray100(tokens: tokens))
                    .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
            }
        }
    }

    // MARK: - Right Content

    @ViewBuilder
    private func makeRightContent() -> some View {
        VStack(alignment: .trailing, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            if let primaryValue = displayData.primaryValue {
                Text(primaryValue)
                    .font(PrimerFont.bodyMedium(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    .lineLimit(1)
            }

            if let secondaryValue = displayData.secondaryValue {
                Text(secondaryValue)
                    .font(PrimerFont.bodySmall(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Checkmark

    private func makeCheckmark() -> some View {
        Image(systemName: "checkmark")
            .font(PrimerFont.body(tokens: tokens))
            .foregroundColor(CheckoutColors.borderFocus(tokens: tokens))
    }

    // MARK: - Card Background

    private func makeCardBackground() -> some View {
        RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
            .fill(CheckoutColors.background(tokens: tokens))
    }

    // MARK: - Card Border

    private func makeCardBorder() -> some View {
        RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
            .stroke(
                isSelected ? CheckoutColors.borderFocus(tokens: tokens) : CheckoutColors.borderDefault(tokens: tokens),
                lineWidth: isSelected ? PrimerBorderWidth.selected : PrimerBorderWidth.standard
            )
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
private enum VaultedPaymentMethodPreviewData {

    // MARK: - Mock PaymentInstrumentData

    static func makePaymentInstrumentData(
        last4Digits: String? = nil,
        expirationMonth: String? = nil,
        expirationYear: String? = nil,
        cardholderName: String? = nil,
        network: String? = nil,
        bankName: String? = nil,
        accountNumberLast4Digits: String? = nil,
        externalPayerInfo: [String: Any]? = nil
    ) -> Response.Body.Tokenization.PaymentInstrumentData {
        var json: [String: Any] = [:]

        if let last4Digits { json["last4Digits"] = last4Digits }
        if let expirationMonth { json["expirationMonth"] = expirationMonth }
        if let expirationYear { json["expirationYear"] = expirationYear }
        if let cardholderName { json["cardholderName"] = cardholderName }
        if let network { json["network"] = network }
        if let bankName { json["bankName"] = bankName }
        if let accountNumberLast4Digits { json["accountNumberLast4Digits"] = accountNumberLast4Digits }
        if let externalPayerInfo { json["externalPayerInfo"] = externalPayerInfo }

        let data = try! JSONSerialization.data(withJSONObject: json) // swiftlint:disable:this force_try
        return try! JSONDecoder().decode(Response.Body.Tokenization.PaymentInstrumentData.self, from: data) // swiftlint:disable:this force_try
    }

    // MARK: - Mock VaultedPaymentMethod

    static func makeVaultedPaymentMethod(
        id: String = UUID().uuidString,
        paymentMethodType: String,
        paymentInstrumentType: PaymentInstrumentType,
        paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: paymentMethodType,
            paymentInstrumentType: paymentInstrumentType,
            paymentInstrumentData: paymentInstrumentData,
            analyticsId: "preview-analytics-id"
        )
    }

    // MARK: - Sample Data

    static var visaCard: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        makeVaultedPaymentMethod(
            paymentMethodType: "PAYMENT_CARD",
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "4242",
                expirationMonth: "12",
                expirationYear: "2026",
                cardholderName: "John Appleseed",
                network: "Visa"
            )
        )
    }

    static var mastercard: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        makeVaultedPaymentMethod(
            paymentMethodType: "PAYMENT_CARD",
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "5678",
                expirationMonth: "03",
                expirationYear: "2025",
                network: "Mastercard"
            )
        )
    }

    static var paypal: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        makeVaultedPaymentMethod(
            paymentMethodType: "PAYPAL",
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: [
                    "email": "john.appleseed@gmail.com",
                    "firstName": "John",
                    "lastName": "Appleseed"
                ]
            )
        )
    }

    static var klarna: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        makeVaultedPaymentMethod(
            paymentMethodType: "KLARNA",
            paymentInstrumentType: .klarnaCustomerToken,
            paymentInstrumentData: makePaymentInstrumentData()
        )
    }

    static var achBank: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        makeVaultedPaymentMethod(
            paymentMethodType: "STRIPE_ACH",
            paymentInstrumentType: .stripeAch,
            paymentInstrumentData: makePaymentInstrumentData(
                cardholderName: "Jane Smith",
                bankName: "Chase",
                accountNumberLast4Digits: "9876"
            )
        )
    }
}

// MARK: - All Payment Methods

@available(iOS 17.0, *)
#Preview("All Payment Methods") {
    ScrollView {
        VStack(spacing: PrimerSpacing.small(tokens: nil)) {
            VaultedPaymentMethodCard(
                vaultedPaymentMethod: VaultedPaymentMethodPreviewData.visaCard,
                isSelected: true
            )
            VaultedPaymentMethodCard(
                vaultedPaymentMethod: VaultedPaymentMethodPreviewData.mastercard
            )
            VaultedPaymentMethodCard(
                vaultedPaymentMethod: VaultedPaymentMethodPreviewData.paypal
            )
            VaultedPaymentMethodCard(
                vaultedPaymentMethod: VaultedPaymentMethodPreviewData.klarna
            )
            VaultedPaymentMethodCard(
                vaultedPaymentMethod: VaultedPaymentMethodPreviewData.achBank
            )
        }
        .padding()
    }
}

// MARK: - Selection States

@available(iOS 17.0, *)
#Preview("Selected") {
    VaultedPaymentMethodCard(
        vaultedPaymentMethod: VaultedPaymentMethodPreviewData.visaCard,
        isSelected: true
    )
    .padding()
}

@available(iOS 17.0, *)
#Preview("Unselected") {
    VaultedPaymentMethodCard(
        vaultedPaymentMethod: VaultedPaymentMethodPreviewData.visaCard
    )
    .padding()
}

// MARK: - Edit Mode

@available(iOS 17.0, *)
#Preview("Edit Mode") {
    VaultedPaymentMethodCard(
        vaultedPaymentMethod: VaultedPaymentMethodPreviewData.visaCard,
        isEditMode: true,
        onDeleteTapped: {}
    )
    .padding()
}

// MARK: - Dark Mode

@available(iOS 17.0, *)
#Preview("Dark Mode") {
    VaultedPaymentMethodCard(
        vaultedPaymentMethod: VaultedPaymentMethodPreviewData.visaCard,
        isSelected: true
    )
    .padding()
    .preferredColorScheme(.dark)
}
#endif
