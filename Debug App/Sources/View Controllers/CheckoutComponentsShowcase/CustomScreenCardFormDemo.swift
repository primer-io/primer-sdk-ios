//
//  CustomScreenCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Custom screen layout demo with completely custom form layouts
@available(iOS 15.0, *)
struct CustomScreenCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @State private var selectedLayout: String = "Split Screen"
    private let layoutOptions = ["Split Screen", "Carousel", "Stepped", "Floating"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Layout selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Screen Layouts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Layout:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Layout", selection: $selectedLayout) {
                        ForEach(layoutOptions, id: \.self) { layout in
                            Text(layout).tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // Custom layouts
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    if let cardFormScope = checkoutScope.cardForm {
                        cardFormScope.screen = { scope in
                            AnyView(
                                Group {
                                    switch selectedLayout {
                                    case "Split Screen":
                                        splitScreenLayout(scope: scope)
                                    case "Carousel":
                                        carouselLayout(scope: scope)
                                    case "Stepped":
                                        steppedLayout(scope: scope)
                                    case "Floating":
                                        floatingLayout(scope: scope)
                                    default:
                                        defaultLayout(scope: scope)
                                    }
                                }
                            )
                        }
                    }
                }
            )
            .frame(height: 180)
            .animation(.easeInOut(duration: 0.5), value: selectedLayout)
        }
    }
    
    @ViewBuilder
    private func splitScreenLayout(scope: PrimerCardFormScope) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                scope.cardNumberInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(44)
                    .padding(.horizontal, 12)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
                    .border(.blue, width: 1)
                )
                
                scope.cardholderNameInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(44)
                    .padding(.horizontal, 12)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
                    .border(.blue, width: 1)
                )
            }
            
            VStack(spacing: 8) {
                scope.expiryDateInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(44)
                    .padding(.horizontal, 12)
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
                    .border(.green, width: 1)
                )
                
                scope.cvvInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(44)
                    .padding(.horizontal, 12)
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
                    .border(.green, width: 1)
                )
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func carouselLayout(scope: PrimerCardFormScope) -> some View {
        TabView {
            scope.cardNumberInput?(PrimerModifier()
                .fillMaxWidth()
                .height(60)
                .padding(.horizontal, 20)
                .background(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            HStack(spacing: 12) {
                scope.expiryDateInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(60)
                    .padding(.horizontal, 20)
                    .background(.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                
                scope.cvvInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(60)
                    .padding(.horizontal, 20)
                    .background(.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            
            scope.cardholderNameInput?(PrimerModifier()
                .fillMaxWidth()
                .height(60)
                .padding(.horizontal, 20)
                .background(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    @ViewBuilder
    private func steppedLayout(scope: PrimerCardFormScope) -> some View {
        VStack(spacing: 20) {
            HStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                Text("Step 1: Card Number")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            scope.cardNumberInput?(PrimerModifier()
                .fillMaxWidth()
                .height(44)
                .padding(.horizontal, 12)
                .background(.white)
                .cornerRadius(8)
                .border(.blue, width: 1)
            )
            
            HStack {
                scope.expiryDateInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(36)
                    .padding(.horizontal, 8)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(6)
                    .border(.gray.opacity(0.3), width: 1)
                )
                
                scope.cvvInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(36)
                    .padding(.horizontal, 8)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(6)
                    .border(.gray.opacity(0.3), width: 1)
                )
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func floatingLayout(scope: PrimerCardFormScope) -> some View {
        ZStack {
            Color.blue.opacity(0.1)
            
            VStack(spacing: 16) {
                scope.cardNumberInput?(PrimerModifier()
                    .fillMaxWidth()
                    .height(44)
                    .padding(.horizontal, 16)
                    .background(.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                
                HStack(spacing: 16) {
                    scope.expiryDateInput?(PrimerModifier()
                        .fillMaxWidth()
                        .height(44)
                        .padding(.horizontal, 16)
                        .background(.white)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    
                    scope.cvvInput?(PrimerModifier()
                        .fillMaxWidth()
                        .height(44)
                        .padding(.horizontal, 16)
                        .background(.white)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding()
        }
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func defaultLayout(scope: PrimerCardFormScope) -> some View {
        VStack(spacing: 12) {
            scope.cardNumberInput?(PrimerModifier()
                .fillMaxWidth()
                .height(44)
                .padding(.horizontal, 12)
                .background(.white)
                .cornerRadius(8)
                .border(.gray.opacity(0.3), width: 1)
            )
            
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
        .padding()
    }
}
