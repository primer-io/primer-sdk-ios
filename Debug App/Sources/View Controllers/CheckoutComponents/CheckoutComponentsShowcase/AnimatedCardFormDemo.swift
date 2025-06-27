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

    var body: some View {
        VStack {
            Text("Animation Demo")
                .font(.headline)
                .padding()
            
            Text("Various animation styles")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Animation Checkout") {
                presentCheckout(title: "AnimatedCardFormDemo")
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func presentCheckout(title: String) {
        // Find the current view controller to present from
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = findTopViewController(from: window.rootViewController) else {
            print("❌ [\(title)] Could not find view controller to present from")
            return
        }
        
        print("🔍 [\(title)] Button tapped - presenting CheckoutComponents")
        
        // Present using CheckoutComponentsPrimer with custom animated content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                    if let cardScope = scope as? any PrimerCardFormScope {
                        return AnyView(AnimatedFormView(scope: cardScope))
                    } else {
                        return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                    }
                }
                return AnyView(EmptyView())
            },
            completion: {
                print("✅ [\(title)] CheckoutComponents presentation completed")
            }
        )
        
        print("✅ [\(title)] CheckoutComponents presentation initiated")
    }

    private func findTopViewController(from rootViewController: UIViewController?) -> UIViewController? {
        if let presented = rootViewController?.presentedViewController {
            return findTopViewController(from: presented)
        }
        
        if let navigationController = rootViewController as? UINavigationController {
            return findTopViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = rootViewController as? UITabBarController {
            return findTopViewController(from: tabBarController.selectedViewController)
        }
        
        return rootViewController
    }
}

/// Animated form view with transitions and effects
@available(iOS 15.0, *)
struct AnimatedFormView: View {
    let scope: any PrimerCardFormScope
    @State private var isVisible = false
    @State private var slideOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated header
            VStack(spacing: 8) {
                Text("✨ Animated Payment")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isVisible)
                
                Text("Smooth transitions and effects")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.2), value: isVisible)
            }
            
            // Animated form fields
            VStack(spacing: 16) {
                // Card number with slide animation
                if let cardNumberInput = scope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 16)
                        .background(.white)
                        .cornerRadius(12)
                        .border(.purple.opacity(0.6), width: 2)
                        .shadow(color: .purple.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .offset(x: isVisible ? 0 : -slideOffset)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0).delay(0.3), value: isVisible)
                }
                
                // Expiry and CVV with staggered animation
                HStack(spacing: 12) {
                    if let expiryDateInput = scope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(12)
                            .border(.orange.opacity(0.6), width: 2)
                            .shadow(color: .orange.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                        .offset(x: isVisible ? 0 : -slideOffset)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0).delay(0.5), value: isVisible)
                    }
                    
                    if let cvvInput = scope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(12)
                            .border(.blue.opacity(0.6), width: 2)
                            .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                        .offset(x: isVisible ? 0 : slideOffset)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0).delay(0.6), value: isVisible)
                    }
                }
                
                // Cardholder name with bounce animation
                if let cardholderNameInput = scope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 16)
                        .background(.white)
                        .cornerRadius(12)
                        .border(.green.opacity(0.6), width: 2)
                        .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .offset(y: isVisible ? 0 : slideOffset)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.8), value: isVisible)
                }
            }
        }
        .padding(20)
        .background(LinearGradient(
            gradient: Gradient(colors: [
                .purple.opacity(0.05),
                .orange.opacity(0.05),
                .blue.opacity(0.05),
                .green.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .onAppear {
            isVisible = true
        }
    }
}
