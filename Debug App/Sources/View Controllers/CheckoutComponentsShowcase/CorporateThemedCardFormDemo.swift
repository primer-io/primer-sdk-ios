//
//  CorporateThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Corporate theme demo with professional blue and gray styling
@available(iOS 15.0, *)
struct CorporateThemedCardFormDemo: View {
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
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Payment Details")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.7))
                                    
                                    Text("Enter your corporate card information")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(50)
                                    .padding(.horizontal, 16)
                                    .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                    .cornerRadius(8)
                                    .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                    .font(.system(.body, design: .monospaced))
                                )
                                
                                HStack(spacing: 12) {
                                    scope.expiryDateInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(50)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                        .cornerRadius(8)
                                        .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                        .font(.system(.body, design: .monospaced))
                                    )
                                    
                                    scope.cvvInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(50)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                        .cornerRadius(8)
                                        .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                        .font(.system(.body, design: .monospaced))
                                    )
                                }
                                
                                scope.cardholderNameInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(50)
                                    .padding(.horizontal, 16)
                                    .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                    .cornerRadius(8)
                                    .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                    .font(.system(.body, design: .default))
                                )
                            }
                            .padding()
                            .background(Color.white)
                        )
                    }
                }
            }
        )
        .frame(height: 220)
    }
}