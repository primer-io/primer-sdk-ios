//
//  AnimatedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Animation playground demo with various animation styles
@available(iOS 15.0, *)
struct AnimatedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @State private var isAnimating = false
    @State private var selectedAnimation: String = "Bounce"
    private let animationOptions = ["Bounce", "Scale", "Rotate", "Glow"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Animation controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Animation Playground")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Picker("Animation", selection: $selectedAnimation) {
                        ForEach(animationOptions, id: \.self) { animation in
                            Text(animation).tag(animation)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Button(isAnimating ? "Stop" : "Start") {
                        isAnimating.toggle()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isAnimating ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
            
            // Animated card form
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    if let cardFormScope = checkoutScope.cardForm {
                        cardFormScope.screen = { scope in
                            AnyView(
                                VStack(spacing: 12) {
                                    scope.cardNumberInput?(getAnimatedModifier(for: selectedAnimation))
                                    
                                    HStack(spacing: 12) {
                                        scope.expiryDateInput?(getAnimatedModifier(for: selectedAnimation))
                                        scope.cvvInput?(getAnimatedModifier(for: selectedAnimation))
                                    }
                                }
                                .scaleEffect(getScaleEffect())
                                .rotationEffect(getRotationEffect())
                                .offset(y: getBounceOffset())
                                .shadow(color: getGlowColor(), radius: getGlowRadius(), x: 0, y: 0)
                            )
                        }
                    }
                }
            )
            .frame(height: 120)
        }
    }
    
    private func getAnimatedModifier(for animation: String) -> PrimerModifier {
        PrimerModifier()
            .fillMaxWidth()
            .height(44)
            .padding(.horizontal, 12)
            .background(.white)
            .cornerRadius(8)
            .border(.purple, width: 2)
    }
    
    private func getScaleEffect() -> CGFloat {
        if selectedAnimation == "Scale" && isAnimating {
            return 1.1
        }
        return 1.0
    }
    
    private func getRotationEffect() -> Angle {
        if selectedAnimation == "Rotate" && isAnimating {
            return .degrees(2)
        }
        return .degrees(0)
    }
    
    private func getBounceOffset() -> CGFloat {
        if selectedAnimation == "Bounce" && isAnimating {
            return -5
        }
        return 0
    }
    
    private func getGlowColor() -> Color {
        if selectedAnimation == "Glow" && isAnimating {
            return .purple
        }
        return .clear
    }
    
    private func getGlowRadius() -> CGFloat {
        if selectedAnimation == "Glow" && isAnimating {
            return 8
        }
        return 0
    }
}