//
//  InlineCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Inline layout demo seamlessly embedded in content
@available(iOS 15.0, *)
struct InlineCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Payment Information")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    // Use concrete type for generic payment method screen API
                    checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                        guard let cardScope = scope as? any PrimerCardFormScope else {
                            return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                        }
                        return AnyView(
                            VStack(spacing: 12) {
                                cardScope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(44)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .border(.gray.opacity(0.2), width: 1)
                                )
                                
                                HStack(spacing: 12) {
                                    cardScope.expiryDateInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(44)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(8)
                                        .border(.gray.opacity(0.2), width: 1)
                                    )
                                    
                                    cardScope.cvvInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(44)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(8)
                                        .border(.gray.opacity(0.2), width: 1)
                                    )
                                }
                                
                                cardScope.cardholderNameInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(44)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .border(.gray.opacity(0.2), width: 1)
                                )
                            }
                        )
                    }
                }
            )
            .frame(height: 150)
            
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Your payment is secure and encrypted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
