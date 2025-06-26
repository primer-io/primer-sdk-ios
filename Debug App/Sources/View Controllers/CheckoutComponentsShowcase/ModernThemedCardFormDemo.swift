//
//  ModernThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Modern theme demo with clean white and subtle shadows
@available(iOS 15.0, *)
struct ModernThemedCardFormDemo: View {
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
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(56)
                                    .padding(.horizontal, 20)
                                    .background(.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    .border(.clear, width: 0)
                                )
                                
                                HStack(spacing: 16) {
                                    scope.expiryDateInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(56)
                                        .padding(.horizontal, 20)
                                        .background(.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                        .border(.clear, width: 0)
                                    )
                                    
                                    scope.cvvInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(56)
                                        .padding(.horizontal, 20)
                                        .background(.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                        .border(.clear, width: 0)
                                    )
                                }
                                
                                scope.cardholderNameInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(56)
                                    .padding(.horizontal, 20)
                                    .background(.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    .border(.clear, width: 0)
                                )
                            }
                            .padding()
                            .background(Color(red: 0.97, green: 0.97, blue: 0.98))
                        )
                    }
                }
            }
        )
        .frame(height: 240)
    }
}