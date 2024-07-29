//
//  ACHMandateView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

struct ACHMandateView: View {
    @ObservedObject var viewModel: ACHMandateViewModel

    var onAcceptPressed: () -> Void
    var onCancelPressed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pay with ACH")
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
                    Text("Accept")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.shouldDisableViews ? Color.gray.opacity(0.2) : Color.blue)
                        .foregroundColor(viewModel.shouldDisableViews ? Color.gray : Color.white)
                        .cornerRadius(8)
                }

                Button {
                    onCancelPressed()
                    viewModel.shouldDisableViews = true
                } label: {
                    Text("Cancel payment")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.shouldDisableViews)
            .padding([.horizontal, .bottom])
        }
    }
}
