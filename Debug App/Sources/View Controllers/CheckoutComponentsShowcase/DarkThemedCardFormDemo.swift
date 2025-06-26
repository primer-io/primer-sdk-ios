//
//  DarkThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Dark theme demo with full dark mode implementation
@available(iOS 15.0, *)
struct DarkThemedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        PrimerCheckout(
            clientToken: clientToken,
            settings: settings,
            scope: { checkoutScope in
                checkoutScope.setPaymentMethodScreen((any PrimerCardFormScope).self) { (scope: any PrimerCardFormScope) in
                    AnyView(
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Payment Information")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("Secure checkout powered by Primer")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(50)
                                    .padding(.horizontal, 16)
                                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                    .cornerRadius(10)
                                    .border(Color(red: 0.3, green: 0.3, blue: 0.3), width: 1)
                                    .foregroundColor(.white)
                                )
                                
                                HStack(spacing: 12) {
                                    scope.expiryDateInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(50)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .cornerRadius(10)
                                        .border(Color(red: 0.3, green: 0.3, blue: 0.3), width: 1)
                                        .foregroundColor(.white)
                                    )
                                    
                                    scope.cvvInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(50)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .cornerRadius(10)
                                        .border(Color(red: 0.3, green: 0.3, blue: 0.3), width: 1)
                                        .foregroundColor(.white)
                                    )
                                }
                                
                                scope.cardholderNameInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(50)
                                    .padding(.horizontal, 16)
                                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                    .cornerRadius(10)
                                    .border(Color(red: 0.3, green: 0.3, blue: 0.3), width: 1)
                                    .foregroundColor(.white)
                                )
                            }
                        .padding()
                        .background(Color.black)
                    )
                }
            }
        )
        .frame(height: 240)
    }
}
