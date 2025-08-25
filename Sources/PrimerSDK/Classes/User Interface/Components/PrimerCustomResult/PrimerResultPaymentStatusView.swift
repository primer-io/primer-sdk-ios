//
//  PrimerResultPaymentStatusView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

struct PrimerResultPaymentStatusView: View {
    @ObservedObject var viewModel: PrimerResultPaymentStatusViewModel

    var onRetry: () -> Void
    var onChooseOtherPaymentMethod: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text(viewModel.title)
                    .font(.system(size: 20, weight: .medium))
                Spacer()
            }
            .padding(.init(top: -5, leading: 0, bottom: viewModel.titleBottomSpacing, trailing: 0))

            Image(systemName: viewModel.statusIconString)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(viewModel.statusIconColor)
                .padding(.bottom, 15)
                .addAccessibilityIdentifier(identifier: viewModel.statusIconAccessibilityIdentifier)

            Text(viewModel.subtitle)
                .font(.system(size: 17))
                .padding(.bottom, 3)
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.ResultScreen.messageLabel.rawValue)

            Text(viewModel.paymentMessage)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, viewModel.paymentMessageBottomSpacing)
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.ResultScreen.descriptionLabel.rawValue)

            if viewModel.showOnRetry {
                Button(action: onRetry) {
                    Text(Strings.ResultView.retryButton)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.ResultScreen.primaryButton.rawValue)
            }

            if viewModel.showChooseOtherPaymentMethod {
                Button(action: onChooseOtherPaymentMethod) {
                    Text(Strings.ResultView.chooseOtherPM)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(viewModel.showOnRetry ? .blue : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.showOnRetry ? Color.clear : .blue)
                        .cornerRadius(8)
                }
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.ResultScreen.secondaryButton.rawValue)
            }
        }
        .padding(.horizontal)
        .background(PrimerColors.swiftColor(PrimerColors.white))
    }
}
