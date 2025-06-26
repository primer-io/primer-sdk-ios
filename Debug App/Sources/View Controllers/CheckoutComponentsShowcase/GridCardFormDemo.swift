//
//  GridCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Grid layout demo with card details in organized grid
@available(iOS 15.0, *)
struct GridCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        PrimerCheckout(
            clientToken: clientToken,
            settings: settings,
            scope: { checkoutScope in
                checkoutScope.setPaymentMethodScreen((any PrimerCardFormScope).self) { (scope: any PrimerCardFormScope) in
                    AnyView(
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                // Card number spans full width
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(48)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(10)
                                    .border(.purple.opacity(0.3), width: 2)
                                )
                                
                                // Empty cell to complete the row
                                Color.clear
                                    .frame(height: 0)
                                
                                // Expiry date
                                scope.expiryDateInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(48)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(10)
                                    .border(.purple.opacity(0.3), width: 2)
                                )
                                
                                // CVV
                                scope.cvvInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(48)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(10)
                                    .border(.purple.opacity(0.3), width: 2)
                                )
                                
                                // Cardholder name spans full width
                                scope.cardholderNameInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(48)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(10)
                                    .border(.purple.opacity(0.3), width: 2)
                                )
                                
                                // Empty cell to complete the row
                                Color.clear
                                    .frame(height: 0)
                        }
                        .padding()
                    )
                }
            }
        )
        .frame(height: 200)
    }
}
