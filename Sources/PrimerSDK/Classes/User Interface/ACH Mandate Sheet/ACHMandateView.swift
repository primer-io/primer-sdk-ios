//
//  ACHMandateView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI
import UIKit

struct ACHMandateView: View {
    @ObservedObject var viewModel: ACHMandateViewModel

    var onAcceptPressed: () -> Void
    var onCancelPressed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(format: Strings.ResultView.paymentTitle, "ACH"))
                .font(.system(size: 20))
                .padding(.horizontal)

            Text(viewModel.mandateText)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                Button {
                    onAcceptPressed()
                    viewModel.shouldDisableViews = true
                } label: {
                    ZStack {
                        if viewModel.shouldDisableViews {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium, color: UIColor.white)
                        } else {
                            Text(Strings.Mandate.acceptButton)
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                }
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.acceptMandateButton.rawValue)

                Button {
                    onCancelPressed()
                    viewModel.shouldDisableViews = true
                } label: {
                    Text(Strings.Mandate.cancelButton)
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.declineMandateButton.rawValue)
            }
            .disabled(viewModel.shouldDisableViews)
            .padding([.horizontal, .bottom])
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    var style: UIActivityIndicatorView.Style
    var color: UIColor

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let activity = UIActivityIndicatorView(style: style)
        activity.color = color
        return activity
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
