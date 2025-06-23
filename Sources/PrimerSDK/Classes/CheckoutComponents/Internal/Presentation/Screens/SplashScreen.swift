//
//  SplashScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default splash screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct SplashScreen: View {
    @Environment(\.designTokens) private var tokens
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    tokens?.primerColorPrimary ?? .blue,
                    (tokens?.primerColorPrimary ?? .blue).opacity(0.7)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Logo or brand
            VStack(spacing: 24) {
                // Placeholder for logo
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("P")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(tokens?.primerColorPrimary ?? .blue)
                    )
                    .scaleEffect(animateGradient ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGradient)
                
                Text("Primer")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Secure Checkout")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}