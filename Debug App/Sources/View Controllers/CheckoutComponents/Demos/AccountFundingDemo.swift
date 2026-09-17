//
//  AccountFundingDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Account Funding — a wallet top-up built on the inline SwiftUI integration, in a made-up merchant
/// brand rather than ours.
///
/// It follows the order a real integration follows: the merchant's own screen decides how much is
/// being paid, the merchant's backend then creates a client session for that amount, and only then
/// does a ``PrimerCheckoutSession`` exist. From there the merchant still owns the saved-card list,
/// the add-a-card panel, the pay bar and both result dialogs; Primer supplies the vault, the card
/// fields and the payment.
///
/// The two paths hand off differently, and the demo shows both. Adding a card is the merchant's
/// panel, so the merchant closes it and raises their own processing dialog; the SDK's own processing
/// screen then covers it. Paying with a saved card is the SDK's from the tap onwards — it may need a
/// security code first — so the demo raises nothing and lets the SDK's screens run.
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
        AccountFundingFlow(configuration: configuration)
    }
}

// MARK: - Flow

@available(iOS 15.0, *)
private struct AccountFundingFlow: View {
    let configuration: DemoConfiguration

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var step: Step = .amount
    @State private var basket = FundingBasket()
    @State private var isCreatingSession = false
    @State private var error: String?

    /// A stand-in for the balance the merchant's own backend would return.
    private static let demoBalance = 18_360

    private enum Step: Equatable {
        case amount
        case payments(clientToken: String)
    }

    var body: some View {
        ZStack {
            FundingPalette.page.ignoresSafeArea()
            VStack(spacing: 0) {
                FundingBar(title: isOnAmountStep ? "Fund Account" : "Payments", onBack: goBack)
                content
            }
        }
        // The merchant's own bar carries the title and the back arrow, so the demo host's navigation
        // bar would only sit on top of it.
        .navigationBarHidden(true)
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .amount:
            FundingAmountScreen(
                basket: $basket,
                currencyCode: configuration.clientSession?.currencyCode,
                balance: Self.demoBalance,
                isBusy: isCreatingSession,
                // A deep link hands us a ready-made session; its amount is fixed and ours to display,
                // not to change.
                isAmountEditable: configuration.clientSession != nil,
                error: error,
                onProceed: proceed
            )
        case let .payments(clientToken):
            AccountFundingCheckout(clientToken: clientToken, settings: configuration.settings, onFinish: reset)
                .id(clientToken)
        }
    }

    private var isOnAmountStep: Bool { step == .amount }

    private func goBack() {
        if isOnAmountStep { dismiss() } else { step = .amount }
    }

    private func reset() {
        step = .amount
    }

    /// The merchant's own "create the session" step. A deep-linked demo already carries a token and
    /// no session body, so it skips straight through with the amount that token was minted for.
    private func proceed() {
        guard var body = configuration.clientSession else {
            if let token = configuration.clientToken, !token.isEmpty {
                step = .payments(clientToken: token)
            } else {
                error = "No session configuration provided - configure a session in the main settings screen"
            }
            return
        }

        body.order = ClientSessionRequestBody.Order(
            countryCode: body.order?.countryCode,
            lineItems: [
                .init(itemId: "account-deposit", description: "Account deposit", amount: basket.totalDue, quantity: 1)
            ]
        )

        isCreatingSession = true
        error = nil
        Task {
            do {
                let token = try await NetworkingUtils.requestClientSession(
                    body: body,
                    apiVersion: configuration.apiVersion
                )
                step = .payments(clientToken: token)
            } catch {
                self.error = error.localizedDescription
            }
            isCreatingSession = false
        }
    }
}

// MARK: - Checkout

@available(iOS 15.0, *)
private struct AccountFundingCheckout: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var isAddingCard = false
    @State private var status: FundingStatus?

    let onFinish: () -> Void

    init(clientToken: String, settings: PrimerSettings, onFinish: @escaping () -> Void) {
        _session = StateObject(
            wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings.withMerchantResultScreens)
        )
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            PaymentsScreen(
                session: session,
                amount: amount,
                onAddCard: { isAddingCard = true }
            )
            if isAddingCard {
                AddCardPanel(onCancel: { isAddingCard = false }, onConfirm: startCardPayment)
            }
            if let status {
                FundingStatusDialog(status: status, onDismiss: finish)
            }
        }
        .primerCheckoutSession(session) { state in
            switch state {
            case let .success(result): status = .funded(reference: result.paymentId)
            case let .failure(error): status = .failed(error.localizedDescription)
            default: break
            }
        }
    }

    /// The card form lives in the merchant's panel, so closing it and raising the merchant's own
    /// processing dialog is the merchant's job. The SDK only learns about the submit, and its own
    /// processing screen then covers this one.
    private func startCardPayment() {
        isAddingCard = false
        status = .processing
    }

    private func finish() {
        status = nil
        onFinish()
    }

    /// What the SDK will charge, read back from the session the merchant just created.
    private var amount: String {
        guard let clientSession = session.clientSession, let total = clientSession.totalAmount else { return "" }
        return FundingAmount.format(total, currencyCode: clientSession.currencyCode)
    }
}

// MARK: - Payments screen

@available(iOS 15.0, *)
private struct PaymentsScreen: View {
    @ObservedObject var session: PrimerCheckoutSession
    let amount: String
    let onAddCard: () -> Void

    @State private var isExpanded = false
    /// Which saved card is highlighted. The merchant owns this, the same way they own the list.
    @State private var selectedCardId: String?

    var body: some View {
        VStack(spacing: 0) {
            content
            if let selection = session.selection {
                FundingBottomBar {
                    FundBar(selection: selection, amount: amount, card: card(in: selection))
                }
            }
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
                        SavedCards(
                            selection: selection,
                            isExpanded: $isExpanded,
                            selectedCardId: $selectedCardId
                        )
                    }
                    AddMethods(onAddCard: onAddCard)
                }
                .padding(16)
            }
        }
    }

    /// The highlighted card, falling back to the first one so the pay bar works before any tap.
    private func card(in selection: PrimerSelectionSession) -> PrimerVaultedPaymentMethods.VaultedMethod? {
        let methods = selection.vaultedPaymentMethods
        return methods.first { $0.id == selectedCardId } ?? methods.first
    }
}

@available(iOS 15.0, *)
private struct FundBar: View {
    /// Observed, not just read: the button shows a spinner while the payment runs.
    @ObservedObject var selection: PrimerSelectionSession
    let amount: String
    let card: PrimerVaultedPaymentMethods.VaultedMethod?

    /// The merchant's own button pays directly. No SDK component is mounted here, and nothing is
    /// raised over the SDK: `selectVaulted` may need a security code first, and its own screens
    /// carry the payment from here to the result.
    var body: some View {
        let isLoading = selection.state.isVaultPaymentLoading
        FundingPayButton(amount: amount, isLoading: isLoading, isEnabled: card != nil && !isLoading) {
            if let card { selection.selectVaulted(card) }
        }
    }
}

@available(iOS 15.0, *)
private struct SavedCards: View {
    @ObservedObject var selection: PrimerSelectionSession
    @Binding var isExpanded: Bool
    @Binding var selectedCardId: String?

    var body: some View {
        let methods = selection.vaultedPaymentMethods
        if !methods.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Saved payment methods").font(.headline).foregroundColor(FundingPalette.ink)
                VStack(spacing: 0) {
                    ForEach(Array(visible(of: methods).enumerated()), id: \.element.id) { index, method in
                        if index > 0 { Divider().padding(.horizontal, 16) }
                        // Highlights only. `selectVaulted` is the pay verb, so it belongs on the
                        // pay bar, not on a row tap.
                        SavedCardRow(method: method, isSelected: method.id == selected(in: methods)?.id) {
                            selectedCardId = method.id
                        }
                    }
                }
                .fundingCard()

                // One saved card renders the same collapsed or expanded, so the toggle would do
                // nothing visible.
                if methods.count > 1 {
                    Button { withAnimation { isExpanded.toggle() } } label: {
                        Text(isExpanded ? "Collapse" : "View all")
                            .font(.body.weight(.semibold))
                            .foregroundColor(FundingPalette.ink)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(FundingPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(FundingPalette.outline, lineWidth: 2))
                    }
                }
            }
        }
    }

    private func selected(
        in methods: [PrimerVaultedPaymentMethods.VaultedMethod]
    ) -> PrimerVaultedPaymentMethods.VaultedMethod? {
        methods.first { $0.id == selectedCardId } ?? methods.first
    }

    /// Collapsed shows the highlighted card alone, which is what the shopper is about to pay with.
    private func visible(
        of methods: [PrimerVaultedPaymentMethods.VaultedMethod]
    ) -> [PrimerVaultedPaymentMethods.VaultedMethod] {
        guard !isExpanded else { return methods }
        return [selected(in: methods) ?? methods[0]]
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
                // The SDK exposes no artwork for a vaulted card's network, so the merchant draws its
                // own mark from `paymentInstrumentData.network`.
                Text(network.prefix(4).uppercased())
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 22)
                    .background(FundingPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text("\(network.capitalized) **** \(method.paymentInstrumentData.last4Digits ?? "••••")")
                    .foregroundColor(FundingPalette.ink)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(FundingPalette.success))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
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
                    Image(uiImage: icon).resizable().scaledToFit().frame(maxHeight: 24)
                } else {
                    Text(method.buttonText ?? method.name)
                }
            }
            .font(.body.weight(.semibold))
            .foregroundColor(isCard ? .white : Color(method.textColor ?? .black))
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(isCard ? FundingPalette.card : Color(method.backgroundColor ?? .systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
            VStack(spacing: 20) {
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
                    // Half width, matching the expiry field above it, as the merchant's sheet has it.
                    billingAddress: { form in
                        HStack(spacing: 12) {
                            CardFormDefaults.postalCode(form)
                            Color.clear
                        }
                    },
                    submitButton: { buttons(for: $0) }
                )
            }
            .padding(20)
            .background(FundingPalette.surface)
            .clipShape(FundingSheetShape())
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func buttons(for form: PrimerCardFormSession) -> some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("Cancel").fontWeight(.semibold).foregroundColor(FundingPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(FundingPalette.outline, lineWidth: 2))
            }
            // Submit first: confirming tears this panel down, and the payment must already be under way.
            Button {
                form.submit()
                onConfirm()
            } label: {
                Text("Confirm").fontWeight(.semibold).foregroundColor(FundingPalette.ink)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(FundingPalette.cta.opacity(form.state.isValid ? 1 : 0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!form.state.isValid || form.state.isLoading)
        }
    }
}
