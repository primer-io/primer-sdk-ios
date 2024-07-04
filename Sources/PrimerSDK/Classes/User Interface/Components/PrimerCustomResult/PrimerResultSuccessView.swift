//
//  PrimerResultSuccessView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

struct PrimerResultSuccessView: View {
    
    var title: String = "Payment authorized"
    var message: String = "You have now authorised your bank account to be debited. You will be notified via email once the payment has been collected successfully."
    
    var body: some View {
        VStack {
            HStack {
                Text("Pay with ACH")
                    .font(.system(size: 20, weight: .medium))
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
                Spacer()
            }
            .padding(.init(top: -5, leading: 0, bottom: 60, trailing: 0))
            
            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.green.opacity(0.8))
                .padding(.bottom, 15)
            
            Text(title)
                .font(.system(size: 17))
                .padding(.bottom, 3)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, 60)
        }
        .padding()
    }
}

