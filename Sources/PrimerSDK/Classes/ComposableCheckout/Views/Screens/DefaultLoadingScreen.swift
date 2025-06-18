//
//  DefaultLoadingScreen.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Default loading screen shown during checkout processing
@available(iOS 15.0, *)
internal struct DefaultLoadingScreen: View {
    
    @Environment(\.designTokens) private var tokens
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(
                        (tokens?.primerColorGray200 ?? Color.gray.opacity(0.3)),
                        lineWidth: 8
                    )
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(
                        tokens?.primerColorBrand ?? .blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            VStack(spacing: 12) {
                Text("Loading Payment Methods...")
                    .font(.headline)
                    .foregroundColor(tokens?.primerColorText ?? .primary)
                
                Text("Please wait while we prepare your checkout")
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct DefaultLoadingScreen_Previews: PreviewProvider {
    static var previews: some View {
        DefaultLoadingScreen()
    }
}