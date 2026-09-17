//
//  AccountFundingComponents.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

// Brand chrome and result dialogs for AccountFundingDemo. None of it touches Primer: it is the
// fictional merchant's UI, kept next to the demo so the flow file stays about the SDK.

// MARK: - Result dialogs

enum FundingStatus: Equatable {
    case processing
    case funded
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
            case .funded:
                result(
                    title: "Deposit successful!",
                    headline: "Good luck!",
                    detail: "Your account has been funded.",
                    isSuccess: true
                )
            case let .failed(message):
                result(title: "Deposit failed", headline: "Nothing was charged", detail: message, isSuccess: false)
            }
        }
    }

    private var processing: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large).tint(FundingPalette.ink)
            Text("One moment please.").font(.subheadline)
            Text("Don't close app, adding funds in progress…")
                .font(.subheadline).multilineTextAlignment(.center)
        }
        .foregroundColor(FundingPalette.ink)
        .padding(24)
        .frame(width: 280)
        .background(FundingPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func result(title: String, headline: String, detail: String, isSuccess: Bool) -> some View {
        VStack(spacing: 18) {
            Text(title).font(.title.weight(.bold)).multilineTextAlignment(.center)
            Image(systemName: isSuccess ? "checkmark" : "xmark")
                .font(.system(size: 44, weight: .bold)).foregroundColor(.white)
                .frame(width: 104, height: 104)
                .background(Circle().fill(isSuccess ? FundingPalette.success : Color.red))
            Text(headline).font(.title3.weight(.bold))
            Text(detail).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            FundingCtaButton(title: "All done", action: onDismiss)
        }
        .foregroundColor(FundingPalette.ink)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(FundingPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Chrome

@available(iOS 15.0, *)
struct FundingBar: View {
    let title: String
    let onBack: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.headline)
            HStack {
                if let onBack {
                    Button(action: onBack) { Image(systemName: "arrow.left") }
                }
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark") }
            }
            .font(.body.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(FundingPalette.bar)
    }
}

@available(iOS 15.0, *)
struct FundingBottomBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(FundingPalette.surface)
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
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(FundingPalette.cta.opacity(isEnabled ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isEnabled)
    }
}

/// The pay bar: label on the left, amount on the right, the shape a wallet app usually gives it.
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
                    Rectangle().fill(FundingPalette.ink.opacity(0.35)).frame(width: 1, height: 20)
                    Text(amount)
                }
            }
            .foregroundColor(FundingPalette.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(FundingPalette.cta.opacity(isEnabled && !isLoading ? 1 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isEnabled || isLoading)
    }
}

@available(iOS 15.0, *)
struct FundingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([120, 56, 56, 56], id: \.self) { height in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.06))
                    .frame(height: CGFloat(height))
            }
            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Helpers

/// A made-up brand, so the demo reads as somebody's product rather than ours. Fixed values on
/// purpose: this brand has one appearance in both colour schemes.
enum FundingPalette {
    static let bar = Color(hex: 0x041E17)
    static let page = Color(hex: 0xE8F0F5)
    static let surface = Color.white
    static let ink = Color(hex: 0x0B1B14)
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let currencyCode { formatter.currencyCode = currencyCode }
        return formatter.string(from: NSNumber(value: Double(minorUnits) / 100)) ?? "\(minorUnits)"
    }
}

extension PrimerSettings {
    /// The merchant draws its own success and failure dialogs, so the SDK screens are switched off.
    /// There is no matching switch for the processing screen.
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
