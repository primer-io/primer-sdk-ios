//
//  AccountFundingAmountScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// The merchant's own deposit screen, ahead of any Primer code. It decides the amount.
@available(iOS 15.0, *)
struct FundingAmountScreen: View {
    @Binding var basket: FundingBasket
    let currencyCode: String?
    let balance: Int
    let isBusy: Bool
    let isAmountEditable: Bool
    let error: String?
    let onProceed: () -> Void

    @State private var amountText = ""
    @State private var panel: Panel?
    @State private var giftCardEntry = ""
    @FocusState private var isAmountFocused: Bool

    private let presets = [2500, 5000, 10_000]

    private enum Panel: Identifiable {
        case promotions, giftCard
        var id: Int { self == .promotions ? 0 : 1 }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        FundingBalanceHeader(balance: balance, currencyCode: currencyCode)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fund amount").font(.headline)
                            amountField
                            chips
                            promotionsRow
                            Text("Funding summary").font(.headline).padding(.top, 8)
                            summary
                            giftCardRow
                            if let error {
                                Text(error).font(.footnote).foregroundColor(.red)
                            }
                        }
                        .foregroundColor(FundingPalette.ink)
                        .padding(16)
                    }
                }
                FundingBottomBar {
                    FundingCtaButton(title: "Proceed to payments", isEnabled: !isBusy, action: onProceed)
                }
            }
            if isBusy { busyOverlay }
            if let panel { panelView(panel) }
        }
        .background(FundingPalette.page)
        .onAppear { amountText = String(basket.deposit / 100) }
    }

    // MARK: Amount

    private var amountField: some View {
        HStack(spacing: 2) {
            Text(FundingAmount.symbol(for: currencyCode))
            TextField("0", text: $amountText)
                .keyboardType(.numberPad)
                .focused($isAmountFocused)
                .disabled(!isAmountEditable)
                .onChange(of: amountText) { newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                    if digits != newValue { amountText = digits }
                    basket.deposit = (Int(digits) ?? 0) * 100
                }
        }
        .foregroundColor(FundingPalette.mutedInk)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fundingCard(radius: 10)
    }

    private var chips: some View {
        HStack(spacing: 10) {
            ForEach(presets, id: \.self) { value in
                chip(label: FundingAmount.formatWhole(value, currencyCode: currencyCode),
                     isOn: basket.deposit == value && !isAmountFocused) {
                    amountText = String(value / 100)
                    isAmountFocused = false
                }
            }
            // "Other" hands focus to the free-entry field that is already on screen.
            chip(label: "Other", isOn: isAmountFocused) {
                amountText = ""
                isAmountFocused = true
            }
        }
        .disabled(!isAmountEditable)
    }

    private func chip(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isOn ? .white : FundingPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isOn ? FundingPalette.accent : FundingPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(FundingPalette.accent, lineWidth: isOn ? 0 : 2)
                )
        }
    }

    // MARK: Promotions, summary, gift card

    private var promotionsRow: some View {
        Button { panel = .promotions } label: {
            HStack(spacing: 12) {
                Image(systemName: "gift").foregroundColor(FundingPalette.accent)
                Text("Promotions").foregroundColor(FundingPalette.ink)
                Spacer()
                Text(basket.isPromotionApplied ? "1 applied" : "\(FundingBasket.availablePromotions)")
                    .foregroundColor(FundingPalette.mutedInk)
                Image(systemName: "chevron.right").foregroundColor(FundingPalette.mutedInk)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .fundingCard(radius: 10)
        }
        .buttonStyle(.plain)
    }

    private var summary: some View {
        VStack(spacing: 0) {
            FundingSummaryRow(
                label: "Deposit amount",
                value: FundingAmount.format(basket.deposit, currencyCode: currencyCode)
            )
            if basket.promotionDiscount > 0 {
                Divider().padding(.horizontal, 16)
                FundingSummaryRow(
                    label: FundingBasket.promotionName,
                    value: "-" + FundingAmount.format(basket.promotionDiscount, currencyCode: currencyCode)
                )
            }
            if basket.giftCardDiscount > 0 {
                Divider().padding(.horizontal, 16)
                FundingSummaryRow(
                    label: "Gift card",
                    value: "-" + FundingAmount.format(basket.giftCardDiscount, currencyCode: currencyCode)
                )
            }
            Divider().padding(.horizontal, 16)
            FundingSummaryRow(
                label: "Total due",
                value: FundingAmount.format(basket.totalDue, currencyCode: currencyCode),
                isBold: true
            )
        }
        .fundingCard()
    }

    @ViewBuilder private var giftCardRow: some View {
        if let code = basket.giftCardCode, !code.isEmpty {
            HStack(spacing: 8) {
                Text("Gift card \(code) applied").font(.footnote).foregroundColor(FundingPalette.mutedInk)
                Button("Remove") { basket.giftCardCode = nil }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(FundingPalette.accent)
            }
        } else {
            Button { panel = .giftCard } label: {
                Text("Have a gift card?")
                    .font(.footnote)
                    .foregroundColor(FundingPalette.accent)
                    .overlay(FundingPalette.accent.frame(height: 1), alignment: .bottom)
            }
        }
    }

    // MARK: Panels

    private var busyOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(FundingPalette.success)
                Text("Loading...").font(.subheadline).foregroundColor(FundingPalette.mutedInk)
            }
            .padding(36)
            .fundingCard(radius: 16)
        }
    }

    @ViewBuilder
    private func panelView(_ panel: Panel) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { self.panel = nil }
            switch panel {
            case .promotions: promotionsPanel
            case .giftCard: giftCardPanel
            }
        }
    }

    // Both panels exist to change `totalDue`, which is what the client session is created with.
    private var promotionsPanel: some View {
        panelBody(title: "Promotions") {
            Toggle(isOn: $basket.isPromotionApplied) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FundingBasket.promotionName).font(.body.weight(.semibold))
                    Text(FundingBasket.promotionDetail).font(.footnote).foregroundColor(FundingPalette.mutedInk)
                }
            }
            .tint(FundingPalette.selected)
            .padding(16)
            .fundingCard(radius: 10)
        }
    }

    private var giftCardPanel: some View {
        panelBody(title: "Gift card") {
            TextField("Enter your code", text: $giftCardEntry)
                .autocorrectionDisabled()
                .padding(16)
                .fundingCard(radius: 10)
            FundingCtaButton(title: "Apply", isEnabled: !giftCardEntry.isEmpty) {
                basket.giftCardCode = giftCardEntry
                giftCardEntry = ""
                panel = nil
            }
        }
    }

    private func panelBody(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("Done") { panel = nil }.font(.body.weight(.semibold))
                    .foregroundColor(FundingPalette.accent)
            }
            content()
        }
        .foregroundColor(FundingPalette.ink)
        .padding(20)
        .background(FundingPalette.surface)
        .clipShape(FundingSheetShape())
        .ignoresSafeArea(edges: .bottom)
    }
}
