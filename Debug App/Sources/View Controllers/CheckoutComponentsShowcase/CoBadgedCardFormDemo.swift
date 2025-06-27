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

    var body: some View {
        VStack {
            Text("Co-badged Cards Demo")
                .font(.headline)
                .padding()
            
            Text("Multiple network selection demo")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Co-badged Cards Checkout") {
                presentCheckout(title: "CoBadgedCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom co-badged card content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                    guard let cardScope = scope as? any PrimerCardFormScope else {
                        return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                    }
                    return AnyView(
                        VStack(spacing: 20) {
                            // Co-badged cards header
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Co-badged Cards Demo")
                                        .font(.title2.weight(.semibold))
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("VISA")
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                        Text("MC")
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                }
                                Text("Cards that support multiple payment networks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Co-badged example info
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Try Co-badged Test Card")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Some cards work with multiple networks")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("🔄")
                                        .font(.title2)
                                }
                                .padding(12)
                                .background(.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            // Form with co-badged emphasis
                            VStack(spacing: 16) {
                                // Card number with network detection
                                if let cardNumberInput = cardScope.cardNumberInput {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Card Number")
                                                .font(.subheadline.weight(.medium))
                                            Spacer()
                                            HStack(spacing: 4) {
                                                Text("Auto-detect:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Image(systemName: "network")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        cardNumberInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(52)
                                            .padding(.horizontal, 16)
                                            .background(.blue.opacity(0.08))
                                            .cornerRadius(12)
                                            .border(.blue.opacity(0.3), width: 1.5)
                                        )
                                        HStack {
                                            Text("Network will be detected automatically")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("🔍 Detecting...")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                // Other fields with network-aware styling
                                HStack(spacing: 16) {
                                    if let expiryDateInput = cardScope.expiryDateInput {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Expiry Date")
                                                .font(.subheadline.weight(.medium))
                                            expiryDateInput(PrimerModifier()
                                                .fillMaxWidth()
                                                .height(52)
                                                .padding(.horizontal, 16)
                                                .background(.purple.opacity(0.08))
                                                .cornerRadius(12)
                                                .border(.purple.opacity(0.3), width: 1.5)
                                            )
                                        }
                                    }
                                    
                                    if let cvvInput = cardScope.cvvInput {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("CVV")
                                                .font(.subheadline.weight(.medium))
                                            cvvInput(PrimerModifier()
                                                .fillMaxWidth()
                                                .height(52)
                                                .padding(.horizontal, 16)
                                                .background(.green.opacity(0.08))
                                                .cornerRadius(12)
                                                .border(.green.opacity(0.3), width: 1.5)
                                            )
                                        }
                                    }
                                }
                                
                                // Cardholder name
                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Cardholder Name")
                                            .font(.subheadline.weight(.medium))
                                        cardholderNameInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(52)
                                            .padding(.horizontal, 16)
                                            .background(.orange.opacity(0.08))
                                            .cornerRadius(12)
                                            .border(.orange.opacity(0.3), width: 1.5)
                                        )
                                    }
                                }
                            }
                            
                            // Co-badged information footer
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Co-badged Card Features:")
                                    .font(.caption.weight(.semibold))
                                Text("• Single card works with multiple networks")
                                Text("• User can choose preferred network")
                                Text("• Automatic network detection")
                                Text("• Routing optimization for best rates")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    )
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
