//
//  AccountFundingDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Account Funding — a wallet top-up built on the inline SwiftUI integration, in a made-up merchant
/// brand rather than ours. The merchant owns the amount screen, the saved-card list, the add-a-card
/// panel and both result dialogs; Primer supplies the vault, the card fields and the payment.
///
/// Two limits surface while running it. Paying with a saved card is reachable only through
/// ``PrimerVaultedPaymentMethods``'s submit slot, which is why the pay bar mounts that component
/// with empty header and item slots. And the processing screen has no off switch, so the inline host
/// presents the SDK's own one in a sheet over the merchant dialog.
@available(iOS 15.0, *)
struct AccountFundingDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .accountFunding,
            name: "Account Funding",
            description: "Merchant-branded wallet top-up with saved cards",
            tags: ["VAULT", "PAYMENT_CARD"],
            isCustom: true,
            category: .navigation
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            AccountFundingContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

// MARK: - Flow

@available(iOS 15.0, *)
private struct AccountFundingContent: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @StateObject private var session: PrimerCheckoutSession
    @State private var step: Step = .amount
    @State private var preset = 2500
    @State private var isAddingCard = false
    @State private var status: FundingStatus?

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(
            wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings.withMerchantResultScreens)
        )
    }

    private enum Step { case amount, payments }

    var body: some View {
        ZStack {
            FundingPalette.page.ignoresSafeArea()
            VStack(spacing: 0) {
                FundingBar(
                    title: step == .amount ? "Fund Account" : "Payments",
                    onBack: step == .payments ? { step = .amount } : nil,
                    onClose: { dismiss() }
                )
                switch step {
                case .amount:
                    FundAmountScreen(preset: $preset, amount: amount, currencyCode: currencyCode) {
                        step = .payments
                    }
                case .payments:
                    PaymentsScreen(
                        session: session,
                        amount: amount,
                        onAddCard: { isAddingCard = true },
                        onPaying: { status = .processing }
                    )
                }
            }
            if isAddingCard {
                AddCardPanel(onCancel: { isAddingCard = false }, onConfirm: startCardPayment)
            }
            if let status {
                FundingStatusDialog(status: status, onDismiss: reset)
            }
        }
        // The merchant's own bar carries the title and the close button, so the demo host's
        // navigation bar would only sit on top of it.
        .navigationBarHidden(true)
        .primerCheckoutSession(session) { state in
            switch state {
            case .success: status = .funded
            case let .failure(error): status = .failed(error.localizedDescription)
            default: break
            }
        }
    }

    /// The card form lives in the merchant's panel, so closing it and raising the merchant's own
    /// processing dialog is the merchant's job — the SDK only learns about the submit.
    private func startCardPayment() {
        isAddingCard = false
        status = .processing
    }

    private func reset() {
        status = nil
        step = .amount
    }

    /// The amount the SDK will charge, not the chip the shopper tapped: one client session carries
    /// one amount, and this demo never creates a second one.
    private var amount: String {
        guard let clientSession = session.clientSession, let total = clientSession.totalAmount else { return "" }
        return FundingAmount.format(total, currencyCode: clientSession.currencyCode)
    }

    private var currencyCode: String? { session.clientSession?.currencyCode }
}

// MARK: - Merchant screens

@available(iOS 15.0, *)
private struct FundAmountScreen: View {
    @Binding var preset: Int
    let amount: String
    let currencyCode: String?
    let onProceed: () -> Void

    private let presets = [2500, 5000, 10_000]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fund amount").font(.headline)
                    chips
                    Text("The client session fixes the amount charged, so the chips only steer this screen.")
                        .font(.caption).foregroundColor(.secondary)
                    Text("Funding summary").font(.headline).padding(.top, 8)
                    summary
                }
                .padding(16)
            }
            FundingBottomBar {
                FundingCtaButton(title: "Proceed to payments", isEnabled: !amount.isEmpty, action: onProceed)
            }
        }
    }

    private var chips: some View {
        HStack(spacing: 10) {
            ForEach(presets, id: \.self) { value in
                let isOn = value == preset
                Button { preset = value } label: {
                    Text(FundingAmount.format(value, currencyCode: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isOn ? .white : FundingPalette.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isOn ? FundingPalette.accent : FundingPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FundingPalette.accent, lineWidth: isOn ? 0 : 1)
                        )
                }
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 0) {
            FundingSummaryRow(label: "Deposit amount", value: amount)
            Divider().padding(.horizontal, 16)
            FundingSummaryRow(label: "Total due", value: amount, isBold: true)
        }
        .background(FundingPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Payments screen

@available(iOS 15.0, *)
private struct PaymentsScreen: View {
    @ObservedObject var session: PrimerCheckoutSession
    let amount: String
    let onAddCard: () -> Void
    let onPaying: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            content
            FundingBottomBar { fundButton }
        }
    }

    @ViewBuilder private var content: some View {
        switch session.phase {
        case .initializing:
            FundingSkeleton()
        case .ready:
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let selection = session.selection {
                        SavedCards(selection: selection, isExpanded: $isExpanded)
                    }
                    AddMethods(onAddCard: onAddCard)
                }
                .padding(16)
            }
        }
    }

    /// `PrimerSelectionSession.submitSelectedVaulted()` is internal, so a merchant-owned pay button
    /// has to be handed to ``PrimerVaultedPaymentMethods``'s submit slot. Header and item render
    /// nothing because the list above is the merchant's own, and the component draws nothing at all
    /// without a selected method — hence the disabled stand-in.
    @ViewBuilder private var fundButton: some View {
        if session.selection?.state.selectedVaultedPaymentMethod != nil {
            PrimerVaultedPaymentMethods(
                header: { _ in AnyView(EmptyView()) },
                item: { _, _, _ in AnyView(EmptyView()) },
                submitButton: { isLoading, isEnabled, onSubmit in
                    AnyView(
                        FundingPayButton(amount: amount, isLoading: isLoading, isEnabled: isEnabled) {
                            onSubmit()
                            onPaying()
                        }
                    )
                }
            )
        } else {
            FundingPayButton(amount: amount, isLoading: false, isEnabled: false, action: {})
        }
    }
}

@available(iOS 15.0, *)
private struct SavedCards: View {
    @ObservedObject var selection: PrimerSelectionSession
    @Binding var isExpanded: Bool

    var body: some View {
        let methods = selection.vaultedPaymentMethods
        if !methods.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Saved payment methods").font(.headline).foregroundColor(FundingPalette.ink)
                VStack(spacing: 0) {
                    ForEach(Array(visible(of: methods).enumerated()), id: \.element.id) { index, method in
                        if index > 0 { Divider().padding(.leading, 60) }
                        SavedCardRow(method: method, isSelected: method.id == selected?.id) {
                            selection.selectVaulted(method)
                        }
                    }
                }
                .background(FundingPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if methods.count > 1 {
                    Button { withAnimation { isExpanded.toggle() } } label: {
                        Text(isExpanded ? "Collapse" : "View all")
                            .font(.body.weight(.semibold))
                            .foregroundColor(FundingPalette.ink)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(FundingPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(FundingPalette.outline, lineWidth: 1.5))
                    }
                }
            }
        }
    }

    private var selected: PrimerVaultedPaymentMethods.VaultedMethod? {
        selection.state.selectedVaultedPaymentMethod
    }

    /// Collapsed shows the selected card alone, which is what the shopper is about to pay with.
    private func visible(
        of methods: [PrimerVaultedPaymentMethods.VaultedMethod]
    ) -> [PrimerVaultedPaymentMethods.VaultedMethod] {
        guard !isExpanded, let selected else { return methods }
        return [selected]
    }
}

@available(iOS 15.0, *)
private struct SavedCardRow: View {
    let method: PrimerVaultedPaymentMethods.VaultedMethod
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(network.prefix(4).uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 20)
                    .background(FundingPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text("\(network.capitalized) **** \(method.paymentInstrumentData.last4Digits ?? "••••")")
                    .foregroundColor(FundingPalette.ink)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(FundingPalette.selected)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var network: String {
        method.paymentInstrumentData.network ?? method.paymentMethodType
    }
}

@available(iOS 15.0, *)
private struct AddMethods: View {
    let onAddCard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add new payment method").font(.headline).foregroundColor(FundingPalette.ink)
            // The card row opens the merchant's own panel instead of the SDK flow; everything else
            // hands straight back to `onSelect`.
            PrimerPaymentMethods(
                header: { _ in EmptyView() },
                method: { method, onSelect in
                    let isCard = method.type == "PAYMENT_CARD"
                    BrandButton(method: method, isCard: isCard, action: isCard ? onAddCard : onSelect)
                },
                emptyState: { _ in EmptyView() }
            )
        }
    }
}

@available(iOS 15.0, *)
private struct BrandButton: View {
    let method: CheckoutPaymentMethod
    let isCard: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isCard {
                    Image(systemName: "creditcard")
                    Text("Debit Card")
                } else if let icon = method.icon {
                    Image(uiImage: icon).resizable().scaledToFit().frame(maxHeight: 22)
                } else {
                    Text(method.buttonText ?? method.name)
                }
            }
            .font(.body.weight(.semibold))
            .foregroundColor(isCard ? .white : Color(method.textColor ?? .black))
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isCard ? FundingPalette.card : Color(method.backgroundColor ?? .systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Add card panel

@available(iOS 15.0, *)
private struct AddCardPanel: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea().onTapGesture(perform: onCancel)
            VStack(spacing: 16) {
                Text("Enter Card Details").font(.headline).foregroundColor(FundingPalette.ink)
                PrimerCardForm(
                    cardDetails: { form in
                        VStack(spacing: 12) {
                            CardFormDefaults.cardholderName(form)
                            CardFormDefaults.cardNumber(form)
                            HStack(spacing: 12) {
                                CardFormDefaults.expiryDate(form)
                                CardFormDefaults.cvv(form)
                            }
                        }
                    },
                    billingAddress: { CardFormDefaults.postalCode($0) },
                    submitButton: { buttons(for: $0) }
                )
            }
            .padding(20)
            .background(FundingPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private func buttons(for form: PrimerCardFormSession) -> some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("Cancel").fontWeight(.semibold).foregroundColor(FundingPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(FundingPalette.outline, lineWidth: 1.5))
            }
            // Submit first: confirming tears this panel down, and the payment must already be under way.
            Button {
                form.submit()
                onConfirm()
            } label: {
                Text("Confirm").fontWeight(.semibold).foregroundColor(FundingPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(FundingPalette.cta.opacity(form.state.isValid ? 1 : 0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!form.state.isValid || form.state.isLoading)
        }
    }
}
