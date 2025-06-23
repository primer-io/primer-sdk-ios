//
//  LoadingScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default loading screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct LoadingScreen: View {
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: tokens?.primerColorPrimary ?? .blue))
            
            Text("Loading payment methods...")
                .font(.body)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
    }
}