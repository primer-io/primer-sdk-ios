//
//  DefaultSplashScreen.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Default splash screen shown during checkout initialization
@available(iOS 15.0, *)
internal struct DefaultSplashScreen: View {
    
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "creditcard")
                .font(.system(size: 64))
                .foregroundColor(tokens?.primerColorPrimary ?? .blue)
            
            Text("Primer Checkout")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(tokens?.primerColorText ?? .primary)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: tokens?.primerColorPrimary ?? .blue))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct DefaultSplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        DefaultSplashScreen()
    }
}