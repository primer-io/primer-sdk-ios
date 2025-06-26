//
//  ExpandedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Expanded layout demo with vertical fields and generous spacing
@available(iOS 15.0, *)
struct ExpandedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        PrimerCheckout(
            clientToken: clientToken,
            settings: settings,
            scope: { checkoutScope in
                if let cardFormScope = checkoutScope.cardForm {
                    cardFormScope.screen = { scope in
                        AnyView(
                            VStack(spacing: 20) {
                                // Card number with large input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Card Number")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    scope.cardNumberInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(56)
                                        .padding(.horizontal, 16)
                                        .background(.white)
                                        .cornerRadius(12)
                                        .border(.blue, width: 2)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                }
                                
                                // Expiry and CVV with labels
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Expiry Date")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        scope.expiryDateInput?(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(56)
                                            .padding(.horizontal, 16)
                                            .background(.white)
                                            .cornerRadius(12)
                                            .border(.blue, width: 2)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("CVV")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        scope.cvvInput?(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(56)
                                            .padding(.horizontal, 16)
                                            .background(.white)
                                            .cornerRadius(12)
                                            .border(.blue, width: 2)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                }
                                
                                // Cardholder name with label
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Cardholder Name")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    scope.cardholderNameInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(56)
                                        .padding(.horizontal, 16)
                                        .background(.white)
                                        .cornerRadius(12)
                                        .border(.blue, width: 2)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                }
                            }
                            .padding()
                        )
                    }
                }
            }
        )
        .frame(height: 300)
    }
}