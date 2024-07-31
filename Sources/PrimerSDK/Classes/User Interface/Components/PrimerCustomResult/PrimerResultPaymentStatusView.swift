//
//  PrimerResultPaymentStatusView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

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
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
                Spacer()
            }
            .padding(.init(top: -5, leading: 0, bottom: viewModel.titleBottomSpacing, trailing: 0))

            Image(systemName: viewModel.statusIconString)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(viewModel.statusIconColor)
                .padding(.bottom, 15)

            Text(viewModel.subtitle)
                .font(.system(size: 17))
                .padding(.bottom, 3)

            Text(viewModel.paymentMessage)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, viewModel.paymentMessageBottomSpacing)

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
            }
        }
        .padding(.horizontal)
    }
}
