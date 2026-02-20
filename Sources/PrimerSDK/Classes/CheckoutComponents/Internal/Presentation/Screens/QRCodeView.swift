//
//  QRCodeView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct QRCodeView: View, LogReporter {
  let scope: any PrimerQRCodeScope

  @Environment(\.designTokens) private var tokens
  @State private var qrCodeState = QRCodeState()

  private enum Layout {
    static let amountFontSize: CGFloat = 34
    static let titleFontSize: CGFloat = 20
    static let subtitleFontSize: CGFloat = 15
    static let iconSize: CGFloat = 48
    static let qrCodeSize: CGFloat = 270
    static let qrCodePadding: CGFloat = 10
  }

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      makeHeaderSection()
      makeContentSection()
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .padding(PrimerSpacing.large(tokens: tokens))
    .frame(maxWidth: .infinity)
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .onAppear(perform: observeState)
  }

  // MARK: - Header Section

  private func makeHeaderSection() -> some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      HStack {
        if scope.presentationContext.shouldShowBackButton {
          Button(
            action: scope.onBack,
            label: {
              HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                Image(systemName: RTLIcon.backChevron)
                  .font(PrimerFont.bodyMedium(tokens: tokens))
                Text("Back")
              }
              .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            }
          )
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          Button("Cancel", action: scope.onCancel)
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        }
      }
    }
  }

  // MARK: - Content Section

  private func makeContentSection() -> some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      switch qrCodeState.status {
      case .loading:
        Spacer()
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(PrimerScale.large)
        Spacer()

      case .displaying:
        ScrollView {
          VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            makeAmountLabel()
            makeTitleSection()
            makeQRCodeImage()
          }
        }

      case .success:
        Spacer()
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: Layout.iconSize))
          .foregroundColor(.green)
        Spacer()

      case .failure:
        Spacer()
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: Layout.iconSize))
          .foregroundColor(.red)
        Spacer()
      }
    }
  }

  private func makeAmountLabel() -> some View {
    Group {
      if let amount = AppState.current.amount,
        let currency = AppState.current.currency
      {
        Text(amount.toCurrencyString(currency: currency))
          .font(.system(size: Layout.amountFontSize, weight: .bold))
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private func makeTitleSection() -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
      Text("Scan to pay or take a screenshot")
        .font(.system(size: Layout.titleFontSize))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity, alignment: .leading)

      Text("Upload the screenshot in your banking app")
        .font(.system(size: Layout.subtitleFontSize))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func makeQRCodeImage() -> some View {
    Group {
      if let imageData = qrCodeState.qrCodeImageData, let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .interpolation(.none)
          .aspectRatio(contentMode: .fit)
          .frame(width: Layout.qrCodeSize, height: Layout.qrCodeSize)
          .padding(Layout.qrCodePadding)
          .overlay(
            RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
              .stroke(Color.gray.opacity(0.5), lineWidth: PrimerBorderWidth.standard)
          )
          .frame(maxWidth: .infinity)
      }
    }
  }

  // MARK: - State Observation

  private func observeState() {
    Task {
      for await state in scope.state {
        await MainActor.run {
          qrCodeState = state
        }
      }
    }
  }
}
