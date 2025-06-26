//
//  CoBadgedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Co-badged cards demo with multiple network selection
@available(iOS 15.0, *)
struct CoBadgedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @State private var selectedNetwork: String = "None"
    @State private var availableNetworks: [String] = ["Visa", "Mastercard", "American Express"]
    @State private var showNetworkSelection = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Network selection display
            VStack(alignment: .leading, spacing: 8) {
                Text("Co-badged Card Networks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Selected Network:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(selectedNetwork)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedNetwork == "None" ? .red : .green)
                    
                    Spacer()
                    
                    Button("Simulate Co-badge") {
                        showNetworkSelection.toggle()
                        if showNetworkSelection {
                            selectedNetwork = availableNetworks.randomElement() ?? "Visa"
                        } else {
                            selectedNetwork = "None"
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
            
            // Available networks display
            if showNetworkSelection {
                HStack(spacing: 8) {
                    Text("Available:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(availableNetworks, id: \.self) { network in
                        Button(network) {
                            selectedNetwork = network
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedNetwork == network ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedNetwork == network ? .white : .primary)
                        .cornerRadius(4)
                    }
                }
                .transition(.slide)
            }
            
            // Card form
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    if let cardFormScope = checkoutScope.cardForm {
                        cardFormScope.screen = { scope in
                            AnyView(
                                VStack(spacing: 12) {
                                    HStack {
                                        scope.cardNumberInput?(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(44)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(8)
                                            .border(showNetworkSelection ? .blue : .gray.opacity(0.3), width: showNetworkSelection ? 2 : 1)
                                        )
                                        
                                        if showNetworkSelection {
                                            VStack {
                                                Image(systemName: "creditcard")
                                                    .foregroundColor(.blue)
                                                Text(selectedNetwork.prefix(4))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 8)
                                        }
                                    }
                                    
                                    HStack(spacing: 12) {
                                        scope.expiryDateInput?(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(44)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(8)
                                            .border(.gray.opacity(0.3), width: 1)
                                        )
                                        
                                        scope.cvvInput?(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(44)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(8)
                                            .border(.gray.opacity(0.3), width: 1)
                                        )
                                    }
                                }
                            )
                        }
                    }
                }
            )
            .frame(height: 120)
        }
        .animation(.easeInOut(duration: 0.3), value: showNetworkSelection)
    }
}