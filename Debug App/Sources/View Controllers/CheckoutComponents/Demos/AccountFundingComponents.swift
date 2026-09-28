//
//  AccountFundingComponents.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

// The fictional merchant's own UI for AccountFundingDemo. None of it touches Primer.

// MARK: - Basket

/// What the shopper deposits and what they pay. `totalDue` is what the client session is created with.
struct FundingBasket: Equatable {
    var deposit = 2500
    var isPromotionApplied = false
    var giftCardCode: String?

    static let availablePromotions = 1
    static let promotionName = "Deposit bonus"
    static let promotionDetail = "10% off any deposit"
    static let giftCardCredit = 500
    private static let minimumCharge = 100

    var promotionDiscount: Int { isPromotionApplied ? deposit / 10 : 0 }

    var giftCardDiscount: Int {
        guard giftCardCode?.isEmpty == false else { return 0 }
        return min(Self.giftCardCredit, max(0, deposit - promotionDiscount - Self.minimumCharge))
    }

    /// Never below the minimum, because a client session for nothing is not a payment.
    var totalDue: Int { max(Self.minimumCharge, deposit - promotionDiscount - giftCardDiscount) }

    var hasDiscount: Bool { totalDue != deposit }
}

// MARK: - Result dialogs

enum FundingStatus: Equatable {
    case processing
    case funded(reference: String)
    case failed(String)
}

@available(iOS 15.0, *)
struct FundingStatusDialog: View {
    let status: FundingStatus
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: status == .processing ? .center : .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
            switch status {
            case .processing:
                processing
            case let .funded(reference):
                result(
                    title: "Deposit successful!",
                    headline: "Good luck!",
                    detail: "Your account has been funded.",
                    reference: reference,
                    isSuccess: true
                )
            case let .failed(message):
                result(title: "Deposit failed", headline: "Nothing was charged", detail: message, isSuccess: false)
            }
        }
    }

    private var processing: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large).tint(FundingPalette.success)
            Text("One moment please.")
            Text("Don't close app, adding funds in progress...")
                .multilineTextAlignment(.center)
        }
        .font(.subheadline)
        .foregroundColor(FundingPalette.mutedInk)
        .padding(28)
        .frame(maxWidth: .infinity)
        .fundingCard(radius: 16)
        .padding(.horizontal, 36)
    }

    private func result(
        title: String,
        headline: String,
        detail: String,
        reference: String? = nil,
        isSuccess: Bool
    ) -> some View {
        VStack(spacing: 22) {
            Text(title).font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
            Image(systemName: isSuccess ? "checkmark" : "xmark")
                .font(.system(size: 62, weight: .bold)).foregroundColor(.white)
                .frame(width: 150, height: 150)
                .background(Circle().fill(isSuccess ? FundingPalette.success : Color.red))
                .padding(.vertical, 8)
            Text(headline).font(.title2.weight(.bold))
            Text(detail).font(.body).foregroundColor(FundingPalette.mutedInk).multilineTextAlignment(.center)
            // The payment id Primer returns, so the dialog proves a real payment was created.
            if let reference {
                Text("Payment \(reference)").font(.caption).foregroundColor(FundingPalette.mutedInk)
            }
            FundingCtaButton(title: isSuccess ? "All done" : "Close", action: onDismiss).padding(.top, 8)
        }
        .foregroundColor(FundingPalette.ink)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(FundingPalette.surface)
        .clipShape(FundingSheetShape())
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Chrome

/// The merchant's own navigation bar.
@available(iOS 15.0, *)
struct FundingBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.headline)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left").font(.body.weight(.semibold))
                }
                Spacer()
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(FundingPalette.bar.ignoresSafeArea(edges: .top))
    }
}

@available(iOS 15.0, *)
struct FundingBalanceHeader: View {
    let balance: Int
    let currencyCode: String?

    private let networks = ["VISA", "MC", "DISC", "PP"]

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(FundingAmount.format(balance, currencyCode: currencyCode))
                    .font(.title.weight(.bold))
                Text("Current balance").font(.subheadline).foregroundColor(FundingPalette.mutedInk)
            }
            Spacer()
            // Names rather than brand marks, because the marks are licensed.
            HStack(spacing: 4) {
                ForEach(networks, id: \.self) { network in
                    Text(network)
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(FundingPalette.mutedInk)
                        .frame(width: 30, height: 20)
                        .background(FundingPalette.page)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.top, 4)
        }
        .foregroundColor(FundingPalette.ink)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(FundingPalette.surface)
    }
}

/// The pinned bar at the foot of every merchant screen.
@available(iOS 15.0, *)
struct FundingBottomBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(FundingPalette.surface)
            .clipShape(FundingSheetShape())
            .shadow(color: .black.opacity(0.08), radius: 10, y: -2)
    }
}

@available(iOS 15.0, *)
struct FundingSummaryRow: View {
    let label: String
    let value: String
    var isBold = false

    var body: some View {
        HStack {
            Text(label).fontWeight(isBold ? .semibold : .regular)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .foregroundColor(FundingPalette.ink)
        .padding(16)
    }
}

@available(iOS 15.0, *)
struct FundingCtaButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.body.weight(.semibold)).foregroundColor(FundingPalette.ink)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(FundingPalette.cta.opacity(isEnabled ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
    }
}

/// The pay bar, with the label on the left and the amount on the right.
@available(iOS 15.0, *)
struct FundingPayButton: View {
    let amount: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if isLoading {
                    ProgressView().tint(FundingPalette.ink)
                } else {
                    Text("Fund account").font(.body.weight(.semibold))
                    Rectangle().fill(FundingPalette.ink.opacity(0.5)).frame(width: 2, height: 22)
                    Text(amount)
                }
            }
            .foregroundColor(FundingPalette.ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(FundingPalette.cta.opacity(isEnabled && !isLoading ? 1 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled || isLoading)
    }
}

/// Two labelled groups of placeholder blocks, matching the shape of the list that replaces them.
@available(iOS 15.0, *)
struct FundingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            group(rows: 1)
            group(rows: 3).padding(.top, 14)
            Spacer()
        }
        .padding(16)
    }

    private func group(rows: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            block(width: 180, height: 20)
            ForEach(0 ..< rows, id: \.self) { _ in block(width: nil, height: 56) }
        }
    }

    private func block(width: CGFloat?, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.black.opacity(0.06))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: .leading)
    }
}

// MARK: - Helpers

/// Rounded top corners with a square bottom, which `RoundedRectangle` alone cannot do.
struct FundingSheetShape: Shape {
    var radius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
        )
    }
}

extension View {
    /// The merchant's card surface.
    @available(iOS 15.0, *)
    func fundingCard(radius: CGFloat = 12) -> some View {
        background(FundingPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// A made-up brand. Fixed values on purpose, so it looks the same in both colour schemes.
enum FundingPalette {
    static let bar = Color(hex: 0x041E17)
    static let page = Color(hex: 0xE8F0F5)
    static let surface = Color.white
    static let ink = Color(hex: 0x0B1B14)
    static let mutedInk = Color(hex: 0x6B7B75)
    static let cta = Color(hex: 0x62E273)
    static let outline = Color(hex: 0x65DA76)
    static let selected = Color(hex: 0x30AD4F)
    static let success = Color(hex: 0x4FD723)
    static let accent = Color(hex: 0x7E44FF)
    static let card = Color(hex: 0x655FEB)
}

enum FundingAmount {
    /// Minor units to a display string. A `nil` currency falls back to the device locale.
    static func format(_ minorUnits: Int, currencyCode: String?) -> String {
        formatter(for: currencyCode, fractionDigits: 2)
            .string(from: NSNumber(value: Double(minorUnits) / 100)) ?? "\(minorUnits)"
    }

    /// Same, with the cents dropped, for the preset amounts.
    static func formatWhole(_ minorUnits: Int, currencyCode: String?) -> String {
        formatter(for: currencyCode, fractionDigits: 0)
            .string(from: NSNumber(value: Double(minorUnits) / 100)) ?? "\(minorUnits / 100)"
    }

    static func symbol(for currencyCode: String?) -> String {
        formatter(for: currencyCode, fractionDigits: 0).currencySymbol ?? ""
    }

    private static func formatter(for currencyCode: String?, fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        if let currencyCode { formatter.currencyCode = currencyCode }
        return formatter
    }
}

extension PrimerSettings {
    /// The merchant draws its own result dialogs, so the SDK screens are switched off.
    var withMerchantResultScreens: PrimerSettings {
        PrimerSettings(
            paymentHandling: paymentHandling,
            localeData: localeData,
            paymentMethodOptions: paymentMethodOptions,
            uiOptions: PrimerUIOptions(
                isInitScreenEnabled: false,
                isSuccessScreenEnabled: false,
                isErrorScreenEnabled: false,
                dismissalMechanism: uiOptions.dismissalMechanism,
                cardFormUIOptions: uiOptions.cardFormUIOptions,
                appearanceMode: uiOptions.appearanceMode,
                theme: uiOptions.theme
            ),
            debugOptions: debugOptions,
            clientSessionCachingEnabled: clientSessionCachingEnabled,
            apiVersion: apiVersion
        )
    }
}
