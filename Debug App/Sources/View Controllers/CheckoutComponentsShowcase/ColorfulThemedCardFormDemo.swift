//
//  ColorfulThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Colorful theme demo with branded colors and gradients
@available(iOS 15.0, *)
struct ColorfulThemedCardFormDemo: View {
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
                            scope.cardNumberInput?(PrimerModifier()
                                .fillMaxWidth()
                                .height(52)
                                .padding(.horizontal, 16)
                                .background(.white)
                                .cornerRadius(12)
                                .border(.pink.opacity(0.6), width: 2)
                                .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                            
                            HStack(spacing: 12) {
                                scope.expiryDateInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(52)
                                    .padding(.horizontal, 16)
                                    .background(.white)
                                    .cornerRadius(12)
                                    .border(.orange.opacity(0.6), width: 2)
                                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                                
                                scope.cvvInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(52)
                                    .padding(.horizontal, 16)
                                    .background(.white)
                                    .cornerRadius(12)
                                    .border(.purple.opacity(0.6), width: 2)
                                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                            }
                            
                            scope.cardholderNameInput?(PrimerModifier()
                                .fillMaxWidth()
                                .height(52)
                                .padding(.horizontal, 16)
                                .background(.white)
                                .cornerRadius(12)
                                .border(.blue.opacity(0.6), width: 2)
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.pink.opacity(0.1), .orange.opacity(0.1), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
            }
        )
        .frame(height: 220)
    }
}
