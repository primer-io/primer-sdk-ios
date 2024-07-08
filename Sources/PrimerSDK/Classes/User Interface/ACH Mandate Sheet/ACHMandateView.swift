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
                .font(.system(size: 20, weight: .medium))
                .padding(.horizontal)
            
            Text(viewModel.mandateText)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    onAcceptPressed()
                }) {
                    Text("Accept")
                        .font(.system(size: 17))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    onCancelPressed()
                }) {
                    Text("Cancel payment")
                        .font(.system(size: 17))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
}
