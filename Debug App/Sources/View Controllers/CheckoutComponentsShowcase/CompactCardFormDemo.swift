//
//  CompactCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Compact layout demo with horizontal card fields
@available(iOS 15.0, *)
struct CompactCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings

    var body: some View {
        PrimerCheckout(
            clientToken: clientToken,
            settings: settings,
            scope: { checkoutScope in
                // Configure card form scope for compact layout
                checkoutScope.setPaymentMethodScreen((any PrimerCardFormScope).self) { (scope: any PrimerCardFormScope) in
                    AnyView(
                        VStack(spacing: 8) {
                            // Card number row
                            HStack(spacing: 8) {
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(40)
                                    .padding(.horizontal, 8)
                                    .background(.white)
                                    .cornerRadius(6)
                                    .border(.gray.opacity(0.3), width: 1)
                                )
                            }

                            // Expiry and CVV row
                            HStack(spacing: 8) {
                                scope.expiryDateInput?(PrimerModifier()
                                    .width(120)
                                    .height(40)
                                    .padding(.horizontal, 8)
                                    .background(.white)
                                    .cornerRadius(6)
                                    .border(.gray.opacity(0.3), width: 1)
                                )

                                scope.cvvInput?(PrimerModifier()
                                    .width(80)
                                    .height(40)
                                    .padding(.horizontal, 8)
                                    .background(.white)
                                    .cornerRadius(6)
                                    .border(.gray.opacity(0.3), width: 1)
                                )
                            }

                            // Cardholder name
                            scope.cardholderNameInput?(PrimerModifier()
                                .fillMaxWidth()
                                .height(40)
                                .padding(.horizontal, 8)
                                .background(.white)
                                .cornerRadius(6)
                                .border(.gray.opacity(0.3), width: 1)
                            )
                        }
                        .padding()
                    )
                }
            }
        )
        .frame(height: 200)
    }
}
