//
//  PrimerResultFailedView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

struct PrimerResultFailedView: View {
    var errorTitle: String
    var errorMessage: String
    var onRetry: (() -> Void)? = nil
    var onChooseOtherMethod: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Pay with ACH")
                    .font(.system(size: 20, weight: .medium))
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
                Spacer()
            }
            .padding(.init(top: -5, leading: 0, bottom: 40, trailing: 0))
            
            Image(systemName: "xmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.red.opacity(0.8))
                .padding(.bottom, 15)
            
            Text(errorTitle)
                .font(.system(size: 17))
                .padding(.bottom, 3)
            
            Text(errorMessage)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, 40)
            
            if let onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(8)
                }
            }
            
            Button(action: onChooseOtherMethod) {
                Text("Choose another payment method")
                    .font(.system(size: 17))
                    .foregroundColor(onRetry != nil ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(onRetry != nil ? Color.clear : .black)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}
