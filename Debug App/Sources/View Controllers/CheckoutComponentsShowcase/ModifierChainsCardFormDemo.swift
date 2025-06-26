//
//  ModifierChainsCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// PrimerModifier chains demo with complex styling combinations
@available(iOS 15.0, *)
struct ModifierChainsCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @State private var selectedStyle: String = "Classic"
    private let styleOptions = ["Classic", "Neon", "Minimal", "Bold"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Style selector
            VStack(alignment: .leading, spacing: 8) {
                Text("PrimerModifier Style Chains")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Style:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Style", selection: $selectedStyle) {
                        ForEach(styleOptions, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // Card form with modifier chains
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    if let cardFormScope = checkoutScope.cardForm {
                        cardFormScope.screen = { scope in
                            AnyView(
                                VStack(spacing: 12) {
                                    scope.cardNumberInput?(getModifierChain(for: selectedStyle))
                                    
                                    HStack(spacing: 12) {
                                        scope.expiryDateInput?(getModifierChain(for: selectedStyle))
                                        scope.cvvInput?(getModifierChain(for: selectedStyle))
                                    }
                                    
                                    scope.cardholderNameInput?(getModifierChain(for: selectedStyle))
                                }
                            )
                        }
                    }
                }
            )
            .frame(height: 140)
            .animation(.easeInOut(duration: 0.5), value: selectedStyle)
        }
    }
    
    private func getModifierChain(for style: String) -> PrimerModifier {
        switch style {
        case "Classic":
            return PrimerModifier()
                .fillMaxWidth()
                .height(44)
                .padding(.horizontal, 12)
                .background(.white)
                .cornerRadius(8)
                .border(.gray.opacity(0.3), width: 1)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
        case "Neon":
            return PrimerModifier()
                .fillMaxWidth()
                .height(48)
                .padding(.horizontal, 16)
                .background(.black)
                .cornerRadius(12)
                .border(.cyan, width: 2)
                .shadow(color: .cyan.opacity(0.5), radius: 8, x: 0, y: 0)
                .foregroundColor(.cyan)
                
        case "Minimal":
            return PrimerModifier()
                .fillMaxWidth()
                .height(40)
                .padding(.horizontal, 8)
                .background(.clear)
                .cornerRadius(0)
                .border(.clear, width: 0)
                .shadow(color: .clear, radius: 0, x: 0, y: 0)
                
        case "Bold":
            return PrimerModifier()
                .fillMaxWidth()
                .height(56)
                .padding(.horizontal, 20)
                .background(.purple)
                .cornerRadius(16)
                .border(.white, width: 3)
                .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 4)
                .foregroundColor(.white)
                
        default:
            return PrimerModifier()
        }
    }
}