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
                    // Use new generic payment method screen API
                    checkoutScope.setPaymentMethodScreen((any PrimerCardFormScope).self) { (scope: any PrimerCardFormScope) in
                        AnyView(
                            VStack(spacing: 12) {
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(44)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .border(.gray.opacity(0.2), width: 1)
                                )
                                
                                HStack(spacing: 12) {
                                    scope.expiryDateInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(44)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(8)
                                        .border(.gray.opacity(0.2), width: 1)
                                    )
                                    
                                    scope.cvvInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(44)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(8)
                                        .border(.gray.opacity(0.2), width: 1)
                                    )
                                }
                                
                                scope.cardholderNameInput?(PrimerModifier()
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
